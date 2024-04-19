rm(list = ls())

.libPaths(c("~/projects/trio_gwas/bin", .libPaths()))
require(data.table)
require(dplyr)
require(sandwich)
require(lmtest)
require(estimatr)

# import argument
arguments <- commandArgs(trailingOnly = T)
rawfile <- arguments[1]
bimfile <- arguments[2]
famfile <- arguments[3]
phenfile <- arguments[4]
covfile <- arguments[5]
outfile <- arguments[6]
outcome <- arguments[7]

#---------------------------------------------------------------------------------------------#
# Prepare data
#---------------------------------------------------------------------------------------------#

time_start <- Sys.time()
paste0("Running GWAS for: ", outfile, " | Started: ")
time_start

# Load genetic data data
paste0("Loading genetic data")
raw <- fread(rawfile)
bim <- fread(bimfile)
fam <- fread(famfile)

# Rename columns
raw[1:5,1:7]
head(bim) # Cols = FID, IID, pat_IID, mat_IID, sex, pheno
head(fam)
fam <- fam%>%
  rename(FID = "V1", IID = "V2", PAT = "V3", MAT = "V4")

# Create offspring, father and mother files
# select FID, child IID, pat IID, and mat IID (pIDD and mIID used later for merging)
off <- fam %>% select(1:4)

pat <- fam %>% select(1,3) %>% # select FID and pat IID and rename PAT=IID
  rename(IID = "PAT")

mat <- fam %>% select(1,4) %>% # select FID and mat IID and rename MAT=IID
  rename(IID = "MAT")

tmp <- raw %>%
  select(-c(PAT,MAT,SEX,PHENOTYPE)) # sex is included in the covariates file already

# Create three dataframes with the genetic data for father, mother and offspring:
patest <- tmp %>%
  semi_join(pat, by=c("FID","IID")) # return all rows from x with a match in y
matest <- tmp %>%
  semi_join(mat, by=c("FID","IID"))
offtest <- raw %>%
  semi_join(off,by=c("FID","IID")) # merge with 'raw' file to get pat and mat IIDs

patest[1:5,1:7]
matest[1:5,1:7]
offtest[1:5,1:7]

# Remove the mothers and fathers from the offspring dataframe
offtest <- offtest %>%
  filter(!IID %in% patest$IID) %>% # remove paternal IIDs from IID column in offspring dataframe
  filter(!IID %in% matest$IID) # remove maternal IIDs from IID column in offspring dataframe - so that IID column in offtest now only contains offspring IIDs

# Rename the paternal SNPs
patest <- patest %>%
  dplyr::rename_with(~paste0("p_", .), -1)

# Rename the maternal SNPs
matest <- matest %>%
  dplyr::rename_with(~paste0("m_", .), -1)

# Rename offspring SNPs
offtest <- offtest %>%
  dplyr::rename_with(~paste0("c_", .), -c(1:4)) %>%
  rename(p_IID = "PAT") %>%
  rename(m_IID = "MAT")

# Merge offspring, paternal and maternal dataframes - this creates a wide dataset with complete trios
wide <- offtest %>%
  left_join(patest, by=c("FID","p_IID"))
wide <- wide %>%
  left_join(matest, by=c("FID","m_IID"))

############################
# Load phenotype and covariate data
# This uses the outcome variable that is passed through into the script at the top
paste0("Loading phenotype data")
paste0("Outcome: ", outcome)
phen <- fread(phenfile)

phen <- subset(phen, select=c("FID", "IID", outcome))
names(phen)<-c("FID", "IID", outcome)

paste0("Loading covariate data")
cov <- fread(covfile)

# Merge phenotype and covariate dataframes
phencov<-merge(phen,cov,by=c("FID", "IID"))
ped<-merge(wide,phencov, by=c("FID", "IID"))

# Select the outcome age variable
age_var <- paste("Age_",outcome,sep = "")

# Rename age variable just to age
ped <- ped %>%
    rename(Age = age_var)

# Clean R environment
clean <- setdiff(ls(), c("ped", "bim", "arguments", "outcome", "outfile")) # keep only main dataframe 'ped' and bim file for output; keep 'outcome' value; keep arguments value?
rm(list=clean)

# Note this script will be run separately for each phenotype. So the rest of the analysis should flow from here.

#---------------------------------------------------------------------------------------------#
# Begin GWAS code:
#---------------------------------------------------------------------------------------------#
# Track time:
time_start <- Sys.time()
paste0("Running GWAS for: ", outcome, " | Started: ")
time_start

# Identify SNPs and INDELs
# Some studies will have SNPs (single base pair changes), and INDELs insertion or deletion of base pairs.
# The MoBA data we're working with doesn't have any INDELs, so we don't need to worry about this here.
# Need to think about other studies. One option is to restrict the analysis to SNPs, not INDELs.
#
#SNPs <- grep("SNP", colnames(ped), value = TRUE)
#INDELs <- grep("INDEL", colnames(ped), value = TRUE)
#Variants <- c(SNPs, INDELs)

setDT(ped) # convert ped to data.table for efficiency

# Sanitise column names in ped for offspring, father, and mother SNP columns - R doesn't like special characters such as ':' - change to '_'
sanitise_colnames <- function(names){
  gsub(":", "_", names)
}
names(ped) <- sanitise_colnames(names(ped))

# Identify SNP columns for offspring, father, and mother
offspring_snp_cols <- grep("^c_chr", colnames(ped), value = TRUE)
father_snp_cols <- grep("^p_chr", colnames(ped), value = TRUE)
mother_snp_cols <- grep("^m_chr", colnames(ped), value = TRUE)

# Pre-define covariates
covariates <- "Age + Sex + batch1 + batch2 + batch3 + batch4"
for (pc in 1:20) covariates <- paste(covariates, paste0("+ PC", pc))

# Loop over all variants

# Start timing the loop
ptm <- proc.time()

# Initialise list to store model results
temp_results <- vector("list", length = length(offspring_snp_cols) * 6)
results_index <- 1

for (i in 1:length(offspring_snp_cols)) {

  snp_ind <- i+6

  # Define base parts of the formula
  offspring_part <- offspring_snp_cols[i]
  father_part <- father_snp_cols[i]
  mother_part <- mother_snp_cols[i]

  # Define regression models
  formulas <- list(
    paste(outcome, " ~ ", offspring_part, "+", covariates),
    paste(outcome, " ~ ", father_part, "+", covariates),
    paste(outcome, " ~ ", mother_part, "+", covariates),
    paste(outcome, " ~ ", offspring_part, "+", father_part, "+", covariates),
    paste(outcome, " ~ ", offspring_part, "+", mother_part, "+", covariates),
    paste(outcome, " ~ ", offspring_part, "+", father_part, "+", mother_part, "+", covariates)
  )

  skip_variant <- FALSE

  # Fit each model and store results
  for (j in seq_along(formulas)) {
    if(skip_variant){
      break # exit the inner loop early if an error occurred
    }

    model_name <- paste("Model", j, "for SNP", i, ":", offspring_part)

    tryCatch({
      model_start <- Sys.time()
      model <- lm_robust(as.formula(formulas[[j]]), data = ped, se_type = "stata", clusters = ped$FID)
      model_elaps <- Sys.time()-model_start

      temp_results[[results_index]] <- list(
        Model = model_name,
        SNP = offspring_snp_cols[i],
        Beta = summary(model)$coefficients[1:4, "Estimate"],
        SE = summary(model, vcov = "robust")$coefficients[1:4, "Std. Error"],
        P_value = summary(model, vcov = "robust")$coefficients[1:4, "Pr(>|t|)"]
      )
      results_index <- results_index + 1

    }, error = function(e) {
      message("Error in fitting ", model_name, ": ", e$message)
      skip_variant <<- TRUE
    })
  }

  if(skip_variant) {
    next
  }

}

# Create output and save results
# Note: the column 'model' in the output contains info on model number (1-6), CHR, BP, and A1 (in one string - not ideal, so will need to fix this at some point..), Beta, SE, and P-Value
# First 4 rows from each model output are saved

output <- do.call(rbind, lapply(temp_results, function(x){
  if(!is.null(x)) {
    parts <- unlist(strsplit(x$SNP, "_"))
    CHR <- parts[2]
    BP <- parts[3]
    A1 <- parts[5]
    simp_mod <- gsub(" for SNP.*", "", x$Model)
    simp_snp <- paste(CHR, BP, "SNP", A1, sep = ":")
    data.frame(Model = simp_mod, CHR = CHR, SNP = simp_snp, BP = BP, A1 = A1, Beta = x$Beta, SE = x$SE, P_value = x$P_value, stringsAsFactors = FALSE)
  }
}))

# Runtime:
run_time<-proc.time()-ptm
cat("Run time: ", run_time)
cat("Elapsed time for model fitting and saving results: ", model_elaps)

# Write output:
print(outfile)
fwrite(output, file = paste0(outfile, "_results.txt"), sep="\t")

# Close out
cat("Finished at: ")
Sys.time()
cat("Elapsed time: ")
Sys.time() - time_start

# Exits R without storing the working space image
q("no")
