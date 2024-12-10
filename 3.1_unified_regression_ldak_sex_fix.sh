#!/bin/bash -x

# To run this script for a sex-specific phenotype (e.g., age at menarche), use:
# ./3.1_unified_regression_ldak_sex.sh menarche_age
# For more information, see the wiki https://github.com/isabellabadini/trioGWAS

set -e
source ./config

mkdir -p ${section_03_dir}
mkdir -p ${section_03_dir}/logs

gwasoutcome=${1}

echo "The GWAS outcome is ${gwasoutcome}"

exec &> >(tee ${section_03_logfile})

# Step 1: Check if the phenotype is sex-specific
IFS=',' read -r -a sex_specific_array <<< "${sex_specific_phenotypes}"
is_sex_specific="NO"
for phenotype in "${sex_specific_array[@]}"; do
    if [ "${gwasoutcome}" == "${phenotype}" ]; then
        is_sex_specific="YES"
        echo "Sex-specific phenotype detected: ${gwasoutcome}."
        break
    fi
done

if [ "${is_sex_specific}" == "NO" ]; then
    echo "Error: The phenotype '${gwasoutcome}' is not sex-specific."
    echo "Please use the 3.0_unified_regression_ldak.sh script for this analysis."
    exit 1
fi

# Step 2: Call an R script to prepare the temporary phenotype file
echo "Preparing temporary files"
Rscript resources/regression/prep_temp_pheno_dat.R \
${gwasoutcome} \
${phenotypes} \
${famfile} \
${section_03_dir}/temp.${gwasoutcome}

# Step 3: Prepare the covariate files excluding 'sex'

# Prepare temporary covariate file excluding 'sex' (with PCs)
temp_covariate_file="${section_03_dir}/temp.${gwasoutcome}.cov"

# Exclude 'sex' column from the covariate file
echo "Exclude sex from temporary covariate files"

awk '{
    if(NR==1){
        for(i=1;i<=NF;i++){
            if($i!="sex") col[i]=1
        }
    }
    for(i=1;i<=NF;i++){
        if(col[i]) printf "%s%s", $i, (i<NF?OFS:ORS)
    }
}' OFS='\t' ${covariates} > ${temp_covariate_file}

# Prepare temporary covariate file excluding 'sex' and PCs
temp_covariate_nopcs_file="${section_03_dir}/temp.${gwasoutcome}.nopcs.cov"

# Exclude 'sex' column from the covariates_nopcs file
awk '{
    if(NR==1){
        for(i=1;i<=NF;i++){
            if($i!="sex") col[i]=1
        }
    }
    for(i=1;i<=NF;i++){
        if(col[i]) printf "%s%s", $i, (i<NF?OFS:ORS)
    }
}' OFS='\t' ${covariates_nopcs} > ${temp_covariate_nopcs_file}

# Step 4: Run regression models 1-6 in LDAK

## Model 1: Population (non-within family) 
# These models use linear regression on offspring genotypes without adjusting for parental genotype. 
# Analysis is perfomed in both the full sample (output file name contains '_all_') and restricted trio sample (output file name contains '_trio_'). 
# Adjustment for structure (PCs) and no adjustment for structure (PCs) 
# Note that non-within family models regressing mother/father genotypes on offspring phenotypes are automatically perfomed in the --duo analysis (see ReadMe for details on output files). 

# No adjustment for structure
# Note!: Please save a 'covariates_nopcs.cov' file without the inclusion of PCs 1:20 in the 'scratch' folder
./ldak6.linux --linear ${section_03_dir}/model001_all_nopc_${gwasoutcome} --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${temp_covariate_nopcs_file} --families YES --max-threads 8 > ${section_03_dir}/logs/model001_all_nopc_${gwasoutcome}.log
./ldak6.linux --linear ${section_03_dir}/model001_trio_nopc_${gwasoutcome} --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${temp_covariate_nopcs_file} --families YES --keep scratch/trio_ids.txt --max-threads 8 > ${section_03_dir}/logs/model001_trio_nopc_${gwasoutcome}.log
#./ldak6.linux --linear ${section_03_dir}/model002_duos_mat_nopc_${gwasoutcome} --duos MOTHERS --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${temp_covariate_nopcs_file} --max-threads 8 > ${section_03_dir}/logs/model002_matduos_nopc_${gwasoutcome}.log
#./ldak6.linux --linear ${section_03_dir}/model003_duos_pat_nopc_${gwasoutcome} --duos FATHERS --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${temp_covariate_nopcs_file} --max-threads 8 > ${section_03_dir}/logs/model003_patduos_nopc_${gwasoutcome}.log
echo "Models 1-3 without adjusting for PCs complete"

# Adjustment for structure
./ldak6.linux --linear ${section_03_dir}/model01_all_pop_${gwasoutcome} --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${temp_covariate_file} --families YES --max-threads 8 > ${section_03_dir}/logs/model01_all_${gwasoutcome}.log
./ldak6.linux --linear ${section_03_dir}/model01_trio_pop_${gwasoutcome} --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${temp_covariate_file} --families YES --keep scratch/trio_ids.txt --max-threads 8 > ${section_03_dir}/logs/model01_trio_${gwasoutcome}.log
echo "Model 1 complete"

## Models 2-5: Duos
# These models restrict to individuals who only have one parent in the data; mother-duos (restricts to ind who have their mother in the data) and father-duos (restricts to ind who have their father in the data) 
# Models 2 and 3 (regressing parent genotype on offspring phenotype - i.e. swap offspring genotypes for their parents) are automatically peformed when doing a --duo analysis (see ReadMe for details on output files). 
# Analysis is performed in the duo sample (excluding trios) 

#./ldak6.linux --linear ${section_03_dir}/model02_duos_mother_${gwasoutcome} --duos MOTHERS --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${temp_covariate_file} --max-threads 8 > ${section_03_dir}/logs/model02_matduos_${gwasoutcome}.log
#echo "Models 2 and 4 complete"

#./ldak6.linux --linear ${section_03_dir}/model03_duos_father_${gwasoutcome} --duos FATHERS --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${temp_covariate_file} --max-threads 8 > ${section_03_dir}/logs/model03_patduos_${gwasoutcome}.log
#echo "Models 3 and 5 complete"

## Model 6: Trio model
# Analysis is performed in trio sample only 
# Adjustment for BOTH parents genotype 
# Note that within-family duo models (swapping offspring genotypes for their parents) within the trio sample only are automatically performed in the --trio analysis (see ReadMe for details on output files)
 
#./ldak6.linux --linear ${section_03_dir}/model06_trios_${gwasoutcome} --trios YES --pheno ${section_03_dir}/temp.${gwasoutcome}.pheno --bfile ${bfile_raw} --covar ${temp_covariate_file} --max-threads 8 > ${section_03_dir}/logs/model06_${gwasoutcome}.log
#echo "Model 6 complete"

# Remove temporary/redudant files 
rm ${section_03_dir}/temp.${gwasoutcome}.*
rm ${section_03_dir}/*.progress
#rm ${section_03_dir}/*.pvalues
#rm ${section_03_dir}/*.score

# Create phenotype folder and move results files 
mkdir -p ${section_03_dir}/${gwasoutcome}_clustered
mv ${section_03_dir}/model*_${gwasoutcome}.* ${section_03_dir}/${gwasoutcome}_clustered/

# Compress folder and create checksum file 
tar -czvf ${section_03_dir}/${gwasoutcome}_clustered.tar.gz -C ${section_03_dir} ${gwasoutcome}_clustered
sha256sum ${section_03_dir}/${gwasoutcome}_clustered.tar.gz > ${section_03_dir}/${gwasoutcome}_clustered.tar.gz.sha256

echo "Completed analysis"
