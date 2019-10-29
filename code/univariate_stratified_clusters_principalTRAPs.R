rm(list = ls())
setwd("C:/NTR/results/ML_methods/clustering/stratified_cluster")

## !!! "average correlation between arrays (RNAexpr_D)" - variable is not between 0 and 1; interpretation? left out for now
covar_fixed<-c("sex","biosmoke","bioage","BMI_cat","biolympn","biomonon","bioneutn","bioeosn","biobason","biohgb","RNAexpr_ndays","RNAexpr_ndays_ext_amp","biotime_mod")

## "biomonth for now included as random variable"
covar_random<-c("RNAexpr_plate","RNAexpr_well","FamilyID","biomonth")
###left zygozity state out of the model for now (need decision how to deal with non-twins)
#"twzyg"

# cluster.list <- c("geographyCluster","trafficCluster","trapsCluster", "biologyCluster","demographicCluster")
cluster.list <- c("trapsCluster")
varlist<-c("pm25","no2","nox","pm25_abs","pm10","pmcoarse","UFP")
# varlist<-c("no2","nox","pm25_abs","pm10","pmcoarse","UFP")

transcr_covar_imp <- readRDS("C:/NTR/data/transcr_covar_imp_clustered_unscaled.rds")

#importing significant probes
sigpm25 <- read.csv("C:/NTR/results/transcriptomics/models_f11_f12/logpm25_sigNames.csv")
sig.probes.pm25 <- as.character(sigpm25$f12)
sig.probes.pm25 <- sig.probes.pm25[!is.na(sig.probes.pm25)]


# ### binning ages into quartiles ###
# library(dplyr)
# transcr_covar_imp$age_bin <- ntile(transcr_covar_imp$bioage, 4) 

library(lme4)


for (inter in cluster.list){

  strat.levels <-  levels(transcr_covar_imp[,inter])
  
  for (j in varlist){
    targetvar=j
    # targetvar <- "no2"
    for (strt in strat.levels){
      
      # strt <-1
    ###########################################################################################
    ###
    ###########################################################################################
    
    #take out observations with missings in one of the covariates or exposures
    studydata<-transcr_covar_imp[complete.cases(transcr_covar_imp[,c(covar_fixed[! covar_fixed %in% "biotime_mod"],covar_random,targetvar)]),]
    
    studydata <- studydata[studydata[,inter] == strt,]
    
    #split into transcripts and exposure+covar datasets 
    transcripts<-studydata[,grep("_at",names(studydata))]
    expo_covar<-studydata[,-grep("_at",names(studydata))]
    
    rownames(transcripts)<-studydata$expression_ID
    rownames(expo_covar)<-studydata$expression_ID
    remove(studydata)
    
    
    # transcripts <- transcripts[,sig.probes.pm25]
    
    #Natural log-transform exposures
    
    for (inx in varlist){
      expo_covar[,paste0("log",inx)]<-log(expo_covar[,inx])
    }
    
    ############################################################################################
    # Run univariate analysis for various models
    ############################################################################################
    
    #Have to verify which ID is the best to correct for here -> family ID or RNA expression ID? Repeats in data?
    
    # Define model formulas for null model and model including the variable of
    # interest `target.var`
    target.var <- paste0("log",targetvar)
    
    f01 <- paste("y ~ ",paste("(1 |",covar_random,")",collapse = "+"))
    f02 <- paste(f01,paste(covar_fixed,collapse = "+"),sep = "+")
    
    f11 <- paste(f01, target.var, sep=" + ")
    f12 <- paste(f02, target.var, sep=" + ")
    
    #options(warn=2)
    
    results <- matrix(NA, ncol(transcripts), 7,
                      dimnames=list(colnames(transcripts),
                                    c("nobs", "coef_f11", "coef.se_f11", "pval_f11",
                                      "coef_f12", "coef.se_f12", "pval_f12")))
    
    for (i in 1:ncol(transcripts)) {
      y <- transcripts[,i]
      
      model01 <- try(lmer(as.formula(f01), data=expo_covar, REML=FALSE))
      if (inherits(model01, "try-error")) {
        next
      }
      
      model02 <- try(lmer(as.formula(f02), data=expo_covar, REML=FALSE))
      if (inherits(model02, "try-error")) {
        next
      }
      
      model11 <- try(lmer(as.formula(f11), data=expo_covar, REML=FALSE))
      if (inherits(model11, "try-error")) {
        next
      }
      
      model12 <- try(lmer(as.formula(f12), data=expo_covar, REML=FALSE))
      if (inherits(model12, "try-error")) {
        next
      }
      
      coefs1 <- try(coef(summary(model11)), silent=TRUE)
      if (inherits(coefs1, "try-error") || !(target.var %in% rownames(coefs1))) {
        next
      }
      
      coefs2 <- try(coef(summary(model12)), silent=TRUE)
      if (inherits(coefs2, "try-error") || !(target.var %in% rownames(coefs2))) {
        next
      }
      
      
      results[i,"nobs"] <- nobs(model11)
      results[i,"coef_f11"] <- coefs1[target.var,"Estimate"]
      results[i,"coef.se_f11"] <- coefs1[target.var,"Std. Error"]
      results[i,"pval_f11"] <- anova(model01, model11)["model11","Pr(>Chisq)"]
      
      
      results[i,"coef_f12"] <- coefs2[target.var,"Estimate"]
      results[i,"coef.se_f12"] <- coefs2[target.var,"Std. Error"]
      results[i,"pval_f12"] <- anova(model02, model12)["model12","Pr(>Chisq)"]
      
    }
    
    results <- as.data.frame(results)
  
    saveRDS(results, paste0(targetvar,"_",inter,"_",strt,"_stratified_results.rds"))
  
}
}
}
