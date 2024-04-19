#!/bin/bash

set -e
source ./config

phenotype=${1}

mkdir -p $(dirname "${output_file}")
mkdir -p ${section_05_dir}/logs

results_dir="${section_04_dir}"
output_file="${section_05_dir}/trios_combined_results_${phenotype}.txt"

echo "Combining results for phenotype: ${phenotype}"
echo "Results directory: ${results_dir}"
echo "Output file: ${output_file}"

exec &> >(tee "${section_05_logfile}")

# Run R script to combine regression results
Rscript resources/regression/combine-save-results.R \
${results_dir} \
${output_file} \
${phenotype}

echo "Combined results file located: ${output_file}"