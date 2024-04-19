.libPaths(c("~/projects/trio_gwas/bin", .libPaths()))
require(data.table)

arguments <- commandArgs(trailingOnly = TRUE)
results_dir <- arguments[1]
output_file <- arguments[2]
phenotype <- arguments[3]

print(exists("output_file"))
print(output_file)
print(phenotype)

file_pattern <- sprintf("output.*.%s_results.txt", phenotype)

#file_list <- list.files(results_dir, pattern = "\\.txt$", full.names = TRUE)
file_list <- list.files(results_dir, pattern = file_pattern, full.names = TRUE)
results_list <- lapply(file_list, fread)

paste0("Combining model results")
cres <- rbindlist(results_list)
head(cres)

# Write output:
fwrite(cres, output_file)
