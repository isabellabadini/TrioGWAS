**Pipeline is still under development**
Thanks to everyone that has already gone through the pipeline and reported any errors/difficulties. We are currently adapting the pipeline to run the GWAS models in LDAK versus R. This will significantly improve computational time and simplify the pre-processing of data for analysts. We will be in touch to confirm once the pipeline is ready and set up monthly calls for analysts. 

# Trio GWAS

This pipeline is designed to perform GWAS using mother-father-offspring trios and duos. The pipeline is designed to be fully automated, requiring minimal user input beyond the initial cleaning and formatting of phenotype and genotype data.

Basic Requirements 
1. Trios
2. Imputed genotype data
3. Phenotypes

**Downloading and running the pipeline**

Navigate to the directory where you want to download the repisotory. The repository can then be downloaded using git: 

> git clone https://github.com/isabellabadini/TrioGWAS

**SCRIPTS**:

**config file**

Modify the config file to specify paths to relevant input files. Note that only this file sould be edited. 

**1.0_setup**

The set-up script runs checks to ensure that the input files are in the correct format and checks the installation of R packages. The R scripts are called in the setup script to perform checks on covariates, phenotypes, and genetic files.

**2.0_summary**

This script extracts summary data on all available phenotypes. 

**3.0_partitions**

This script partitions the genetic data into smaller lists of SNPs to be run in batches (note: batch size can be specified in the config file). 

**4.0_unified_regression**

This script runs the regression models in R. Submission script is included in the pipeline. The corresponding R script includes code for data preparation, fitting the regression models, and saving the output files. The script fits six regression models separately on offspring, father, and mother genotypes without adjusting for the parental genotypes, and in mutually adjusted analyses that account for one or both parental genotypes.

**5.0_combine_results**
This script compiles the output files into a final summary statistics file. Submission script for this is included in the repository. 

Any queries to Isabella Badini [i.badini@ucl.ac.uk](i.badini@ucl.ac.uk)

Note scripts were adapted from scripts included in the [within-sibling GWAS](https://github.com/LaurenceHowe/SiblingGWAS) [(Howe et al. 2022)](https://www.nature.com/articles/s41588-022-01062-7), which were adapted from scripts by GoDMC (Gibran Hemani et al) and the SSGAC (Sean Lee/Patrik Turley et al).
