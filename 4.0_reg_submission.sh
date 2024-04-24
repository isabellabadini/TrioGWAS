#!/bin/bash
#
# Job name (this is what the cluster will show as running - keep short):
#SBATCH --job-name=trio_gwas
#
#Project:
#SBATCH --account=pXXX
#
#Wall clock limit (change based on resources required):
#SBATCH --time=50:00:00 
#
#Output filename customization
#This specification is Jobname_User_JobID
#SBATCH --output=./output/%x_%u_%j.out
#SBATCH --error=./error/trio_gwas_%j.txt
#
#Number of CPUs per task. 
#SBATCH --cpus-per-task=1
#
# Max memory usage (change based on resources required):
#SBATCH --mem-per-cpu=16G
#
#1-1 for batch1; 1-3489 for all batches
#SBATCH --array=[1-1]%100

temp=$SLURM_ARRAY_TASK_ID
pheno=${1}

#Working directory
outm="/cluster/projects/trio_gwas"

#Load R
#module add R/4.0.0-foss-2020a  
module add R/4.2.1-foss-2022a

#Load Plink
module add  plink/1.90b6.2  

#Call script - will pass through the phenotype name in each submission

$outm/4.0_unified_regression.sh $temp $pheno
echo "this is temp $temp"
echo "this is pheno $pheno"


