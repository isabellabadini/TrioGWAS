errorlist <- list()
warninglist <- list()

.libPaths(c("/ess/p471/cluster/projects/trio_gwas/bin", .libPaths()))
require(data.table)
require(plyr)

args <- (commandArgs(TRUE));
phenotype_file <- as.character(args[1]);
cov_file <- as.character(args[2]);
genotype_ids <- as.character(args[3])
gwas_phenotype_list_file <- as.character(args[4])
updated_phenotype_file <- as.character(args[5])

message("Checking phenotypes: ", phenotype_file)

if(phenotype_file == "NULL") 
{
	msg <- paste0("No phenotype file has been provided.")
	warninglist <- c(warninglist, msg)
	message("WARNING: ", msg)
	q()
}


message("Checking genotype fam file: ", genotype_ids)

if(genotype_ids == "NULL") 
{
	msg <- paste0("No PLINK .fam file has been provided.")
	warninglist <- c(warninglist, msg)
	message("WARNING: ", msg)
	q()
}

#Read in files

ph <- fread(phenotype_file, h=T)
p1 <- dim(ph)[1]
p2 <- dim(ph)[2]
cov <-fread(cov_file, h=T)
g_ids <- read.table(genotype_ids, h=F, stringsAsFactors=F)

#Check phenotype file

if(names(ph)[1] !="FID")
	{
	msg <- paste0("First column in phenotype file should contain FID")
	errorlist <-c(errorlist, msg)
	warning("ERROR: ", msg)
	}

if(names(ph)[2] !="IID")
	{
	msg <- paste0("Second column in phenotype file should be the sample identified with the name IID")
	errorlist <-c(errorlist, msg)
	warning("ERROR: ", msg)
	}

nom <- names(ph)[-1][names(ph)[-1] %in% c("height", "exam")]


#Check genotype file

if(names(g_ids)[2] !="V2")
	{
	msg <- paste0("The .fam file should not have a header.")
	errorlist <-c(errorlist, msg)
	warning("ERROR: ", msg)
	}

#Intersection of files
commonids_cpg<-Reduce(intersect, list(ph$IID, cov$IID, g_ids$V2))
message(length(commonids_cpg), " in common between phenotype, covariate and genotype data")

if(length(commonids_cpg)<50)
	{
	msg <-paste0("fewer than 50 subjects with phenotype, covariate and genotype data")
	warninglist<-c(warninglist, msg)
	warning("Warning: ", msg)
	}

ph<-subset(ph, IID%in%commonids_cpg)
g_ids<-subset(g_ids, V2%in%commonids_cpg)
	
#Phenotype checks

phenlist<-names(ph)[-2:-1]
famlist<-unique(ph$FID)
check<-NULL

#Identify families with phenotype data for only one sibling
#message("Checking phenotype data for families with phenotype data for only one sibling.")
#for (i in 1:length(phenlist)) {
#		temp<-paste(phenlist[i])
#		ph2<-subset(ph, select=c("FID", "IID", temp))
#		names(ph2)<-c("FID", "IID", "Phenotype")
#		comp<-ph2[complete.cases(ph2$Phenotype),]
#		
#		counts<-count(comp, "FID")
#		counts$Pheno<-paste(temp)
#		counts2<-counts[which(counts$freq<2),]
#		number=nrow(counts2)
#		if(number>0)
#	{
#	msg <- paste0("Families present where only one sibling has phenotype data for"," ",temp )
#	msg2 <-paste0(": Updated phenotype file with these families set to missing will be written to updated_phenotypes.txt. Please rerun with this updated phenotype file!")
#	warninglist <- c(warninglist, msg)
#	warning("WARNING: ", msg," ",msg2)
#	check<-rbind(check, counts2)
#	}
#	
#	     }	
#		 
#Sets phenotype to missing for these individuals
#if(number>0)
#	{
#for (i in 1:length(phenlist)) {
#		x<-i+2
#		temp<-paste(phenlist[i])
#		test<-check[which(check$Pheno==temp),]
#		ph[[x]][ph$FID%in%test$FID]<-NA
#}		
#}

#Identify phenotypes with less than 500 data points and set to missing

message("Checking that all phenotypes have at least 500 observations.")

for (i in 1:length(phenlist)) {
		temp<-paste(phenlist[i])
		ph2<-subset(ph, select=c("FID", "IID", temp))
		names(ph2)<-c("FID", "IID", "Phenotype")
		
		miss <- is.na(ph2$Phenotype)
		N <- as.numeric(summary(miss)[2])
	
		if(N<500)
	{
	x<-i+2
	ph[[x]]<-NA
			
	msg <- paste0("Phenotype with less than 500 observations, this phenotype will be set to missing and GWAS should not be run using it:"," ",temp )
	msg2 <-paste0("Please rerun this step with the updated phenotype file: ./results/01/updated_phenotypes.txt !")
	warninglist <- c(warninglist, msg)
	warning("WARNING: ", msg," ",msg2)
	
	}
	
	     }	
		


#Output updated phenotype file
message("Generating updated phenotype file in ./results/01/.")
write.table(ph, file=updated_phenotype_file, quote=F, row=F)		


if("height" %in% nom)
{
	message("Checking Height")
	m1 <- mean(ph$height,na.rm=T)
	age.mean<-mean(cov$YOB,na.rm=T)
	if((m1<100|m1>250)&age.mean>10)
	{
	msg <- paste0("please convert Height units to centimetres")
	errorlist <- c(errorlist, msg)
	warning("ERROR: ", msg)
	}
}

if("height" %in% nom)
{
	message("Checking Height")
	m1 <- mean(ph$height,na.rm=T)
	age.mean<-mean(cov$YOB,na.rm=T)
	if((m1<20|m1>250)&age.mean<10)
	{
	msg <- paste0("please convert Height units to centimetres")
	errorlist <- c(errorlist, msg)
	warning("ERROR: ", msg)
	}
}

#if("BMI" %in% nom)
#{
#	message("Checking BMI")
#	m1<-mean(ph$BMI,na.rm=T)
#	age.mean<-mean(cov$Age,na.rm=T)
#	if((m1<10|m1>40)&age.mean>2)
#	{
#	msg <- paste0("please convert BMI units to kg/m2")
#	errorlist <- c(errorlist, msg)
#	warning("ERROR: ", msg)
#	}
#}

write.table(names(ph)[-2:-1], file=gwas_phenotype_list_file, row=F, col=F, qu=F)


message("\n\nCompleted checks\n")


if(length(warninglist) > 0)
{
	message("\n\nPlease take note of the following warnings, and fix and re-run the data check if you see fit:")
	null <- sapply(warninglist, function(x)
	{
		message("- ", x)
	})
}

if(length(errorlist) > 0)
{
	message("\n\nThe following errors were encountered, and must be addressed before continuing:")
	null <- sapply(errorlist, function(x)
	{
		message("- ", x)
	})
	q(status=1)
}

message("\n\n")
