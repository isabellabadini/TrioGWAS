#!/bin/bash
#
# Job name (this is what the cluster will show as running - keep short):
#SBATCH --job-name=trio_gwas
#
#Project:
#SBATCH --account=p471
#
#Wall clock limit (change based on resources required):
#SBATCH --time=50:00:00 
#
# Output filename customization
# This specification is Jobname_User_JobID
#SBATCH --output=./output/%x_%u_%j.out
#SBATCH --error=./error/trio_gwas_submission.txt
#
#SBATCH --ntasks=1
#
# Max memory usage (change based on resources required):
#SBATCH --mem-per-cpu=8G
#
#Number of CPUs per task. 
#SBATCH --cpus-per-task=2


#Working directory
outm="/cluster/projects/trio_gwas"

# Load R
module add R/4.2.1-foss-2022a

# Load Plink
module add  plink/1.90b6.2  

# Load Plink2
module add  plink2/2.00a2LM

#Call script
$outm/1.0_setup.sh 
