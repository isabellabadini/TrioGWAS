#!/bin/bash
#
# Usage: To run this script for a specific phenotype and combine results accordingly, use the command below:
# sbatch 5.0_submission_script <phenotype> 
# example: sbatch 5.0_submission_script.sh height 
#
#Job name (this is what the cluster will show as running - keep short):
#SBATCH --job-name=trio_gwas
#
#Project:
#SBATCH --account=p471
#
#Wall clock limit (change based on resources required):
#SBATCH --time=10:00:00
#
#Output filename
#This specification is Jobname_User_JobID
#SBATCH --output=./output/%x_%u_%j.out
#SBATCH --error=./error/trio_gwas_submission.txt
#
#Number of CPUs per task
#SBATCH --cpus-per-task=1
#
#Max memory usage (change based on resources required): 
#SBATCH --mem-per-cpu=32G

phenotype=${1}

#Working directory
outm="/cluster/projects/p471/trio_gwas"

#Load R
module add R/4.2.1-foss-2022a

#Call script 
$outm/5.0_combine_results.sh $phenotype
