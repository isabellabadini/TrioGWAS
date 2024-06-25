# Create lists of offspring/father/mother IDs who belong in a trio #
# Note: For trio GWAS pipeline, you only need a list of trio IDs (at level of offspring) - please save this in your scratch folder

rm(list = ls())

.libPaths(c("~/projects/trio_gwas/bin", .libPaths()))
require(data.table)

# Import arguments
arguments <- commandArgs(trailingOnly = TRUE)
famfile <- arguments[1]
outfile <- arguments[2]

# Read in fam file 
fam <- fread(famfile)

# Create list of complete trio IDs
trio_ids <- fam %>%
  filter(!V2 %in% V3) %>%
  filter(!V2 %in% V4) %>%
  filter(V3 %in% fam$V2) %>%
  filter(V4 %in% fam$V2)

trio_ids <- trio_ids %>%
  select(V1:V4) %>%
  rename(FID = "V1",
         IID = "V2",
         PID = "V3",
         MID = "V4")
#n_distinct(trio_ids$PID) 
#n_distinct(trio_ids$MID) 

off_trio_ids <- trio_ids %>%
  select(FID, IID)

# Create father_ids.txt
#pat_ids <- fam %>%
#  filter(V2 %in% fam$V3) %>% # fam file is in long and wide format meaning father IDs (V3) also appear in V2 and are not duplicated
#  select(V1, V2)
#
#pat_ids_trios <- pat_ids %>%
#  filter(V2 %in% trio_ids$PID) # filter to keep only fathers in complete trios (n = 36938) 
#
# Create mother_ids.txt
#mat_ids <- fam %>%
#  filter(V2 %in% fam$V4) %>% # fam file is in long and wide format meaning mother IDs (V4) also appear in V2 and not duplicated
#  select(V1, V2)
#
#mat_ids_trios <- mat_ids %>%
#  filter(V2 %in% trio_ids$MID) # filter to keep only fathers in complete trios (n = 36984)

fwrite(trio_ids, file = paste0(outfile, "trio_ids.txt"), sep = "\t", row.names = FALSE, quote = FALSE)
#fwrite(off_trio_ids, file = paste0(outfile, "off_trio_ids.txt", sep = "\t", row.names = FALSE, quote = FALSE)
#fwrite(pat_ids_trios, file = paste0(outfile, "father_trio_ids.txt"), sep = "\t", row.names = FALSE, quote = FALSE)
#fwrite(mat_ids_trios, file = paste0(outfile, "mother_trio_ids.txt"), sep = "\t", row.names = FALSE, quote = FALSE)
