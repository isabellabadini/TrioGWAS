errorlist <- list()
warninglist <- list()

library(data.table)
suppressMessages(library(matrixStats))

args <- (commandArgs(TRUE))
cov_file <- as.character(args[1])
fam_file <- as.character(args[2])
phen_file <- as.character(args[3])
cov_list_file <- as.character(args[4])

message("Checking covariates: ", cov_file)

if (cov_file == "NULL") {
  msg <- paste0("No covariate file has been provided.")
  warninglist <- c(warninglist, msg)
  message("WARNING: ", msg)
  q()
}

cov <- fread(cov_file, h = TRUE)
cov1 <- dim(cov)[1]
cov2 <- dim(cov)[2]

fam <- read.table(fam_file, h = FALSE, stringsAsFactors = FALSE)
phen <- fread(phen_file, h = TRUE)

# Check IDs
if (names(cov)[1] != "FID") {
  msg <- paste0("First column in covariate file should be the FID")
  errorlist <- c(errorlist, msg)
  warning("ERROR: ", msg)
}

if (names(cov)[2] != "IID") {
  msg <- paste0("Second column in covariate file should be the sample identified with the name IID")
  errorlist <- c(errorlist, msg)
  warning("ERROR: ", msg)
}

commonids_cpg <- Reduce(intersect, list(cov$IID, phen$IID, fam[, 2]))
message("Number of samples with covariate, genetic and phenotype data: ", length(commonids_cpg))

if (length(commonids_cpg) < 50) {
  msg <- paste0("Must have at least 50 individuals with covariate, genetic and phenotype data.")
  errorlist <- c(errorlist, msg)
  warning("ERROR: ", msg)
}

# Check Sex
sex_column <- names(cov)[grepl("^sex$", names(cov), ignore.case = TRUE)]
if (length(sex_column) < 1) {
  msg <- paste0("Sex is not present in the covariate file. Please check that the columns are labelled correctly")
  errorlist <- c(errorlist, msg)
  warning("ERROR: ", msg)
} else {
  sex_column <- sex_column[1]
  invalid_sex_values <- !cov[[sex_column]] %in% c("1", "0", NA)
  if (any(invalid_sex_values, na.rm = TRUE)) {
    msg <- paste0("There are some values in the Sex column that are neither 0 (F) nor 1 (M). Please categorise Males as 1 and Females as 0 and missing values as NA.")
    warninglist <- c(warninglist, msg)
    message("WARNING: ", msg)
  }
}

# Check YOB
yob_column <- names(cov)[grepl("^yob$", names(cov), ignore.case = TRUE)]
if (length(yob_column) < 1) {
  msg <- paste0("Year of Birth (YOB) is not present in the covariate file. Please check that the columns are labelled correctly")
  errorlist <- c(errorlist, msg)
  warning("ERROR: ", msg)
} else {
  yob_column <- yob_column[1]
  current_year <- as.numeric(format(Sys.Date(), "%Y"))
  invalid_yob_values <- cov[[yob_column]] < (current_year - 120) | cov[[yob_column]] > current_year
  if (any(invalid_yob_values, na.rm = TRUE)) {
    msg <- paste0("There are some values in the YOB column that fall outside a realistic range. Please make sure YOB is within a realistic range and missing values are coded as NA.")
    warninglist <- c(warninglist, msg)
    message("WARNING: ", msg)
  }
}

# Check principal components
pccheck <- grep("^PC", names(cov), ignore.case = TRUE)
if (length(pccheck) < 20) {
  msg <- paste0("The first 20 principal components are not present in the covariate file. Please check that the columns are labelled correctly")
  errorlist <- c(errorlist, msg)
  warning("ERROR: ", msg)
}

cov <- subset(cov, IID %in% commonids_cpg)

write.table(names(cov)[-2:-1], file = cov_list_file, row = FALSE, col = FALSE, qu = FALSE)

message("\n\nCompleted checks\n")

if (length(warninglist) > 0) {
  message("\n\nPlease take note of the following warnings, and fix and re-run the data check if you see fit:")
  null <- sapply(warninglist, function(x) {
    message("- ", x)
  })
}

if (length(errorlist) > 0) {
  message("\n\nThe following errors were encountered, and must be addressed before continuing:")
  null <- sapply(errorlist, function(x) {
    message("- ", x)
  })
  q(status = 1)
}
message("\n\n")