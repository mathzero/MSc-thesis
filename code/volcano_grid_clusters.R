rm(list=ls())
#set working path
path <- "C:/NTR/results/transcriptomics/models_f11_f12/elemental_particle_screening/all_probes"
path <- "C:/NTR/results/ML_methods/clustering/stratified_cluster/main_TRAPs/geography"
setwd(path)
library(dplyr)

# load annotations
load("C:/NTR/data/probeset_annotation.RData")
annotation <- as.data.frame(A)
rm(A)
colnames(annotation)[1] <- "OMIC.ID"
annotation$gene_name <- as.character(annotation$gene_name)


##############################################################################################################
##############################################################################################################

# import all files from working folder
expo.filenames <- list.files(path = path, pattern = "ster_1")
expo.strat <- lapply(expo.filenames, readRDS)
expo.filenames <- substr(expo.filenames,1,(nchar(expo.filenames)-42)) # amend the numbers here depending on 
names(expo.strat) <- expo.filenames
varlist <- expo.filenames

# adding adjusted pvals etc
for (x in 1:length(varlist)){
  expo.strat[[x]][,"BHpval_f11"] <- p.adjust(expo.strat[[x]][,"pval_f11"], method = "BH")
  expo.strat[[x]][,"BHpval_f12"] <- p.adjust(expo.strat[[x]][,"pval_f12"], method = "BH")
  expo.strat[[x]][,"OMIC.ID"] <- rownames(expo.strat[[x]])
  expo.strat[[x]] <- left_join(expo.strat[[x]], annotation, by = "OMIC.ID")
}

# adding significance levels
for (x in 1:length(expo.strat)){
  sig.levels <- c("Insignificant","Significant (BH p <0.05)",  "Significant (Bonferroni p <0.05)")
  
  expo.strat[[x]]$significancef11 <-as.factor(ifelse(-log10(expo.strat[[x]]$BHpval_f11) < -log10(0.05),"Insignificant", 
                                                     ifelse(-log10(expo.strat[[x]]$pval_f11) > -log10(0.05 / nrow(expo.strat[[x]])),
                                                            "Significant (Bonferroni p <0.05)" ,"Significant (BH p <0.05)")))
  
  levels(expo.strat[[x]]$significancef11) <- sig.levels
  
  expo.strat[[x]]$significancef12 <-as.factor(ifelse(-log10(expo.strat[[x]]$BHpval_f12) < -log10(0.05),"Insignificant", 
                                                     ifelse(-log10(expo.strat[[x]]$pval_f12) > -log10(0.05 / nrow(expo.strat[[x]])),
                                                            "Significant (Bonferroni p <0.05)" ,"Significant (BH p <0.05)")))
  levels(expo.strat[[x]]$significancef12) <- sig.levels
}

for (x in 1:length(varlist)){
  print(varlist[[x]])
  print(sum(expo.strat[[x]]$BHpval_f12 <= 0.05))
}
 

##############################################################################################################

library(ggplot2)
library(ggrepel)
library(gridExtra)
library(dplyr)
library(VennDiagram)
library(ggthemes)

##############################################################################################################

plots.uncontrolled <- list()
plots.controlled <- list()

for (x in 1:length(expo.strat)){
  sus.list <- expo.strat[[x]][expo.strat[[x]]$significancef11 == "Insignificant" &  expo.strat[[x]]$significancef12 != "Insignificant","OMIC.ID"]
  expo.strat[[x]] <- expo.strat[[x]][-which(expo.strat[[x]]$OMIC.ID %in% sus.list),]
  plots.uncontrolled[[x]] <- ggplot(data=expo.strat[[x]], aes(x=coef_f11, y=-log10(pval_f11), col = significancef11)) +
    geom_point(alpha=0.8, size=1.5) +
    theme(legend.position = "none") +
    xlab("Beta") + ylab("-log10 p-value") +
    geom_text(aes(label=ifelse(rank(pval_f11) < 6,as.character(gene_name),'')),
              check_overlap = FALSE, col = 'grey40',size=2, alpha = 0.9, hjust = 0, vjust = 1) +
    geom_hline(yintercept=-log10(0.05 / nrow(expo.strat[[x]])), linetype="dashed", color = "black", alpha = 0.6) +
    geom_hline(yintercept=-log10(0.05), linetype="dashed", color = "grey60", alpha = 0.7) +
    ggtitle(paste0(varlist[[x]]," uncontrolled model")) + 
    # ylim(0,9) + xlim(-3,3) +
    geom_text(mapping=aes(x=0,y=-log10(0.05)),label="Pval < 0.05",
              vjust=-1, size = 2.5, col ="grey60", alpha = 0.9) +
    geom_text(mapping=aes(x=0,y=-log10(0.05 / nrow(expo.strat[[x]]))),label="Bonferroni significance threshold",
              vjust=-1, size = 2.5, col ="grey60")  +
    scale_colour_manual(name = "", values = c("grey60","turquoise3", "firebrick2"),labels = levels(expo.strat[[x]]$significancef11), drop = FALSE) +
    theme_few()
  
  ggsave(paste0(varlist[[x]],"_uncontrolled_mod.png"), plot = last_plot(), device = NULL, path = NULL,
         scale = 1, width = 200, height = 200, units =  "mm",
         dpi = 300, limitsize = TRUE)
  
  plots.controlled[[x]] <- ggplot(data=expo.strat[[x]], aes(x=coef_f12, y=-log10(pval_f12), col = significancef12)) +
    geom_point(alpha=0.8, size=1.5) +
    theme(legend.position = "none") +
    xlab("Beta") + ylab("-log10 p-value") +
    geom_text(aes(label=ifelse(rank(pval_f12) < 6,as.character(gene_name),'')),
              check_overlap = FALSE, col = 'grey40',size=2, alpha = 0.9, hjust = 0, vjust = 1) +
    geom_hline(yintercept=-log10(0.05 / nrow(expo.strat[[x]])), linetype="dashed", color = "black", alpha = 0.6) +
    geom_hline(yintercept=-log10(0.05), linetype="dashed", color = "grey60", alpha = 0.7) + xlim(-2,2) + ylim(0,10) +
    ggtitle(paste0(varlist[[x]]," controlled model")) +  
    # ylim(0,9) + xlim(-3,3) +
    geom_text(mapping=aes(x=0,y=-log10(0.05)),label="Pval < 0.05",
              vjust=-1, size = 2.5, col ="grey60", alpha = 0.9) +
    geom_text(mapping=aes(x=0,y=-log10(0.05 / nrow(expo.strat[[x]]))),label="Bonferroni significance threshold",
              vjust=-1, size = 2.5, col ="grey60")  +
    scale_colour_manual(name = "", values = c("grey60","turquoise3", "firebrick2"),labels = levels(expo.strat[[x]]$significancef12), drop = FALSE) +
    theme_few()
  
  ggsave(paste0(varlist[[x]],"_controlled_mod.png"), plot = last_plot(), device = NULL, path = NULL,
         scale = 1, width = 200, height = 200, units =  "mm",
         dpi = 300, limitsize = TRUE)
}

library(cowplot)

control.grid <- plot_grid(plots.controlled[[1]]+ theme(legend.position="none"),plots.controlled[[2]]+ theme(legend.position="none"),plots.controlled[[3]]+ theme(legend.position="none"),
                          plots.controlled[[4]]+ theme(legend.position="none"),plots.controlled[[5]]+ theme(legend.position="none"), plots.controlled[[6]]+ theme(legend.position="none"),
                          plots.controlled[[7]]+ theme(legend.position="none"),plots.controlled[[8]]+ theme(legend.position="none"),
                          (get_legend(plots.controlled[[1]])),ncol=3)
cowplot::save_plot("controlled_volcanos_allparts.png",control.grid, base_height = 15, base_width = 15, dpi = 300)


uncontrol.grid <- plot_grid(plots.uncontrolled[[1]]+ theme(legend.position="none"),plots.uncontrolled[[2]]+ theme(legend.position="none"),plots.uncontrolled[[3]]+ theme(legend.position="none"),
                            plots.uncontrolled[[4]]+ theme(legend.position="none"),plots.uncontrolled[[5]]+ theme(legend.position="none"),plots.uncontrolled[[6]]+ theme(legend.position="none"),
                            plots.controlled[[7]]+ theme(legend.position="none"),plots.controlled[[8]]+ theme(legend.position="none"),
                            (get_legend(plots.uncontrolled[[1]])),ncol=3)
cowplot::save_plot("uncontrolled_volcanos_allparts.png",uncontrol.grid, base_height = 15, base_width = 15, dpi = 300)





