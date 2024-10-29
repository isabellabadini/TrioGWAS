# Trios GWAS

This pipeline is designed to perform GWAS using parent-offspring trios (mother-father-offspring) and duos (mother/father-offspring). The pipeline is designed to be fully automated, requiring minimal user input beyond the initial cleaning and formatting of phenotype and genotype data.

**Basic requirements**
1.	Genotype data for parent-offspring trios and/or duos 
2.	Sample size greater than n=250 trios/duos
3.	Data on at least one phenotype
4.	Data on all covariates 
5.	SNP data containing genotyped and imputed SNPs (prior to imputation, we recommend excluding genotyped SNPs with missingness >5%)

**Software requirements**

LDAK Version 6 - download from this page: <br />
https://dougspeed.com/downloads2/

**Input files**
1. Genetic data: Binary PLINK format files (.bim, .fam, .bed)
2. Phenotype data: Phenotype data for offspring
3. Two covariate files. The first file should include sex, year of birth, genotyping batches and 20 PCs. The second file should exclude PCs (i.e., include sex, 
   year of birth, genotyping batches but NOT 20 PCs).
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

**3.1_unified_regression_ldak_sex**

This script is set up to run regression models in [LDAK](https://dougspeed.com) for phenotypes where ‘sex’ should be excluded as a covariate. It's specifically designed for analysing sex-limited traits (i.e. traits expressed in only one sex, such as age at menarche) or when sex itself is the outcome variable. The script automatically adjusts the covariate files by excluding ‘sex’ variable to prevent statistical issues like multicollinearity. Submission script is included in the pipeline. Similar to the main regression script, it runs several regression models separately on offspring, father, and mother genotypes without adjusting for parental genotypes (non-within-family analysis), as well as models that account for one or both parental genotypes (within-family analysis).

Any queries to Isabella Badini [i.badini@ucl.ac.uk](i.badini@ucl.ac.uk) <br />

Note scripts were adapted from scripts included in the [within-sibling GWAS](https://github.com/LaurenceHowe/SiblingGWAS) [(Howe et al. 2022)](https://www.nature.com/articles/s41588-022-01062-7), which were adapted from scripts by GoDMC (Gibran Hemani et al) and the SSGAC (Sean Lee/Patrik Turley et al).
For reference on LDAK, see [Speed et al. (2012)](https://doi.org/10.1016/j.ajhg.2012.10.010).
