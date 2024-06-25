#!/bin/bash

#To run this file on for height use the following command:
# ./4.0_unified_regression.sh height
#For more information see the wiki https://github.com/isabellabadini/trioGWAS

set -e
source ./config

mkdir -p ${section_03_dir}
mkdir -p ${section_03_dir}/logs

gwasoutcome=${1}

echo "The GWAS outcome is ${gwasoutcome}"

exec &> >(tee ${section_03_logfile})

# Step 1: Call an R script to prepare the temporary gwasoutcome and covariate files
Rscript resources/regression/prep_temp_pheno_dat.R \
${gwasoutcome} \
${phenotypes} \
${famfile} \
${section_03_dir}/temp.${gwasoutcome}  

# Step 2: Run regression models 1-6 in LDAK

## Model 1: Population (non-within family) 
# These models use linear regression on offspring genotypes without adjusting for parental genotype. 
# Analysis is perfomed in both the full sample (output file name contains '_all_') and restricted trio sample (output file name contains '_trio_'). 
# Adjustment for structure (PCs) and no adjustment for structure (PCs) 
# Note that non-within family models regressing mother/father genotypes on offspring phenotypes are automatically perfomed in the --duo analysis (see ReadMe for details on output files). 

# No adjustment for structure
# Note!: Please save a 'covariates_nopcs.cov' file without the inclusion of PCs 1:20 in the 'scratch' folder
./ldak6.beta --linear ${section_03_dir}/model001_all_nopc_${gwasoutcome} --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${covariates_nopcs} --sandwich YES --max-threads 8 > ${section_03_dir}/logs/model001_all_nopc_${gwasoutcome}.log
./ldak6.beta --linear ${section_03_dir}/model001_trio_nopc_${gwasoutcome} --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${covariates_nopcs} --sandwich YES --keep scratch/trio_ids.txt --max-threads 8 > ${section_03_dir}/logs/model001_trio_nopc_${gwasoutcome}.log
./ldak6.beta --linear ${section_03_dir}/model002_duos_mat_nopc_${gwasoutcome} --duos MOTHERS --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${covariates_nopcs} --max-threads 8 > ${section_03_dir}/logs/model002_matduos_nopc_${gwasoutcome}.log 
./ldak6.beta --linear ${section_03_dir}/model003_duos_pat_nopc_${gwasoutcome} --duos FATHERS --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${covariates_nopcs} --max-threads 8 > ${section_03_dir}/logs/model003_patduos_nopc_${gwasoutcome}.log
echo "Models 1-3 without adjusting for PCs complete"

# Adjustment for structure 
./ldak6.beta --linear ${section_03_dir}/model01_all_pop_${gwasoutcome} --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${covariates} --sandwich YES --max-threads 8 > ${section_03_dir}/logs/model01_all_${gwasoutcome}.log
./ldak6.beta --linear ${section_03_dir}/model01_trio_pop_${gwasoutcome} --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${covariates} --sandwich YES --keep scratch/trio_ids.txt --max-threads 8 > ${section_03_dir}/logs/model01_trio_${gwasoutcome}.log
echo "Model 1 complete"

## Models 2-5: Duos 
# These models restrict to individuals who only have one parent in the data; mother-duos (restricts to ind who have their mother in the data) and father-duos (restricts to ind who have their father in the data) 
# Models 2 and 3 (regressing parent genotype on offspring phenotype - i.e. swap offspring genotypes for their parents) are automatically peformed when doing a --duo analysis (see ReadMe for details on output files). 
# Analysis is performed in the duo sample (excluding trios) 

./ldak6.beta --linear ${section_03_dir}/model02_duos_mother_${gwasoutcome} --duos MOTHERS --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${covariates} --max-threads 8 > ${section_03_dir}/logs/model02_matduos_${gwasoutcome}.log 
echo "Models 2 and 4 complete"

./ldak6.beta --linear ${section_03_dir}/model03_duos_father_${gwasoutcome} --duos FATHERS --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${covariates} --max-threads 8 > ${section_03_dir}/logs/model03_patduos_${gwasoutcome}.log
echo "Models 3 and 5 complete" 

## Model 6: Trio model
# Analysis is performed in trio sample only 
# Adjustment for BOTH parents genotype 
# Note that within-family duo models (swapping offspring genotypes for their parents) within the trio sample only are automatically performed in the --trio analysis (see ReadMe for details on output files)
  
./ldak6.beta --linear ${section_03_dir}/model06_trios_${gwasoutcome} --trios YES --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${covariates} --max-threads 8 > ${section_03_dir}/logs/model06_${gwasoutcome}.log 
echo "Model 6 complete"

# Remove temp pheno/covar files
rm ${section_03_dir}/temp.${gwasoutcome}.*

# Remove LDAK progress files
rm ${section_03_dir}/*.progress

# Create phenotype folder and move results files 
mkdir -p ${section_03_dir}/${gwasoutcome}
mv ${section_03_dir}/model*_${gwasoutcome}.* ${section_03_dir}/${gwasoutcome}/

echo "Completed analysis"