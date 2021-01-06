library(ggplot2)
library(reshape2)
library(gridExtra)
library(plyr)
library(scales)

source("SCRIPTS/multiplot.R")

###################################
# PART 1: TRACE GHD PHONEME PLOTS #
###################################
message("Starting TRACE phoneme plots")

d<-read.table("GHD_TRACE/trace_ghd_phone_out.txt")  
names(d)=c("Cycle","Phase","Item","Type","File", "Phone","Act")
d$Phase = factor(d$Phase, levels(d$Phase)[c(2,1)])
levels(d$Phase)=c("Pre training", "Post training")
levels(d$Item)=c("Untrained","Trained","Original")
levels(d$Type)=c("Replaced phoneme","Original phoneme   ")
d$Type = factor(d$Type, levels(d$Type)[c(2,1)])
d$Condition = as.factor(paste(sep = " | ", d$Type, d$Item))

dsum<-ddply(d, c("Phase", "Condition", "Cycle"), summarise,
            N = length(Act),
            Activation = mean(Act),
            sd = sd(Act),
            se = sd / sqrt(N))
bluered=c("black", "blue","red", "blue", "red")
rs=1.8
shapeValues  = c(16, 1, 20, 18, 2)
dsum$Condition=factor(dsum$Condition)
dsum$Condition = factor(dsum$Condition, levels(dsum$Condition)[c(1, 3, 2, 5, 4)])

phone_act_zoom = ggplot(dsum, aes(Cycle,Activation, group=Condition, color=Condition, shape=Condition, linetype=Condition) ) +
  geom_line(position=position_dodge(width=0.2)) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Phoneme activation") +
  coord_cartesian(ylim=c(-.11,.21), xlim=c(15,45)) + 
  geom_point(size=rel(3),data=subset(dsum, Cycle %% 4 == 1),position=position_dodge(width=0.2)) +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid",  "solid", "dashed")) +
  facet_grid(.~Phase) +
theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(rs), face="plain"),
        axis.text.y = element_text(size=rel(rs), face="plain"),
        axis.title.x = element_text(size=rel(1), face="bold"),
        axis.title.y = element_text(size=rel(1), face="bold"),
        title=element_text(size=rel(rs)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        strip.text.x = element_text(size=rel(rs)),
        legend.position = c(.17,.82),
        legend.background = element_rect(fill="white", colour="black"),
      panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
      legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")

ggsave(plot=phone_act_zoom, filename="PLOTS/trace_ghd_phonemes_zoom.png", height=6, width=12 )
message("\t--- Created PLOTS/trace_ghd_phonemes_zoom.png")
  
phone_act = ggplot(dsum, aes(Cycle,Activation, group=Condition, color=Condition, shape=Condition, linetype=Condition) ) +
  geom_line() + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Phoneme activation") +
  coord_cartesian(ylim=c(-0.2, 0.66), xlim=c(0,101)) + 
  geom_point(size=rel(3),data=subset(dsum, Cycle %% 4 == 1)) +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dashed",  "solid", "solid")) +
  facet_grid(.~Phase) +
  theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(rs), face="plain"),
        axis.text.y = element_text(size=rel(rs), face="plain"),
        axis.title.x = element_text(size=rel(1), face="bold"),
        axis.title.y = element_text(size=rel(1), face="bold"),
        title=element_text(size=rel(rs)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        strip.text.x = element_text(size=rel(rs)),
        legend.position = c(.5,.66),
        legend.background = element_rect(fill="white", colour="black"),
  panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
  legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")

ggsave(plot=phone_act, filename="PLOTS/trace_ghd_phonemes.png", height=6, width=12 )
message("\t--- Created PLOTS/trace_ghd_phonemes.png")

####################################
# PART 2: TRACE GHD ACTIVITY PLOTS #
####################################

c<-read.table("GHD_TRACE/trace_ghd_comb_out.txt",header=TRUE)  
c$Phase = factor(c$Phase, levels(c$Phase)[c(2,1)])
levels(c$Phase)=c("Pre training", "Post training")
levels(c$Item)=c("Untrained","Trained","Word")
c$Item = factor(c$Item, levels(c$Item)[c(3,2,1)])

lex.POS<-ddply(c, c("Phase", "Item", "Cycle"), summarise,
            N = length(LexSumPos),
            Competition = mean(LexSumPos),
            sd = sd(LexSumPos),
            se = sd / sqrt(N))
lex.SUM<-ddply(c, c("Phase", "Item", "Cycle"), summarise,
               N = length(LexSum),
               Competition = mean(LexSum),
               sd = sd(LexSum),
               se = sd / sqrt(N))
lex.FB<-ddply(c, c("Phase", "Item", "Cycle"), summarise,
                N = length(WPsum),
                Feedback = mean(WPsum),
                sd = sd(WPsum),
                se = sd / sqrt(N))
lex.INHIB<-ddply(c, c("Phase", "Item", "Cycle"), summarise,
                  N = length(LexInhib),
                  Competition = mean(LexInhib),
                  sd = sd(LexInhib),
                  se = sd / sqrt(N))
phon.FF<-ddply(c, c("Phase", "Item", "Cycle"), summarise,
                N = length(PWsum),
                FF = mean(PWsum),
                sd = sd(PWsum),
                se = sd / sqrt(N))
phon.INHIB<-ddply(c, c("Phase", "Item", "Cycle"), summarise,
               N = length(PhoneInhib),
               Competition = mean(PhoneInhib),
               sd = sd(PhoneInhib),
               se = sd / sqrt(N))
phon.POS<-ddply(c, c("Phase", "Item", "Cycle"), summarise,
               N = length(PhoneSumPos),
               Competition = mean(PhoneSumPos),
               sd = sd(PhoneSumPos),
               se = sd / sqrt(N))
phon.SUM<-ddply(c, c("Phase", "Item", "Cycle"), summarise,
                N = length(PhoneSum),
                Competition = mean(PhoneSum),
                sd = sd(PhoneSum),
                se = sd / sqrt(N))

shapeValues = c(20, 2, 18)
bluered = c("black", "red", "blue")

##########################
######## LEX INHIB PLOT ##
##########################

# amount of inhibition in the lexical layer over time
lex.SUM.plot = ggplot(lex.SUM, aes(Cycle,Competition, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Total lexical activation") +
  scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  geom_point(size=rel(3),data=subset(lex.SUM, Cycle %% 4 == 1)) +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
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
        legend.position = c(.5,.75),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")

ggsave(plot=lex.SUM.plot, filename="PLOTS/trace_ghd_lex_act_sum.png", height=6, width=12 )
message("\t--- Created PLOTS/trace_ghd_lex_act_sum.png")

# amount of inhibition in the lexical layer over time
lex.POS.plot = ggplot(lex.POS, aes(Cycle,Competition, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Total positive lexical activation") +
  scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  scale_y_continuous(limits = c(-0.5, 6)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  geom_point(size=rel(3),data=subset(lex.POS, Cycle %% 4 == 1)) +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
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
        legend.position = c(.5,.75),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")

# amount of inhibition in the lexical layer over time
lex.INHIB.plot = ggplot(lex.INHIB, aes(Cycle,Competition, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Lexical inhibition") +
  scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  geom_point(size=rel(3),data=subset(lex.INHIB, Cycle %% 4 == 1)) +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
  facet_grid(.~Phase) +
  theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(rs), face="plain"),
        axis.text.y = element_text(size=rel(rs), face="plain"),
        axis.title.x = element_text(size=rel(1), face="bold"),
        axis.title.y = element_text(size=rel(1), face="bold"),
        title=element_text(size=rel(rs)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        strip.text.x = element_text(size=rel(rs)),
        legend.position = c(.5,.4),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")

ggsave(plot=lex.INHIB.plot, filename="PLOTS/trace_ghd_lex_inhib.png", height=6, width=12 )
message("\t--- Created PLOTS/trace_ghd_lex_inhib.png")

##########################
# FEEDBACK PLOT
##########################
# amount of feedback flowing from word to phoneme layer over time
lex.FB.plot = ggplot(lex.FB, aes(Cycle,Feedback, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Lexical feedback") +
  coord_cartesian(ylim=c(0, 0.51), xlim=c(0,101)) + 
  geom_point(size=rel(3),data=subset(lex.FB, Cycle %% 4 == 1)) +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
  facet_grid(.~Phase) +
  theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(rs), face="plain"),
        axis.text.y = element_text(size=rel(rs), face="plain"),
        axis.title.x = element_text(size=rel(1), face="bold"),
        axis.title.y = element_text(size=rel(1), face="bold"),
        title=element_text(size=rel(rs)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        strip.text.x = element_text(size=rel(rs)),
        legend.position = c(.5,.66),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")  #       legend.key = element_blank()) +

ggsave(plot=lex.FB.plot, filename="PLOTS/trace_ghd_lex_fb.png", height=6, width=12 )
message("\t--- Created PLOTS/trace_ghd_lex_fb.png")
  

##########################
# FEEDFORWARD p->w
##########################
# amount of feedforward signal from phonems to words over time
phon.FF.plot = ggplot(phon.FF, aes(Cycle,FF, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Phone-to-word feedforward") +
  coord_cartesian(xlim=c(0,101)) + 
  geom_point(size=rel(3),data=subset(phon.FF, Cycle %% 4 == 1)) +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
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
        legend.position = c(.5,.76),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red") 

ggsave(plot=phon.FF.plot, filename="PLOTS/trace_ghd_phone_word_ff.png", height=6, width=12 )
message("\t--- Created PLOTS/trace_ghd_phone_word_ff.png")

# amount of inhibition in the lexical layer over time
phon.SUM.plot = ggplot(phon.SUM, aes(Cycle,Competition, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Total phoneme activation") +
  scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  geom_point(size=rel(3),data=subset(phon.SUM, Cycle %% 4 == 1)) +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
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
        legend.position = c(.5,.75),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")

ggsave(plot=phon.SUM.plot, filename="PLOTS/trace_ghd_phon_act_sum.png", height=6, width=12 )
message("\t--- Created PLOTS/trace_ghd_phon_act_sum.png")

# amount of inhibition in the lexical layer over time
phon.POS.plot = ggplot(phon.POS, aes(Cycle,Competition, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Total positive phoneme activation") +
  scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  geom_point(size=rel(3),data=subset(phon.POS, Cycle %% 4 == 1)) +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
  facet_grid(.~Phase) +
  theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(rs), face="plain"),
        axis.text.y = element_text(size=rel(rs), face="plain"),
        axis.title.x = element_text(size=rel(1), face="bold"),
        axis.title.y = element_text(size=rel(1), face="bold"),
        title=element_text(size=rel(rs)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        strip.text.x = element_text(size=rel(rs)),
        legend.position = c(.5,.45),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")

#ggsave(plot=phon.POS.plot, filename="PLOTS/trace_ghd_phon_act_pos.png", height=6, width=12 )
#message("\t--- Created PLOTS/trace_ghd_phon_act_pos.png")

# amount of inhibition in the lexical layer over time
phon.INHIB.plot = ggplot(phon.INHIB, aes(Cycle,Competition, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Phoneme inhibition") +
  scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  geom_point(size=rel(3),data=subset(phon.INHIB, Cycle %% 4 == 1)) +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
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
        legend.position = c(.5,.4),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")

ggsave(plot=phon.INHIB.plot, filename="PLOTS/trace_ghd_phon_inhib.png", height=6, width=12 )
message("\t--- Created PLOTS/trace_ghd_phon_inhib.png")

lex.FB.plot2    = lex.FB.plot + theme(legend.position = "none")
lex.INHIB.plot2 = lex.INHIB.plot + theme(axis.title.x = element_blank()) 
lex.SUM.plot2 = lex.SUM.plot + theme(axis.title.x = element_blank()) + theme(legend.position = "none")
lex.POS.plot2 = lex.POS.plot + theme(axis.title.x = element_blank()) + theme(legend.position = "none")

phon.INHIB.plot2 = phon.INHIB.plot + theme(axis.title.x = element_blank()) 
phon.SUM.plot2 = phon.SUM.plot + theme(axis.title.x = element_blank()) + theme(legend.position = "none")
phon.POS.plot2 = phon.POS.plot + theme(axis.title.x = element_blank()) + theme(legend.position = "none")
phon.FF.plot2   = phon.FF.plot + theme(legend.position = "none")

phon.comb.plot<-grid.arrange(phon.INHIB.plot2, phon.SUM.plot2, phon.POS.plot2, phon.FF.plot2, 
                      nrow=4)
lex.comb.plot<-grid.arrange(lex.INHIB.plot2, lex.SUM.plot2, lex.POS.plot2, lex.FB.plot2, 
                             nrow=4)
ggsave(plot=phon.comb.plot, filename="PLOTS/trace_ghd_combined_phon.png", height=18, width=12)
message("\t--- Created PLOTS/trace_ghd_combined_phon.png")
ggsave(plot=lex.comb.plot, filename="PLOTS/trace_ghd_combined_lex.png", height=18, width=12)
message("\t--- Created PLOTS/trace_ghd_combined_lex.png")

##############################################################################
# PART 3: TRACE LEXICAL PLOT
##############################################################################

l<-read.table("GHD_TRACE/trace_ghd_lex_out.txt")
names(l)=c("Cycle", "Phase", "Input", "Item", "TRACEwrd", "Word", "Trainer", "Stimulus", "Act")
l$Phase = factor(l$Phase, levels(l$Phase)[c(2,1)])
levels(l$Phase)=c("Pre training", "Post training")
levels(l$Input)=c("Untrained","Trained","Original")
l$Input = factor(l$Input, levels(l$Input)[c(3,1,2)])
l$Condition = as.factor(paste(sep=" | ", l$Item, l$Input))

lexact<-ddply(l, c("Phase", "Condition", "Cycle"), summarise,
              N = length(Act),
              Activation = mean(Act),
              sd = sd(Act),
              se = sd / sqrt(N))

lexa = ggplot(lexact, aes(Cycle,Activation, group=Condition, color=Condition, 
                          size=Condition, shape=Condition, linetype=Condition) ) +
  geom_line(size=.5, position=position_dodge(width=2)) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Lexical activation") +
  coord_cartesian(ylim=c(-0.21, 1.01), xlim=c(0,101)) + 
  geom_point(data=subset(lexact, Cycle %% 4 == 1), position=position_dodge(width=2)) +
  scale_shape_manual(values=c(20, 21, 20, 2, 2, 2)) +                  # Change shapes
  scale_size_manual(values=c(3, 3, 2, 4, 3, 3)) +                  # Change shapes
  scale_color_manual(values=c("black", "red", "blue", "black", "red", "blue")) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dashed", "dashed", "dashed", "dashed")) +
  facet_grid(.~Phase) +
  theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(rs), face="plain"),
        axis.text.y = element_text(size=rel(rs), face="plain"),
        axis.title.x = element_text(size=rel(1), face="bold"),
        axis.title.y = element_text(size=rel(1), face="bold"),
        title=element_text(size=rel(rs)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        strip.text.x = element_text(size=rel(rs)),
        legend.position = c(.64,.82),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red") 

ggsave(plot=lexa, filename="PLOTS/trace_lex_activation.png", height=6, width=12 )
message("\t--- Created PLOTS/trace_lex_activation.png")


##########################################################
message("All done")
													      
													      

