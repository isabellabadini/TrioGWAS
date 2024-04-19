#!/bin/bash

#To run this file on batch 1 for height use the following command:
# ./4.0_unified_regression.sh 1 height
#For more information see the wiki https://github.com/LaurenceHowe/SiblingGWAS/wiki/4.0_unified_regression

set -e
source ./config

mkdir -p ${section_04_dir}
mkdir -p ${section_04_dir}/logs

batch_number=${1}
gwasoutcome=${2}

echo "the batch number is this ${batch_number}"
echo "the gwas outcome is ${gwasoutcome}"

exec &> >(tee ${section_04_logfile})

re='^[0-9]+$'

if ! [[ $batch_number =~ $re ]] ; then
	echo "error: Batch variable is not a number"
	echo "Usage: ${0} [batch number]"
	exit 1
fi


j=$(echo "$((batch_number-1))")
k=`printf "%04d" $j`

echo "this is j ${j}"
echo "this is k ${k}"

echo "Running analysis"
#Run analysis on partitioned files

#Convert to .raw
plink \
--bfile ${bfile_raw} \
--allow-no-sex \
--extract ${section_03_dir}/extract${k} \
--recode A \
--out ${section_04_dir}/temp.${batch_number}.${gwasoutcome}

#Run regression script in R
Rscript resources/regression/unified_regression_trios.R \
${section_04_dir}/temp.${batch_number}.${gwasoutcome}.raw \
${section_03_dir}/extract${k} \
${famfile} \
${phenotypes} \
${covariates} \
${section_04_dir}/output.${batch_number}.${gwasoutcome} \
${gwasoutcome}

#Remove .raw file
rm ${section_04_dir}/temp.${batch_number}.${gwasoutcome}.*


echo "Completed analysis"
