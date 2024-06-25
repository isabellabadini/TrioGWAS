# Trio GWAS

This pipeline is designed to perform GWAS using parent-offspring trios (mother-father-offspring) and duos (mother/father-offspring). The pipeline is designed to be fully automated, requiring minimal user input beyond the initial cleaning and formatting of phenotype and genotype data.

**Basic requirements**
1.	Genotype data for parent-offspring trios and/or duos 
2.	Sample size greater than n=250 trios/duos
3.	Data on at least one phenotype
4.	Data on all covariates 
5.	Successfully genotyped genome-wide (recommended individual genotyping rate: > 95%) and imputed genotype data.

**Software requirements**
[LDAK6.beta](https://dougspeed.com/) 

**Input files**
1. Genetic data: Binary PLINK format files (.bim, .fam, .bed)
2. Phenotype data: Phenotype data for offspring
3. Covariates files: 
Covariates file including sex, year of birth, genotyping batches, 20 PCs 
Covariates file excluding PCs: including sex, year of birth, genotyping batches
4. List of trio offspring IDs: A file containing IDs of offspring who belong to a trio (refer to the example script extract-trio-pat-mat-ids.R).

**Downloading and running the pipeline**

Navigate to the directory where you want to download the repisotory. The repository can then be downloaded using git: 

> git clone https://github.com/isabellabadini/TrioGWAS

**SCRIPTS**:

**config file**

Modify the config file to specify paths to relevant input files. Note that only this file should be edited.

**1.0_setup**

The set-up script runs checks to ensure that the input files are in the correct format and checks the installation of R packages (see also 0.0_dependencies.R script). The R scripts are called in the setup script to perform checks on covariates, phenotypes, and genetic files. Submission script is included for reference. 

**2.0_summary**

This script extracts summary data on all available phenotypes and genotypes. 

**3.0_unified_regression_ldak**

This script runs the regression models in [LDAK](https://dougspeed.com). Submission script is included in the pipeline. The script is set up to run several regression models separately on offspring, father, and mother genotypes without adjusting for the parental genotypes (non-within family analysis), and in mutually adjusted analyses that account for one or both parental genotypes (within-family analysis).

Any queries to Isabella Badini [i.badini@ucl.ac.uk](i.badini@ucl.ac.uk)
Wiki coming soon. 

Note scripts were adapted from scripts included in the within-sibling GWAS (Howe et al. 2022), which were adapted from scripts by GoDMC (Gibran Hemani et al) and the SSGAC (Sean Lee/Patrik Turley et al).

Note scripts were adapted from scripts included in the [within-sibling GWAS](https://github.com/LaurenceHowe/SiblingGWAS) [(Howe et al. 2022)](https://www.nature.com/articles/s41588-022-01062-7), which were adapted from scripts by GoDMC (Gibran Hemani et al) and the SSGAC (Sean Lee/Patrik Turley et al).
