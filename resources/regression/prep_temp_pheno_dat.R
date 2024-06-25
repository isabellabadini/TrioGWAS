# Prepare temporary phenotype data files and trio IDs list for subsetting data

rm(list = ls())

.libPaths(c("~/projects/trio_gwas/bin", .libPaths()))
require(data.table)
require(dplyr)

# Import arguments
arguments <- commandArgs(trailingOnly = TRUE)
outcome <- arguments[1]
phenfile <- arguments[2]
famfile <- arguments[3]
outfile <- arguments[4]

paste0("Creating temporary files for: ", outcome)

# Read in phenotype data
phen <- fread(phenfile)
fam <- fread(famfile)

# Extract relevant phenotype data
phendat <- subset(phen, select=c("FID", "IID", outcome))
names(phendat)<-c("FID", "IID", outcome)

# Write the temporary phenotype files
#fwrite(phendat, file = paste0(outfile, ".pheno"), sep = "\t")
write.table(phendat, file = paste0(outfile, ".pheno"), sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE, eol = "\n", fileEncoding = "UTF-8")