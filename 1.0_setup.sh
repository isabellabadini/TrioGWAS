#!/bin/bash

set -e
source ./config

mkdir -p ${results}
mkdir -p ${section_01_dir}
mkdir -p ${section_01_dir}/logs

exec &> >(tee ${section_01_logfile})

containsElement () {
	local e
	for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
	echo "There is no method for ${1}."
	echo "Please run:"
	echo "./01-check_data [arg]"
	echo "where arg is an optional argument that can be one of:"
	printf '%s\n' ${@:2}
	return 1
}

arg="all"
declare -a sections=('all' 'config' 'requirements' 'genetics' 'rel' 'covariates' 'phenotypes' 'skipsib') #'siblings'


if [ -n "${1}" ]; then
	arg="${1}"
	containsElement ${1} ${sections[@]}
fi

section_message () {
	echo "-----------------------------------------------"
	echo ""
	echo "$1 section"
	echo ""
	echo "to run this part on its own type:"
	echo "$ ./1.0setup.sh $1"
	echo ""
	echo "-----------------------------------------------"
	echo ""
	echo ""
}

#Check study name

if [ "$arg" = "config" ] || [ "$arg" = "all" ] || [ "$arg" = "skipsib" ]
then
	section_message "config"
	if ! [[ "$study_name" =~ [^a-zA-Z0-9_\ ] ]] && ! [ "$study_name" = "" ]
	then
		echo "The study name '${study_name}' will be used for this analysis. Change this in the config file if necessary."
		echo ""
	else
		echo "The study name '${study_name}' is invalid. Please use only alphanumeric or underscore characters, with no spaces or special characters etc."
		exit
	fi
fi

#Check R version and packages

if [ "$arg" = "requirements" ] || [ "$arg" = "all" ] || [ "$arg" = "skipsib" ]
then
	section_message "requirements"
    Rscript resources/checks/packages.R
fi

#Check genotype file

if [ "$arg" = "genetics" ] || [ "$arg" = "all" ] || [ "$arg" = "skipsib" ]
then
	section_message "genetics"
	Rscript resources/checks/genetic_data.R \
		${bfile_raw}.bim \
		${bfile_raw}.fam \
		${quality_scores} \
		${controlsnps_file} 
fi

#Generate relatedness checks

if [ "$arg" = "rel" ] || [ "$arg" = "all" ]
then
#	section_message "Relatedness checks"
#	plink \
#	--bfile ${bfile_raw} \
#	--extract ${snplist} \
#	--genome \
#	--rel-check \
#	--out ${section_01_dir}/rel
#	
# 	plink2 \
#	--bfile ${bfile_raw} 
#	--make-king-table  
#	--out ${section_01_dir}/rel

	plink \
	--bfile ${bfile_raw} \
	--mendel \
	--out ${section_01_dir}/mendel
fi

#Check covariate file

if [ "$arg" = "covariates" ] || [ "$arg" = "all" ] || [ "$arg" = "skipsib" ]
then
	section_message "covariates"
	Rscript resources/checks/covariates_updated.R \
		${covariates} \
		${bfile_raw}.fam \
		${phenotypes} \
		${covariate_list}
fi

#Check phenotype file

if [ "$arg" = "phenotypes" ] || [ "$arg" = "all" ] || [ "$arg" = "skipsib" ]
then
	section_message "phenotypes"
	Rscript resources/checks/phenotypes.R \
		${phenotypes} \
		${covariates} \
		${bfile_raw}.fam \
		${phenotype_list} \
		${updated_phenotype_file}
fi

#Finish 

if [ "$arg" = "all" ]
then
        echo ""
        echo ""
        echo "You successfully performed all data checks!"
fi

