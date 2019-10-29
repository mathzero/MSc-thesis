rm(list = ls())
library(chron)
setwd("C:/NTR/results/ML_methods/clustering")
transcr_covar_imp <- readRDS("C:/NTR/data/transcr_covar.rds")

# data scleaning

#Identify factors
transcr_covar_imp$sex<-as.factor(transcr_covar_imp$sex)
transcr_covar_imp$biomonth<-as.factor(transcr_covar_imp$biomonth)
transcr_covar_imp$biosmoke<-as.factor(transcr_covar_imp$biosmoke)
transcr_covar_imp$biosmoke <- relevel(transcr_covar_imp$biosmoke, ref = 3)
levels(transcr_covar_imp$biosmoke)[levels(transcr_covar_imp$biosmoke)==-1] <- NA
transcr_covar_imp$STED <- as.factor(transcr_covar_imp$STED)
transcr_covar_imp$STED <- droplevels(transcr_covar_imp$STED)

###Categorize BMI and sted
transcr_covar_imp$BMI_cat<-transcr_covar_imp$biobmi
transcr_covar_imp$BMI_cat[transcr_covar_imp$BMI_cat<20 & !is.na(transcr_covar_imp$BMI_cat)]<-1
transcr_covar_imp$BMI_cat[transcr_covar_imp$BMI_cat<30 & transcr_covar_imp$BMI_cat>=20 & !is.na(transcr_covar_imp$BMI_cat)]<-2
transcr_covar_imp$BMI_cat[transcr_covar_imp$BMI_cat>=30 & !is.na(transcr_covar_imp$BMI_cat)]<-3
transcr_covar_imp$BMI_cat<-as.factor(transcr_covar_imp$BMI_cat)
transcr_covar_imp$BMI_cat <- relevel(transcr_covar_imp$BMI_cat, ref = 2)
transcr_covar_imp[(transcr_covar_imp$STED == 0),]$STED <- NA
transcr_covar_imp$STED <-as.factor(transcr_covar_imp$STED)
transcr_covar_imp$STED <-relevel(transcr_covar_imp$STED, ref = 1)

##convert time of sampling to date variable (assuming fixed date)

tt<-as.character(transcr_covar_imp$biotime)
transcr_covar_imp$biotime_mod<-as.numeric(chron(times.=tt))

## !!! "average correlation between arrays (RNAexpr_D)" - variable is not between 0 and 1; interpretation? left out for now
covar_fixed<-c("sex","biosmoke","BMI_cat","biolympn","biomonon","bioneutn","bioeosn","biobason","biohgb","RNAexpr_ndays","RNAexpr_ndays_ext_amp","biotime_mod","STED")

## "biomonth for now included as random variable"
covar_random<-c("RNAexpr_plate","RNAexpr_well","FamilyID","biomonth")
###left zygozity state out of the model for now (need decision how to deal with non-twins)
#"twzyg"

# convert spaces to NA
levels(transcr_covar_imp$RNAexpr_plate)[levels(transcr_covar_imp$RNAexpr_plate)==" "] <- NA
levels(transcr_covar_imp$RNAexpr_well)[levels(transcr_covar_imp$RNAexpr_well)==" "] <- NA
levels(transcr_covar_imp$FamilyID)[levels(transcr_covar_imp$FamilyID)==" "] <- NA

# create age binvariable
transcr_covar_imp$age_bin <- as.factor(ntile(transcr_covar_imp$bioage, 4))

transcr_covar_imp_unscaled <- transcr_covar_imp
##############################################################################################################
##############################################################################################################

# Creating lists of variables 

traps.vars <-c("no2", "nox", "pm25_abs", "pm10", "pm25", "pmcoarse","pm10_Cu", "pm10_Fe", "pm10_K", "pm10_Ni", "pm10_S", "pm10_Si", "pm10_V", 
               "pm10_Zn", "pm25_Cu", "pm25_Fe", "pm25_K", "pm25_Ni", "pm25_S", "pm25_Si", "pm25_V", "pm25_Zn", "UFP")


traps.pm25 <-c( "pm25_Cu", "pm25_Fe", "pm25_K", "pm25_Ni", "pm25_S", "pm25_Si", "pm25_V", "pm25_Zn")

bio.vars <- c("bioage", "bioheight","bioweight", "biobmi", "biowbc","bioneut","biolymp","biomono","bioeos","biobaso", "biorbc")

geo.vars <- c("NATUR_500", "NATUR_1000","NATUR_5000","INDUS_100", "INDUS_300", "INDUS_500", "INDUS_1000", 
              "INDUS_5000","LDRES_100", "LDRES_300", "LDRES_500", "LDRES_1000","LDRES_5000","URBG_100","URBG_300","URBG_500", 
              "URBG_1000", "URBG_5000", "PORT_100","PORT_300","PORT_500","PORT_1000", "PORT_5000",
              "POP_100","POP_300","POP_500","POP_1000","POP_5000","HHOLD_100", "HHOLD_300",
              "HHOLD_500", "HHOLD_1000","HHOLD_5000","INTINVD2","HTRAFNEAR", "HINTINVD","DINVNEAR1",
              "DINVNEAR2", "HINTINVD2", "TRAFNEAR","INTINVD","DINVMAJOR2","DINVMAJOR1","INTMINVD","TRAFMAJOR", 
              "INTMINVD2", "HTRAFMAJOR","TMLOA_50","TMLOA_100", "TMLOA_300", "TMLOA_500", "TMLOA_1000","HMLOA_50",
              "HMLOA_100", "HMLOA_300", "HMLOA_500", "HMLOA_1000","TLOA_50",
              "TLOA_100","TLOA_300","TLOA_500","TLOA_1000", "HLOA_50","HLOA_100","HLOA_300", 
              "HLOA_500","HLOA_1000", "RDL_50", "RDL_100","RDL_300","RDL_500","RDL_1000", 
              "MRDL_50","MRDL_100","MRDL_300","MRDL_500","MRDL_1000", "DINVNEARC1","DINVNEARC2", 
              "CMAJOCLASS","DINVMAJOC1","DINVMAJOC2","EEA_100","EEA_300","EEA_500","EEA_1000", 
              "EEA_5000","TMLOA_25","HMLOA_25","TLOA_25","HLOA_25","MRDL_25","RDL_25", "NDVI_100m","NDVI_300m","NDVI_500m",                 
              "NDVI_1000m","NDVI_3000m","TOP10NL_100m","TOP10NL_300m","TOP10NL_500m","TOP10NL_1000m","TOP10NL_3000m",           
              "agri_500m","nature_500m","urban_500m","agri_1000m","nature_1000m","urban_1000m","agricul_3000m",          
              "nature_3000m","urban_3000m","out_top10n","NDVI_out","OPP_LAND","OPP_WATER")


geo.vars.traffic <- c("INTINVD2","HTRAFNEAR", "HINTINVD","DINVNEAR1",
                      "DINVNEAR2", "HINTINVD2", "TRAFNEAR","INTINVD","DINVMAJOR2","DINVMAJOR1","INTMINVD","TRAFMAJOR", 
                      "INTMINVD2", "HTRAFMAJOR","TMLOA_50","TMLOA_100", "TMLOA_300", "TMLOA_500", "TMLOA_1000","HMLOA_50",
                      "HMLOA_100", "HMLOA_300", "HMLOA_500", "HMLOA_1000","TLOA_50",
                      "TLOA_100","TLOA_300","TLOA_500","TLOA_1000", "HLOA_50","HLOA_100","HLOA_300", 
                      "HLOA_500","HLOA_1000", "DINVNEARC1","DINVNEARC2", 
                      "CMAJOCLASS","DINVMAJOC1","DINVMAJOC2")


demog.vars <- c("P_ONGEHUWD","P_GEHUWD", "P_GESCHEID","P_VERWEDUW","BEV_DICHTH","P_WEST_AL","P_N_W_AL","P_MAROKKO","P_ANT_ARU",                
                "P_SURINAM","P_TURKIJE","P_OVER_NW","WOZ","P_KOOPWON","P_HUURWON","P_LAAGINKH", 
                "P_HOOGINKH","P_LKOOPKRH","P_SOCMINH","P_WWB_UIT" )


var.groups <-list(bio.vars, traps.vars, geo.vars, geo.vars.traffic, demog.vars)
var.group.names <- c("biology","traps","geography","traffic","demographic")

every.var <- c(bio.vars, traps.vars,geo.vars, demog.vars)


## creating imputed data set (clustering fails with NAs)
expression_ID <- "expression_ID"
df <- transcr_covar_imp[,c(bio.vars, traps.vars, geo.vars, demog.vars)]
df[df < 0 ] <- NA
df <- cbind(transcr_covar_imp[,covar_fixed,covar_random])
# change integers to numeric for clustering
for (i in 1:ncol(df)){
  print(colnames(df)[i])
     print(class(df[,i]))
     if(class(df[,i]) == "integer"){
       df[,i] <- as.numeric(df[,i])
     }
}


# creating fully imputed data set (warning: takes approx 1 hour)
library(mice)
scale.df <- scale(df)
tempData <- mice(scale.df,m=5,maxit=50,meth='pmm',seed=500)
ids.df <- rownames(transcr_covar_imp)
imputed.df <- mice::complete(tempData,1)
rownames(imputed.df) <- (ids.df)
imputed.df <- imputed.df[,!(grepl("\\.1",colnames(imputed.df)))]
imp.vars <- names(imputed.df)

transcr_covar_imp  <- cbind(imputed.df,transcr_covar_imp[,-which(names(transcr_covar_imp) %in% imp.vars)])

# confirm no NAs in clustering data
sum(is.na(transcr_covar_imp[,imp.vars]))

# loop through all clustering dimensions to create clusters

for (indx in 1:length(var.groups)){
  group.select <- var.groups[[indx]]
  group.name <- var.group.names[[indx]]
  cluster.df <- transcr_covar_imp[,group.select]
  
  ################################################################################################
  
  
  # plotting heatmap correlation matrix
  save_pheatmap_png <- function(x, filename, width=3000, height=3000, res = 300) {
    png(filename, width = width, height = height, res = res)
    grid::grid.newpage()
    grid::grid.draw(x$gtable)
    dev.off()
  }
  
  library(pheatmap)
  my_heatmap <- pheatmap(cor(Filter(is.numeric, cluster.df), use = "na.or.complete"))
  save_pheatmap_png(my_heatmap, paste0(group.name,"_heatmap.png"))

  library(ggplot2)
  # plotting correlation matrix
  ggcorr(cluster.df, label = TRUE, label_color = "white", label_size = 300/(ncol(transcr_covar_imp)), label_round = 2, 
         limits = c(-1,1), midpoint=0, name =paste0(group.name," var correlation"), legend.position = "left")
  ggsave(paste0(group.name,"_vars_select_correlation_all.png") , plot = last_plot(), device = "png", width = 13, height = 13, dpi = 300)
  
  ################################################################################################
  
  
  
  
  # Deternining optimum number of clusters
  library(factoextra)
  library(NbClust)
  
  # NBclust for applying multiple methods
  nbclust.results.all <- NbClust(data = cluster.df, diss = NULL, distance = "euclidean", min.nc = 2, max.nc = 15, method = "kmeans")
  
  # save optimum number of clusters are nclust
  nclust <- length(table(nbclust.results.all$Best.partition))
  
  
  ################################################################################################
  ################################################################################################
  
  # Applying clustering algorithm and visualising with PCA
  

  #  clustering
  set.seed(20)
  clusters <- kmeans(cluster.df, nclust) #  cluster
  
  
  # Save the cluster number in the dataset 
  clustername <- paste0(group.name,"Cluster")
  transcr_covar_imp[,clustername] <- as.factor(clusters$cluster) 

  
  
  ### VISUALISING CLUSTERS IN PCA

  
  ## create PCA
  df.pca <- prcomp(cluster.df, center = TRUE,scale. = TRUE)
  
  # PLotting PCA explained variance in relevant dimension
  png(paste0(group.name,"_PCA_variance_explained.png"), res = 300, units = "in", width = 8, height = 6)
  print(plot(cumsum(df.pca$sdev^2/sum(df.pca$sdev^2)), xlab = "Variable index", 
             ylab = "Cumulative proportion of variance explained", 
             main = "Principal component analysis: "))
  dev.off()
  
  library(ggfortify)
  
  ### PCA SCATTER PLOT FOR VISUALISATION
  png(paste0(group.name,"_PCA_vis.png"), res = 300, units = "in", width = 8, height = 6)
  print(autoplot(df.pca,  data = transcr_covar_imp, colour = clustername, alpha = 0.5))
  dev.off()
  
  
  ################################################################################################
  ################################################################################################
  
  # Checking how clusters correlate with other variables
  
  library(tableone)
  
  
  all.vars <- c( "biosmoke", "sex", "twzyg","bioage", "bioheight","bioweight", "biobmi", "biowbc","bioneut","biolymp","biomono","bioeos","biobaso", "biorbc")
  cat.vars <- c("biosmoke", "BMI_cat", "sex", "twzyg", "STED")
  
  
  tab <- CreateTableOne(vars = c(all.vars,traps.vars,geo.vars),  factorVars = cat.vars, data = transcr_covar_imp, strata = clustername)
  print(tab, showAllLevels = TRUE)
  summary(tab)
  
  
  tab1Mat <- print(tab, exact = "stage", quote = FALSE, noSpaces = TRUE, printToggle = FALSE)
  ## Save to a CSV file
  vars.for.writing <- as.data.frame(names(cluster.df))
  write.csv(tab1Mat, file = paste0(group.name,"tableOne.csv"))
  write.csv(vars.for.writing, file = paste0(group.name,"_vars.csv"))

}

table(transcr_covar_imp$biologyCluster)
table(transcr_covar_imp$trapsCluster)
table(transcr_covar_imp$trafficCluster)
table(transcr_covar_imp$demographicCluster)
table(transcr_covar_imp$geographyCluster)


# save data set with clusters (data set will be scaled for all variables used in clustering)
saveRDS(transcr_covar_imp, "C:/NTR/data/transcr_covar_imp_clustered_scaled.rds")

transcr_covar_imp_new <- cbind(transcr_covar_imp_unscaled, transcr_covar_imp[,grepl( "Cluster", names(transcr_covar_imp))])
saveRDS(transcr_covar_imp_new, "C:/NTR/data/transcr_covar_imp_clustered_unscaled.rds")



