library(ggplot2)
library(reshape2)
library(gridExtra)
library(plyr)
library(scales)

##############################################################################
# GHD SRN PLOTS
##############################################################################

srn <- read.table("GHD_SRN/srn_DP_plus.txt",header=T)[c(seq(1,13),15)]
names(srn)=c("Position", "Original", "Actual", "Phase", "Type", "Act", "GHDerr", "MSE", "IH", "CH", "Hstate", "Habs", "HO", "DP_Position")
#levels(srn$Phase)
srn$Phase = factor(srn$Phase, levels(srn$Phase)[c(2,1)])
levels(srn$Phase)=c("Pre training", "Post training")
#levels(srn$Type)
levels(srn$Type)=c("Original","Trained","Untrained")
srn$DP_Position = srn$DP_Position + 1

srn.act<-ddply(subset(srn, DP_Position > -3 & DP_Position < 3), c("Phase", "Type", "DP_Position"), summarise,
               N = length(Act),
               Activation = mean(Act),
               sd = sd(Act),
               se = sd / sqrt(N))
#head(srn.act)
#str(srn.act)

srn.err<-ddply(subset(srn, DP_Position > -3 & DP_Position < 3), c("Phase", "Type", "DP_Position"), summarise,
               N = length(MSE),
               Error = mean(MSE),
               sd = sd(MSE),
               se = sd / sqrt(N))

fface = "bold"
fsize = 4
rs = 3
srnactplot <- ggplot(srn.act, aes(DP_Position,Activation, color=Type, shape=Type, linetype=Type) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Position relative to DP") + ylab("Activation") +
  scale_x_continuous(limits = c(-2.5, 2.5)) + #, breaks=c(0,10,20,30)) +
  scale_y_continuous(limits = c(-0, .315), breaks=c(0, .05, .1, .15, .2, .25)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  #coord_cartesian(ylim=c(-0.001, .29), xlim=c(-3,3)) + 
  geom_point(size=rel(3)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(20, 15, 16, 0)) +                  # Change shapes
  scale_color_manual(values=c("black", "red", "blue", "red")) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~Phase) +
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
        legend.position = c(.55,.17),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=0.5, linetype="dotted", size=0.5, color="red") +
  annotate("text", x=-2.48, y = .275, label = "f  o  r", color="darkgrey", size=fsize) +
  annotate("text", x = -2, y = .275, label = "m", color="black", size=fsize, fontface=fface) +
  annotate("text", x = -1, y = .275, label = "j", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  0, y = .275, label = "u", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .275,  label = "l", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .269,  label = "^", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .295, label = "b", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .295, label = "o", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .315,  label = "t", color="blue", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .315,  label = "i", color="blue", size=fsize, fontface=fface)
#srnactplot


srnerrplot <- ggplot(srn.err, aes(DP_Position,Error, color=Type, shape=Type, linetype=Type) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Position relative to DP") + ylab("Error") +
  scale_x_continuous(limits = c(-2.5, 2.5)) + #, breaks=c(0,10,20,30)) +
  scale_y_continuous(limits = c(0.123, .172), breaks=c (.13, .14, .15, .16)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  #coord_cartesian(ylim=c(-0.001, .29), xlim=c(-3,3)) + 
  geom_point(size=rel(3)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(20, 15, 16, 0)) +                  # Change shapes
  scale_color_manual(values=c("black", "red", "blue", "red")) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~Phase) +
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
        legend.position = c(.5,.15),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=0.5, linetype="dotted", size=0.5, color="red") +
  annotate("text", x=-2.48, y = .166, label = "f  o  r", color="darkgrey", size=fsize) +
  annotate("text", x = -2, y = .166, label = "m", color="black", size=fsize, fontface=fface) +
  annotate("text", x = -1, y = .166, label = "j", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  0, y = .166, label = "u", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .166,  label = "l", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .1655,  label = "^", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .169, label = "b", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .169, label = "o", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .172,  label = "t", color="blue", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .172,  label = "i", color="blue", size=fsize, fontface=fface)

#srnerrplot
ggsave(plot=srnerrplot, filename="PLOTS/srn_error.png", height=5, width=12 )
ggsave(plot=srnactplot, filename="PLOTS/srn_act.png", height=5, width=12 )

message("    ---- Saved basic SRN plots")

#####################################################
# ADDITIONAL SRN PLOTS

srn.check<-ddply(subset(srn, DP_Position > -3 & DP_Position < 3), c("Phase", "Type", "DP_Position"), summarise,
                 N = length(Hstate),
                 Hstate = mean(Hstate),
                 sd = sd(Hstate),
                 se = sd / sqrt(N))

srn.hid.plot <- ggplot(srn.check, aes(DP_Position,Hstate, color=Type, shape=Type, linetype=Type) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Position relative to DP") + ylab("Hidden (raw)") +
  scale_x_continuous(limits = c(-2.5, 2.5)) + #, breaks=c(0,10,20,30)) +
  #scale_y_continuous(limits = c(-0, .315), breaks=c(0, .05, .1, .15, .2, .25)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  #coord_cartesian(ylim=c(-0.001, .29), xlim=c(-3,3)) + 
  geom_point(size=rel(3)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(20, 15, 16, 0)) +                  # Change shapes
  scale_color_manual(values=c("black", "red", "blue", "red")) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~Phase) +
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
        legend.position = c(.55,.17),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=0.5, linetype="dotted", size=0.5, color="red") +
  annotate("text", x=-2.48, y = .275, label = "f  o  r", color="darkgrey", size=fsize) +
  annotate("text", x = -2, y = .275, label = "m", color="black", size=fsize, fontface=fface) +
  annotate("text", x = -1, y = .275, label = "j", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  0, y = .275, label = "u", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .275,  label = "l", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .269,  label = "^", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .295, label = "b", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .295, label = "o", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .315,  label = "t", color="blue", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .315,  label = "i", color="blue", size=fsize, fontface=fface)
#srn.hid.plot
ggsave(plot=srn.hid.plot, filename="PLOTS/srn_hid_raw.png", height=5, width=12 )

message("    ---- Saved hidden SRN plot")


srn.check<-ddply(subset(srn, DP_Position > -3 & DP_Position < 3), c("Phase", "Type", "DP_Position"), summarise,
                 N = length(Habs),
                 Habs = mean(Habs),
                 sd = sd(Habs),
                 se = sd / sqrt(N))

srn.hab.plot <- ggplot(srn.check, aes(DP_Position,Habs, color=Type, shape=Type, linetype=Type) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Position relative to DP") + ylab("Hidden (abs)") +
  scale_x_continuous(limits = c(-2.5, 2.5)) + #, breaks=c(0,10,20,30)) +
  scale_y_continuous(limits = c(155, 162), breaks=c(seq(155,165))) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  #coord_cartesian(ylim=c(-0.001, .29), xlim=c(-3,3)) + 
  geom_point(size=rel(3)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(20, 15, 16, 0)) +                  # Change shapes
  scale_color_manual(values=c("black", "red", "blue", "red")) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~Phase) +
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
        legend.position = c(.5,.8),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=0.5, linetype="dotted", size=0.5, color="red") +
  annotate("text", x=-2.48, y = .275, label = "f  o  r", color="darkgrey", size=fsize) +
  annotate("text", x = -2, y = .275, label = "m", color="black", size=fsize, fontface=fface) +
  annotate("text", x = -1, y = .275, label = "j", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  0, y = .275, label = "u", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .275,  label = "l", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .269,  label = "^", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .295, label = "b", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .295, label = "o", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .315,  label = "t", color="blue", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .315,  label = "i", color="blue", size=fsize, fontface=fface)
#srn.hab.plot
ggsave(plot=srn.hab.plot, filename="PLOTS/srn_hid_abs.png", height=5, width=12 )

srn.check<-ddply(subset(srn, DP_Position > -3 & DP_Position < 3), c("Phase", "Type", "DP_Position"), summarise,
                 N = length(IH),
                 IH = mean(IH),
                 sd = sd(IH),
                 se = sd / sqrt(N))

srn.ih.plot <- ggplot(srn.check, aes(DP_Position,IH, color=Type, shape=Type, linetype=Type) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Position relative to DP") + ylab("Input to hidden") +
  scale_x_continuous(limits = c(-2.5, 2.5)) + #, breaks=c(0,10,20,30)) +
  #scale_y_continuous(limits = c(-0, .315), breaks=c(0, .05, .1, .15, .2, .25)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  #coord_cartesian(ylim=c(-0.001, .29), xlim=c(-3,3)) + 
  geom_point(size=rel(3)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(20, 15, 16, 0)) +                  # Change shapes
  scale_color_manual(values=c("black", "red", "blue", "red")) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~Phase) +
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
        legend.position = c(.55,.17),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=0.5, linetype="dotted", size=0.5, color="red") +
  annotate("text", x=-2.48, y = .275, label = "f  o  r", color="darkgrey", size=fsize) +
  annotate("text", x = -2, y = .275, label = "m", color="black", size=fsize, fontface=fface) +
  annotate("text", x = -1, y = .275, label = "j", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  0, y = .275, label = "u", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .275,  label = "l", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .269,  label = "^", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .295, label = "b", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .295, label = "o", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .315,  label = "t", color="blue", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .315,  label = "i", color="blue", size=fsize, fontface=fface)
#srn.ih.plot
ggsave(plot=srn.ih.plot, filename="PLOTS/srn_ih.png", height=5, width=12 )

message("    ---- Saved input-hidden SRN plot")

srn.check<-ddply(subset(srn, DP_Position > -3 & DP_Position < 3), c("Phase", "Type", "DP_Position"), summarise,
                 N = length(CH),
                 CH = mean(CH),
                 sd = sd(CH),
                 se = sd / sqrt(N))

srn.ch.plot <- ggplot(srn.check, aes(DP_Position,CH, color=Type, shape=Type, linetype=Type) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Position relative to DP") + ylab("Context to hidden") +
  scale_x_continuous(limits = c(-2.5, 2.5)) + #, breaks=c(0,10,20,30)) +
  #scale_y_continuous(limits = c(-0, .315), breaks=c(0, .05, .1, .15, .2, .25)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  #coord_cartesian(ylim=c(-0.001, .29), xlim=c(-3,3)) + 
  geom_point(size=rel(3)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(20, 15, 16, 0)) +                  # Change shapes
  scale_color_manual(values=c("black", "red", "blue", "red")) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~Phase) +
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
        legend.position = c(.5,.8),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=0.5, linetype="dotted", size=0.5, color="red") +
  annotate("text", x=-2.48, y = .275, label = "f  o  r", color="darkgrey", size=fsize) +
  annotate("text", x = -2, y = .275, label = "m", color="black", size=fsize, fontface=fface) +
  annotate("text", x = -1, y = .275, label = "j", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  0, y = .275, label = "u", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .275,  label = "l", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .269,  label = "^", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .295, label = "b", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .295, label = "o", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .315,  label = "t", color="blue", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .315,  label = "i", color="blue", size=fsize, fontface=fface)
#srn.ch.plot
ggsave(plot=srn.ch.plot, filename="PLOTS/srn_ch.png", height=5, width=12 )

message("    ---- Saved context-hidden SRN plot")

#names(srn)

srn.check<-ddply(subset(srn, DP_Position > -3 & DP_Position < 3), c("Phase", "Type", "DP_Position"), summarise,
                 N = length(HO),
                 HO = mean(HO),
                 sd = sd(HO),
                 se = sd / sqrt(N))

srn.ho.plot <- ggplot(srn.check, aes(DP_Position,HO, color=Type, shape=Type, linetype=Type) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Position relative to DP") + ylab("Hidden to output") +
  scale_x_continuous(limits = c(-2.5, 2.5)) + #, breaks=c(0,10,20,30)) +
  #scale_y_continuous(limits = c(-0, .315), breaks=c(0, .05, .1, .15, .2, .25)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  #coord_cartesian(ylim=c(-0.001, .29), xlim=c(-3,3)) + 
  geom_point(size=rel(3)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(20, 15, 16, 0)) +                  # Change shapes
  scale_color_manual(values=c("black", "red", "blue", "red")) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~Phase) +
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
        legend.position = c(.5,.7),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=0.5, linetype="dotted", size=0.5, color="red") +
  annotate("text", x=-2.48, y = .075, label = "f  o  r", color="darkgrey", size=fsize) +
  annotate("text", x = -2, y = .075, label = "m", color="black", size=fsize, fontface=fface) +
  annotate("text", x = -1, y = .075, label = "j", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  0, y = .075, label = "u", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .075,  label = "l", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .069,  label = "^", color="black", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .095, label = "b", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .095, label = "o", color="red", size=fsize, fontface=fface) +
  annotate("text", x =  1, y = .115,  label = "t", color="blue", size=fsize, fontface=fface) +
  annotate("text", x =  2, y = .115,  label = "i", color="blue", size=fsize, fontface=fface)
#srn.ho.plot
ggsave(plot=srn.ho.plot, filename="PLOTS/srn_ho.png", height=5, width=12 )
message("    ---- Saved hidden-output SRN plot; started combined plot")

#png("srn_plots.png", height=20, width=10)
x<-grid.arrange(srnactplot, srnerrplot,
                srn.ih.plot, srn.ch.plot, 
                srn.hab.plot, srn.hid.plot, srn.ho.plot, nrow=4)
#dev.off()
#x
ggsave(plot=x, filename="PLOTS/srn_plots.png", height=18, width=20)
message("    ---- Saved combined plot; that's the last one! ")
