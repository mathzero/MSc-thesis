rm(list = ls())
library(chron)
setwd("C:/NTR/results/transcriptomics/models_f11_f12/elemental_particle_screening/")

############################################################################################
### Read in transcriptomics and covariate data
############################################################################################

transcr_covar_imp <- readRDS("C:/NTR/data/transcr_covar_imp_clustered_unscaled.rds")

# fixed effects
covar_fixed<-c("sex","biosmoke","bioage","BMI_cat","biolympn","biomonon","bioneutn","bioeosn","biobason","biohgb","RNAexpr_ndays","RNAexpr_ndays_ext_amp","biotime_mod")

# random effects
covar_random<-c("RNAexpr_plate","RNAexpr_well","FamilyID","biomonth")

# pm25 elemental particles
# varlist<-c("pm10_Cu","pm10_Fe","pm10_K","pm10_Ni","pm10_S","pm10_Si","pm10_V","pm10_Zn")
varlist<-c("pm10_Fe","pm10_K","pm10_Ni","pm10_S","pm10_Si","pm10_V","pm10_Zn")


library(lme4)


for (j in varlist){
  targetvar=j

###########################################################################################
###
###########################################################################################

#take out observations with missings in one of the covariates or exposures
studydata<-transcr_covar_imp[complete.cases(transcr_covar_imp[,c(covar_fixed[! covar_fixed %in% "biotime_mod"],covar_random,targetvar)]),]
 
# remove ay observations with below zero observation values
studydata <- studydata[studydata[,targetvar] >= 0,]

#split into transcripts and exposure+covar datasets 
transcripts<-studydata[,grep("_at",names(studydata))]
expo_covar<-studydata[,-grep("_at",names(studydata))]

rownames(transcripts)<-studydata$expression_ID
rownames(expo_covar)<-studydata$expression_ID
remove(studydata)
# 
# ### use only significant transcripts
# transcripts <- transcripts[,pm25.sig.probes]

#Natural log-transform exposures

for (inx in varlist){
    expo_covar[,paste0("log",inx)]<-(log(expo_covar[,inx]))
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


saveRDS(results,file = paste0(target.var,"_scaled.rds",sep=""))

}

