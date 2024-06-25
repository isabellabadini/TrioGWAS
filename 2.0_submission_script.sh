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
# Number of CPUs per task. 
#SBATCH --cpus-per-task=4
#
# Max memory usage (change based on resources required):
#SBATCH --mem-per-cpu=16G

#Working directory
outm="/cluster/projects/p471/projects/trio_gwas"

# Load R
module add R/4.2.1-foss-2022a

#Call script
$outm/2.0_summary.sh 