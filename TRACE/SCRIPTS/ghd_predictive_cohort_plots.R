library(ggplot2)
library(reshape2)
library(gridExtra)
library(plyr)
library(scales)
source("SCRIPTS/multiplot.R")
##############################################################################
# GHD PREDICTIVE COHORT PLOTS
##############################################################################
# gagnepain sims from Monica

g<-read.csv("GHD_PREDICTIVE_COHORT/GHD_DP_revised.csv")
#g$X
#str(g)
#names(l)=c("Cycle", "Phase", "Item", "Type", "Word", "Base", "Input", "Act")
g$PHASE = factor(g$PHASE, levels(g$PHASE)[c(2,1)])
levels(g$PHASE)=c("Pre training", "Post training")
levels(g$TYPE)=c("Original","Trained","Untrained")
#head(g)
#levels(l$Condition)
#l$Condition = factor(l$Condition, levels(l$Condition)[c(1,3,2,4)])

gprob<-ddply(subset(g, position_DP < 3 & position_DP > -3), c("PHASE", "TYPE", "position_DP"), summarise,
             N = length(phon_prob),
             Probability = mean(phon_prob),
             sd = sd(phon_prob),
             se = sd / sqrt(N))
gerr<-ddply(subset(g, position_DP < 3 & position_DP > -3), c("PHASE", "TYPE", "position_DP"), summarise,
            N = length(error),
            Error = mean(error),
            sd = sd(error),
            se = sd / sqrt(N))
fface = "bold"
fsize = 4
rs = 3
gpplot <- ggplot(gprob, aes(position_DP,Probability, color=TYPE, shape=TYPE, linetype=TYPE) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  #xlab("Position relative to DP") + 
  ylab("Probability") +
  scale_x_continuous(limits = c(-2.5, 2.5), breaks= pretty_breaks()) + #, breaks=c(0,10,20,30)) +
  scale_y_continuous(limits = c(-0.01, 1.24), breaks= c(0, .25, .5,.75, 1.0)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  #coord_cartesian(ylim=c(-0.01, 2.01), xlim=c(-3,3), breaks= pretty_breaks()) + 
  geom_point(size=rel(3)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(20, 15, 16, 0)) +                  # Change shapes
  scale_color_manual(values=c("black", "red", "blue", "red")) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~PHASE) +
  theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(rs), face="plain"),
        axis.text.y = element_text(size=rel(rs), face="plain"),
        axis.title.x = element_blank(),
        axis.title.y = element_text(size=rel(1), face="bold"),
        #axis.title.y = element_blank(),
        title=element_text(size=rel(rs)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        #         legend.position = c(.1,.7),
        strip.text.x = element_text(size=rel(rs)),
        legend.position = c(.5,.35),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank() ) + 
  geom_vline(xintercept=0.5, linetype="dotted", size=0.5, color="red") +
  annotate("text", x=-2.48, y = 1.05, label = "f  o  r", color="darkgrey", size=fsize) +
  annotate("text", x = -2, y = 1.05, label = "m", color="black", size=fsize, fontface=fface) +
  annotate("text", x = -1, y = 1.05, label = "j", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  0, y = 1.05, label = "u", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = 1.05,  label = "l", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = 1.025,  label = "^", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = 1.14, label = "b", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = 1.14, label = "o", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = 1.23,  label = "t", color="blue", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = 1.23,  label = "i", color="blue", size=fsize, fontface=fface) 


gpEplot <- ggplot(gerr, aes(position_DP,Error, color=TYPE, shape=TYPE, linetype=TYPE) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Position relative to DP") + ylab("Error") +
  scale_x_continuous(limits = c(-2.5, 2.5), breaks= pretty_breaks()) + #, breaks=c(0,10,20,30)) +
  scale_y_continuous(limits = c(-0.01, 2.38), breaks= pretty_breaks()) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  #coord_cartesian(ylim=c(-0.01, 2.01), xlim=c(-3,3), breaks= pretty_breaks()) + 
  geom_point(size=rel(3)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(20, 15, 16, 0)) +                  # Change shapes
  scale_color_manual(values=c("black", "red", "blue", "red")) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~PHASE) +
  theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(rs), face="plain"),
        axis.text.y = element_text(size=rel(rs), face="plain"),
        axis.title.x = element_text(size=rel(1), face="bold"),
        axis.title.y = element_text(size=rel(1), face="bold"),
        #axis.title.y = element_blank(),
        title=element_text(size=rel(rs)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        #         legend.position = c(.1,.7),
        strip.text.x = element_text(size=rel(rs)),
        legend.position = c(.5,.25),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=0.5, linetype="dotted", size=0.5, color="red") +
  annotate("text", x=-2.48, y = 2.05, label = "f  o  r", color="darkgrey", size=fsize) +
  annotate("text", x = -2, y = 2.05, label = "m", color="black", size=fsize, fontface=fface) +
  annotate("text", x = -1, y = 2.05, label = "j", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  0, y = 2.05, label = "u", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = 2.05,  label = "l", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = 2.02,  label = "^", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = 2.2, label = "b", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = 2.2, label = "o", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = 2.35,  label = "t", color="blue", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = 2.35,  label = "i", color="blue", size=fsize, fontface=fface) 
#annotate("segment", x = 32, xend = 32, y = -.02, yend = -.265, colour = "black", size=.4, arrow=arrow( length = unit(0.25,"cm"))) +
#annotate(rep("text",4), label = c("for","m","y","u"), x = c(0, -2, -1, 0), y = rep(.005, 4))

#gpEplot  
#gpplot

png("PLOTS/GHD_prob_error.png", width=1200, height=600)
multiplot(gpplot, gpEplot)
dev.off()

#ggsave(plot=ghd_prob_err, filename="PLOTS/GHD_prob_error.png") #, height=10, width=12)

ggsave(plot=gpEplot, filename="PLOTS/GHD_error.png", height=5, width=12 )
ggsave(plot=gpplot, filename="PLOTS/GHD_prob.png", height=5, width=12 )

