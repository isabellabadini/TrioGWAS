#!/bin/bash

set -e
source ./config

mkdir -p ${section_02_dir}
mkdir -p ${section_02_dir}/logs

exec &> >(tee ${section_02_logfile})

./ldak6.beta --calc-stats ${section_02_dir}/snp-summary --bfile ${bfile_raw} --max-threads 4

Rscript resources/summary/summary_updated.R \
		${phenotypes} \
		${covariates} \
		${phenotype_list} \
		${covariate_list} \
		${summary_file}
		
echo "Summary data successfully generated!"
		 
