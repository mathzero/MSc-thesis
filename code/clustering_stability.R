## clustering stability analysis ###
rm(list = ls())

setwd("C:/NTR/results/ML_methods/clustering")
library(fpc)

#import data
transcr_covar_imp <- readRDS("C:/NTR/data/transcr_covar_imp_clustered_scaled.rds")


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



# assign cluster numbers
traps.nums <-as.numeric(length(levels(transcr_covar_imp$trapsCluster)))
bio.nums <- as.numeric(length(levels(transcr_covar_imp$biologyCluster)))
geo.nums <- as.numeric(length(levels(transcr_covar_imp$geographyCluster)))
geo.nums.traffic <- as.numeric(length(levels(transcr_covar_imp$trafficCluster)))
demog.nums <- as.numeric(length(levels(transcr_covar_imp$demographicCluster)))

# creage lists of cluster dimension
var.groups <-list(bio.vars, traps.vars, geo.vars, geo.vars.traffic, demog.vars)
var.group.names <- c("biology","traps","geography","traffic","demographic")
var.nums <- list(bio.nums, traps.nums, geo.nums, geo.nums.traffic, demog.nums)


############################################################################################
############################################################################################

boot.clust.list <- list()

# looping through cluster dimensions to do stability analysis
for (i in 1:5){
  data <- (transcr_covar_imp[,var.groups[[i]]])

  nclust <- var.nums[[i]]
  print(var.group.names[[i]])
  mod.clusterboot <- clusterboot(data = data,B=100, distances=(class(data)=="dist"),
                                  bootmethod="boot",
                                  bscompare=TRUE, 
                                  multipleboot=FALSE,
                                  jittertuning=0.05, noisetuning=c(0.05,4),
                                  subtuning=floor(nrow(data)/2),
                                  clustermethod= kmeansCBI,
                                  noisemethod=FALSE,count=TRUE,
                                  showplots=F,dissolution=0.5,
                                  recover=0.75,seed=20,datatomatrix=TRUE, krange=nclust)
  boot.clust.list[[i]] <- mod.clusterboot
}
names(boot.clust.list) <- var.group.names


# create cluster results data frame
boot.clust.list.df <- data.frame(matrix(data=NA, nrow = (bio.nums+ traps.nums+ geo.nums+ geo.nums.traffic+ demog.nums), ncol = 3))

#looping to enter results into df
counter <- 0
for (i in 1:5){
  print(var.group.names[[i]])
  print(boot.clust.list[[i]]$bootmean)
  print(table(boot.clust.list[[i]]$result$result$cluster))
  nclust <- boot.clust.list[[i]]$result$nccl
  for (x in 1:nclust){
    boot.clust.list.df[(counter + x),2] <- boot.clust.list[[i]]$result$result$size[[x]]
    boot.clust.list.df[(counter + x),1] <- (var.group.names[[i]])
    boot.clust.list.df[(counter + x),3] <- boot.clust.list[[i]]$bootmean[[x]]
  }
  counter <- counter + nclust
}

names(boot.clust.list.df) <- c("dimension", "No_in_cluster", "stability")
write.csv(boot.clust.list.df, "bootstrapped_clustering_results.csv")



