rm(list=ls()) #clear all variables
library(ggplot2); library(plyr); library(dplyr); library(car); library(reshape); library(lme4); library(cowplot); library(stringi); library(scales); library(ggrepel)

# Fig 1: Gagnepain, Henson & Davis Model ----

# Read in GHD results
ghd <- read.csv("Gagnepain2012_Results.Frequency.csv") #read in df

# Read in GHD items to pull UP, DP
ghd_items <- read.csv("gagnepain_items_revised.csv")
ghd_items <- select(ghd_items, c("Trans_word_ELP","UP","DP"))
colnames(ghd_items)[1] <- "ORIGINAL"

# Add UP, DP to GHD df
ghd <- select(ghd, c("PHASE", "TYPE", "ORIGINAL", "ACTUAL", "position", "phoneme", "phon_prob", "error"))
ghd <- merge(ghd, ghd_items, by = "ORIGINAL")

str(ghd) # look at structure of df

# Rename levels of PHASE -- we'll collapse across post_Novel1 and post_Novel 2 later
levels(ghd$PHASE)=c("Pre training", "Post_Novel1", "Post_Novel2")

# Need to replicate pretraining df so that we can label nonwords as both trained novel words and untrained baseline nonwords
ghd$TYPE <- as.character(ghd$TYPE)

ghd_pretraining <- subset(ghd, PHASE == "Pre training")
ghd <- subset(ghd, PHASE != "Pre training")

ghd_pretraining_novel1 <- ghd_pretraining
ghd_pretraining_novel2 <- ghd_pretraining


ghd_pretraining_novel1$TYPE[ghd_pretraining_novel1$TYPE=="Novel1"] <- "Novel"
ghd_pretraining_novel1$TYPE[ghd_pretraining_novel1$TYPE=="Novel2"] <- "Baseline"

ghd_pretraining_novel2$TYPE[ghd_pretraining_novel2$TYPE=="Novel2"] <- "Novel"
ghd_pretraining_novel2$TYPE[ghd_pretraining_novel2$TYPE=="Novel1"] <- "Baseline"

ghd$TYPE[ghd$TYPE=="Novel1" & ghd$PHASE == "Post_Novel1"] <- "Novel"
ghd$TYPE[ghd$TYPE=="Novel2" & ghd$PHASE == "Post_Novel1"] <- "Baseline"

ghd$TYPE[ghd$TYPE=="Novel1" & ghd$PHASE == "Post_Novel2"] <- "Baseline"
ghd$TYPE[ghd$TYPE=="Novel2" & ghd$PHASE == "Post_Novel2"] <- "Novel"

ghd <- rbind(ghd_pretraining_novel1, ghd_pretraining_novel2, ghd)

ghd$TYPE <- as.factor(ghd$TYPE)

levels(ghd$TYPE)=c("Baseline","Novel","Source") # Call "original" items "source" words
ghd$TYPE = factor(ghd$TYPE, levels(ghd$TYPE)[c(3,2,1)]) # reorder levels of type

# Collapse across post_Novel1 and post_Novel 2
ghd$PHASE <- as.character(ghd$PHASE)
ghd$PHASE[ghd$PHASE == "Post_Novel1"] <- "Post training"
ghd$PHASE[ghd$PHASE == "Post_Novel2"] <- "Post training"
ghd$PHASE <- as.factor(ghd$PHASE)
ghd$PHASE = factor(ghd$PHASE, levels(ghd$PHASE)[c(2,1)]) # reorder levels of type


# Express phoneme position relative to DP and UP
ghd$position_DP <- ghd$position-ghd$DP
ghd$position_UP <- ghd$position-ghd$UP

head(ghd) # look at df


ghd.prob <-ddply(subset(ghd, position_DP < 3 & position_DP > -3), c("PHASE", "TYPE", "position_DP"), summarise,
                 N = length(phon_prob),
                 Probability = mean(phon_prob),
                 sd = sd(phon_prob),
                 se = sd / sqrt(N)) # summarise phoneme probabilities

ghd.err <-ddply(subset(ghd, position_DP < 3 & position_DP > -3), c("PHASE", "TYPE", "position_DP"), summarise,
                N = length(error),
                Error = mean(error),
                sd = sd(error),
                se = sd / sqrt(N)) # summarise phoneme prediction error

# General plotting parameters
fface = "bold"
fsize = 4

# Make top plot
fig1A <- ggplot(ghd.prob, aes(position_DP, Probability,
                              color = TYPE, shape = TYPE, linetype = TYPE)) +
  facet_grid(. ~PHASE) +
  xlab("Position relative to DP") +
  ylab("Probability") +
  scale_x_continuous(limits = c(-2.5, 2.5)) +
  scale_y_continuous(limits = c(-0.01, 1.24),
                     breaks = c(0, .25, .5,.75, 1.0)) +
  theme(text = element_text(size = 20),
        line = element_line(size = 2),
        title = element_text(size = rel(1)),
        # background & structure
        plot.background = element_rect(colour = NA, fill = "transparent"),
        panel.background = element_rect(colour = "black", fill = "transparent"),
        panel.grid.major = element_line(colour = "grey",
                                        linetype = "dotted",
                                        size = rel(0.25)),
        panel.grid.minor = element_blank(),
        legend.background = element_rect(colour = "darkgrey", fill = "white"),
        legend.key = element_blank(),
        legend.position = c(.5,.7),
        # titles & text
        axis.title.x = element_text(size = rel(2), face = "bold"),
        axis.title.y = element_text(size = rel(2), face = "bold"),
        axis.text.x = element_text(size = rel(2), face = "plain"),
        axis.text.y = element_text(size = rel(2), face = "plain"),
        strip.text.x = element_text(size = rel(2), face = "bold"), # facet labels
        legend.title = element_blank(),
        legend.text = element_text(size = rel(1.3))) +
  geom_line(size = rel(1)) +
  geom_point(size = rel(5)) +
  scale_shape_manual(values = c(15, 16, 2)) +
  scale_color_manual(values = c("#19c986", "#ffb520", "#c71993", "#ffb520")) +
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  geom_vline(xintercept = 0.5, linetype = "dotted", size = rel(0.5), color = "darkblue")

# set up labels
labels <- data.frame(position_DP = rep(c(-2.45, -2, -1, 0, 1, 2,
                                         1, 2, 1, 2), 2),
                     Probability = rep(c(rep(1.05, 6),
                                         1.14, 1.14, 1.23, 1.23), 2),
                     TYPE = rep(c(rep("Source", 6),
                                  rep("Novel", 2),
                                  rep("Baseline", 2)), 2),
                     PHASE = c(rep("Pre training", 10),
                               rep("Post training", 10)),
                     text = rep(c("f o r", "m", "j", "u", "l", "ʌ",
                                  "b", "o", "t", "i"), 2),
                     color = rep(c("darkgrey",
                                   rep("#19c986", 5),
                                   rep("#ffb520", 2),
                                   rep("#c71993", 2)), 2),
                     fontface = rep(c("plain", rep("bold", 9)), 2),
                     size = rep(c(rel(9),
                                  rep(rel(9), 9)), 2))

fig1A <- fig1A +
  geom_text(data = labels,
            label = labels$text,
            size = labels$size,
            fontface = labels$fontface,
            color = labels$color,
            show.legend = FALSE)

fig1A
ggsave(plot=fig1A, filename="fig1A.png",
       height = 9.75, width = 16.25,
       bg = "transparent")

# Make bottom plot
fig1B <- ggplot(ghd.err , aes(position_DP, Error,
                              color = TYPE, shape = TYPE, linetype = TYPE)) +
  facet_grid(. ~PHASE) +
  xlab("Position relative to DP") +
  ylab("Error") +
  scale_x_continuous(limits = c(-2.5, 2.5)) +
  scale_y_continuous(limits = c(-0.01, 2.38),
                     breaks =  pretty_breaks()) +
  theme(text = element_text(size = 20),
        line = element_line(size = 2),
        title = element_text(size = rel(1)),
        # background & structure
        plot.background = element_rect(colour = NA, fill = "transparent"),
        panel.background = element_rect(colour = "black", fill = "transparent"),
        panel.grid.major = element_line(colour = "grey",
                                        linetype = "dotted",
                                        size = rel(0.25)),
        panel.grid.minor = element_blank(),
        legend.background = element_rect(colour = "darkgrey", fill = "white"),
        legend.key = element_blank(),
        legend.position = c(.5,.25),
        # titles & text
        axis.title.x = element_text(size = rel(2), face = "bold"),
        axis.title.y = element_text(size = rel(2), face = "bold"),
        axis.text.x = element_text(size = rel(2), face = "plain"),
        axis.text.y = element_text(size = rel(2), face = "plain"),
        strip.text.x = element_text(size = rel(2), face = "bold"), # facet labels
        legend.title = element_blank(),
        legend.text = element_text(size = rel(1.3))) +
  geom_line(size = rel(1)) +
  geom_point(size = rel(5)) +
  scale_shape_manual(values = c(15, 16, 2)) +
  scale_color_manual(values = c("#19c986", "#ffb520", "#c71993", "#ffb520")) +
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  geom_vline(xintercept = 0.5, linetype = "dotted", size = rel(0.5), color = "darkblue")

# update labels
labels <- data.frame(position_DP = rep(c(-2.45, -2, -1, 0, 1, 2,
                                         1, 2, 1, 2), 2),
                     Error = rep(c(rep(2.05, 6),
                                   2.2, 2.2, 2.35, 2.35), 2),
                     TYPE = rep(c(rep("Source", 6),
                                  rep("Novel", 2),
                                  rep("Baseline", 2)), 2),
                     PHASE = c(rep("Pre training", 10),
                               rep("Post training", 10)),
                     text = rep(c("f o r", "m", "j", "u", "l", "ʌ",
                                  "b", "o", "t", "i"), 2),
                     color = rep(c("darkgrey",
                                   rep("#19c986", 5),
                                   rep("#ffb520", 2),
                                   rep("#c71993", 2)), 2),
                     fontface = rep(c("plain", rep("bold", 9)), 2),
                     size = rep(c(rel(9),
                                  rep(rel(9), 9)), 2))

fig1B <- fig1B +
  geom_text(data = labels,
            label = labels$text,
            size = labels$size,
            fontface = labels$fontface,
            color = labels$color,
            show.legend = FALSE)

fig1B
ggsave(plot=fig1B, filename="fig1B.png",
       height = 9.75, width = 16.25,
       bg = "transparent")


# Compute mean error pre/post-training, collapsed across word-type
ghd.err.preDP<- ddply(subset(ghd, position_DP < 0), c("PHASE"), summarise,
                               N = length(error),
                               Error = mean(error),
                               sd = sd(error),
                               se = sd / sqrt(N)) # summarise phoneme probabilities
ghd.err.preDP


# Fig S2: SRN ----

# Prepare df for plotting
srn <- read.csv('SRN_Result_Data.Use_Frequency.csv', 
                header = TRUE, sep = ',', na.strings = "#N/A")

# In the df, position is currently expressed relative to input
# So if position = 1, then we are asking what the model predicts for position *2* when given position 1 (e.g., predicting /O/ in position 2 if given /f/ in position 1)
# It would be more straightforward to express positions relative to output
# So that if the position = 2, we are asking what the model predicts for position 2 (and how much error is associated with that)
srn$Position <- as.integer(srn$Position)+1 # so we add 1 to the position number and set as an integer
srn$Phase <- as.factor(srn$Phase) # set phase as factor
srn$Type <- as.factor(srn$Type) # set type as factor

# We only want "Day2" labels (trained for 50 epochs)
srn <- droplevels(subset(srn, Phase != "Post_Novel1_Day1" & Phase != "Post_Novel2_Day1"))
srn$Phase = factor(srn$Phase, levels(srn$Phase)[c(3,1,2)]) # reorder levels of Phase

levels(srn$Phase)=c("Pre training", "Post_Novel1", "Post_Novel2")


# Read in GHD items to pull UP, DP
ghd_items <- read.csv("gagnepain_items_revised.csv")
ghd_items <- select(ghd_items, c("Trans_word_ELP","UP","DP"))
colnames(ghd_items)[1] <- "Original"

# Add UP, DP to GHD df
srn <- merge(srn, ghd_items, by = "Original")

# Need to replicate pretraining df so that we can label nonwords as both trained novel words and untrained baseline nonwords
srn$Type <- as.character(srn$Type)

srn_pretraining <- subset(srn, Phase == "Pre training")
srn <- subset(srn, Phase != "Pre training")

srn_pretraining_novel1 <- srn_pretraining
srn_pretraining_novel2 <- srn_pretraining


srn_pretraining_novel1$Type[srn_pretraining_novel1$Type=="Novel1"] <- "Novel"
srn_pretraining_novel1$Type[srn_pretraining_novel1$Type=="Novel2"] <- "Baseline"

srn_pretraining_novel2$Type[srn_pretraining_novel2$Type=="Novel2"] <- "Novel"
srn_pretraining_novel2$Type[srn_pretraining_novel2$Type=="Novel1"] <- "Baseline"

srn$Type[srn$Type=="Novel1" & srn$Phase == "Post_Novel1"] <- "Novel"
srn$Type[srn$Type=="Novel2" & srn$Phase == "Post_Novel1"] <- "Baseline"

srn$Type[srn$Type=="Novel1" & srn$Phase == "Post_Novel2"] <- "Baseline"
srn$Type[srn$Type=="Novel2" & srn$Phase == "Post_Novel2"] <- "Novel"

srn <- rbind(srn_pretraining_novel1, srn_pretraining_novel2, srn)

srn$Type <- as.factor(srn$Type)

levels(srn$Type)=c("Baseline","Novel","Source") # Call "original" items "source" words
srn$Type = factor(srn$Type, levels(srn$Type)[c(3,2,1)]) # reorder levels of Type

# Collapse across post_Novel1 and post_Novel 2
srn$Phase <- as.character(srn$Phase)
srn$Phase[srn$Phase == "Post_Novel1"] <- "Post training"
srn$Phase[srn$Phase == "Post_Novel2"] <- "Post training"
srn$Phase <- as.factor(srn$Phase)
srn$Phase = factor(srn$Phase, levels(srn$Phase)[c(2,1)]) # reorder levels of Type


# Express phoneme position relative to DP and UP
srn$position_DP <- srn$Position-srn$DP
srn$position_UP <- srn$Position-srn$UP








srn.Activation <-ddply(subset(srn, position_DP > -3 & position_DP < 3), 
                       c("Phase", "Type", "position_DP"), summarise,
                       N = length(Activation),
                       mean = mean(Activation),
                       sd = sd(Activation),
                       se = sd / sqrt(N)) # summarise activation at each time point

srn.MSE<-ddply(subset(srn, position_DP > -3 & position_DP < 3), 
               c("Phase", "Type", "position_DP"), summarise,
               N = length(MSE),
               mean = mean(MSE),
               sd = sd(MSE),
               se = sd / sqrt(N)) # measure MSE at each time step

# Activation plot

# Set up labels
labels <- data.frame(position_DP = rep(c(-2.45, -2, -1, 0, 1, 2,
                                         1, 2, 1, 2), 2),
                     mean = rep(c(rep(.285, 6),
                                  .305, .305, .325, .325), 2),
                     Type = rep(c(rep("Source", 6),
                                  rep("Novel", 2),
                                  rep("Baseline", 2)), 2),
                     Phase = c(rep("Pre training", 10),
                               rep("Post training", 10)),
                     text = rep(c("f o r", "m", "j", "u", "l", "ʌ",
                                  "b", "o", "t", "i"), 2),
                     color = rep(c("darkgrey",
                                   rep("#19c986", 5),
                                   rep("#ffb520", 2),
                                   rep("#c71993", 2)), 2),
                     fontface = rep(c("plain", rep("bold", 9)), 2),
                     size = rep(c(rel(9),
                                  rep(rel(9), 9)), 2))

# Make plot
figS2A <-
  ggplot(srn.Activation, aes(position_DP, mean,
                             color = Type, shape = Type, linetype = Type)) +
  facet_grid(. ~Phase) +
  xlab("Position relative to DP") +
  ylab("Activation") +
  scale_x_continuous(limits = c(-2.5, 2.5)) +
  scale_y_continuous(limits = c(0.025, .325),
                     breaks = c(0, .05, .1, .15, .2, .25)) +
  theme(text = element_text(size = 20),
        line = element_line(size = 2),
        title = element_text(size = rel(1)),
        # background & structure
        plot.background = element_rect(colour = NA, fill = "transparent"),
        panel.background = element_rect(colour = "black", fill = "transparent"),
        panel.grid.major = element_line(colour = "grey",
                                        linetype = "dotted",
                                        size = rel(0.25)),
        panel.grid.minor = element_blank(),
        legend.background = element_rect(colour = "darkgrey", fill = "white"),
        legend.key = element_blank(),
        legend.position = c(.58,.2),
        # titles & text
        axis.title.x = element_text(size = rel(2), face = "bold"),
        axis.title.y = element_text(size = rel(2), face = "bold"),
        axis.text.x = element_text(size = rel(2), face = "plain"),
        axis.text.y = element_text(size = rel(2), face = "plain"),
        strip.text.x = element_text(size = rel(2), face = "bold"), # facet labels
        legend.title = element_blank(),
        legend.text = element_text(size = rel(1.3))) +
  geom_line(size = rel(1)) +
  geom_point(size = rel(5)) +
  scale_shape_manual(values = c(15, 16, 2)) +
  scale_color_manual(values = c("#19c986", "#ffb520", "#c71993", "#ffb520")) +
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  geom_vline(xintercept = 0.5, linetype = "dotted", size = rel(0.5), color = "darkblue")


figS2A <- figS2A +
  geom_text(data = labels,
            label = labels$text,
            size = labels$size,
            fontface = labels$fontface,
            color = labels$color,
            show.legend = FALSE)

figS2A
ggsave(plot=figS2A, filename="figS2A.png",
       height = 9.75, width = 16.25,
       bg = "transparent")

# Error plot

# Set up labels
labels <- data.frame(position_DP = rep(c(-2.45, -2, -1, 0, 1, 2,
                                         1, 2, 1, 2), 2),
                     mean = rep(c(rep(0.17, 6),
                                  0.18, 0.18, 0.19, 0.19), 2),
                     Type = rep(c(rep("Source", 6),
                                  rep("Novel", 2),
                                  rep("Baseline", 2)), 2),
                     Phase = c(rep("Pre training", 10),
                               rep("Post training", 10)),
                     text = rep(c("f o r", "m", "j", "u", "l", "ʌ",
                                  "b", "o", "t", "i"), 2),
                     color = rep(c("darkgrey",
                                   rep("#19c986", 5),
                                   rep("#ffb520", 2),
                                   rep("#c71993", 2)), 2),
                     fontface = rep(c("plain", rep("bold", 9)), 2),
                     size = rep(c(rel(9),
                                  rep(rel(9), 9)), 2))
# make plot
figS2B <-
  ggplot(srn.MSE, aes(position_DP, mean,
                      color = Type, shape = Type, linetype = Type)) +
  facet_grid(. ~Phase) +
  xlab("Position relative to DP") +
  ylab("Mean Squared Error") +
  scale_x_continuous(limits = c(-2.5, 2.5)) +
  scale_y_continuous(limits = c(0, 0.2),
                     breaks = pretty_breaks()) +
  theme(text = element_text(size = 20),
        line = element_line(size = 2),
        title = element_text(size = rel(1)),
        # background & structure
        plot.background = element_rect(colour = NA, fill = "transparent"),
        panel.background = element_rect(colour = "black", fill = "transparent"),
        panel.grid.major = element_line(colour = "grey",
                                        linetype = "dotted",
                                        size = rel(0.25)),
        panel.grid.minor = element_blank(),
        legend.background = element_rect(colour = "darkgrey", fill = "white"),
        legend.key = element_blank(),
        legend.position = c(.58,.2),
        # titles & text
        axis.title.x = element_text(size = rel(2), face = "bold"),
        axis.title.y = element_text(size = rel(2), face = "bold"),
        axis.text.x = element_text(size = rel(2), face = "plain"),
        axis.text.y = element_text(size = rel(2), face = "plain"),
        strip.text.x = element_text(size = rel(2), face = "bold"), # facet labels
        legend.title = element_blank(),
        legend.text = element_text(size = rel(1.3))) +
  geom_line(size = rel(1)) +
  geom_point(size = rel(5)) +
  scale_shape_manual(values = c(15, 16, 2)) +
  scale_color_manual(values = c("#19c986", "#ffb520", "#c71993", "#ffb520")) +
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  geom_vline(xintercept = 0.5, linetype = "dotted", size = rel(0.5), color = "darkblue")


figS2B <- figS2B +
  geom_text(data = labels,
            label = labels$text,
            size = labels$size,
            fontface = labels$fontface,
            color = labels$color,
            show.legend = FALSE)

figS2B
ggsave(plot=figS2B, filename="figS2B.png",
       height = 9.75, width = 16.25,
       bg = "transparent")

# Compute pre-DP error pre/post training
srn.err.preDP<- ddply(subset(srn, position_DP < 0), c("Phase"), summarise,
                      N = length(MSE),
                      Error = mean(MSE),
                      sd = sd(MSE),
                      se = sd / sqrt(N)) # summarise phoneme probabilities
srn.err.preDP

# Fig 2: TRACE Phoneme Activation ----

trace_phon <- read.table(fs::path("trace_ghd_phone_out", ext = "txt")) # read in df
names(trace_phon)=c("Cycle","Phase","Item","Type","File", "Phone","Act")
trace_phon$Phase = factor(trace_phon$Phase, levels(trace_phon$Phase)[c(2,1)])
levels(trace_phon$Phase)=c("Pre training", "Post training")
levels(trace_phon$Item)=c("Baseline","Novel","Source") # more informative item labels
levels(trace_phon$Type)=c("Replaced phoneme","Source phoneme   ") # more informative type labels
trace_phon$Type = factor(trace_phon$Type, levels(trace_phon$Type)[c(2,1)])
trace_phon$Condition = as.factor(paste(sep = " | ", trace_phon$Type, trace_phon$Item))

dsum<-ddply(trace_phon, c("Phase", "Condition", "Cycle"), summarise,
            N = length(Act),
            Activation = mean(Act),
            sd = sd(Act),
            se = sd / sqrt(N))
bluered=c("#19c986", "#ffb520","#c71993", "#ffb520", "#c71993")
rs=1.8
shapeValues  = c(16, 20, 1, 2, 18)
#levels(dsum$Condition)
#str(dsum)
dsum$Condition=factor(dsum$Condition)
#levels(dsum$Condition)
dsum$Condition = factor(dsum$Condition, levels(dsum$Condition)[c(5, 4, 3, 2, 1)])

# Make plot
fig2A = ggplot(dsum, aes(Cycle,Activation, group=Condition, color=Condition, shape=Condition, linetype=Condition) ) +
  geom_line() + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Phoneme activation") +
  #  scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  #  scale_y_continuous(limits = c(-0.2, 0.66)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  coord_cartesian(ylim=c(-0.2, 0.66), xlim=c(0,101)) + 
  geom_point(size=rel(3),data=subset(dsum, Cycle %% 4 == 1)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid",  "dashed", "solid")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~Phase) +
  theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(rs), face="plain"),
        axis.text.y = element_text(size=rel(rs), face="plain"),
        axis.title.x = element_text(size=rel(1), face="bold"),
        #        axis.title.y = element_blank(),
        axis.title.y = element_text(size=rel(1), face="bold"),
        title=element_text(size=rel(rs)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        #         legend.position = c(.1,.7),
        strip.text.x = element_text(size=rel(rs)),
        legend.position = c(.5,.66),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")
fig2A
ggsave(plot=fig2A, filename="fig2A.png",
       height = 12, width = 20,
       bg = "transparent")

fig2B = ggplot(dsum, aes(Cycle,Activation, group=Condition, color=Condition, shape=Condition, linetype=Condition) ) +
  geom_line(position=position_dodge(width=0.2)) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Phoneme activation") +
  coord_cartesian(ylim=c(-.11,.21), xlim=c(15,45)) + 
  #scale_x_continuous(limits = c(15, 45)) + #, breaks=c(0,10,20,30)) +
  #scale_y_continuous(limits = c(-0.11, 0.11)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  geom_point(size=rel(3),data=subset(dsum, Cycle %% 4 == 1),position=position_dodge(width=0.2)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid", "solid",  "dashed", "solid")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~Phase) +
  theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(rs), face="plain"),
        axis.text.y = element_text(size=rel(rs), face="plain"),
        axis.title.x = element_text(size=rel(1), face="bold"),
        axis.title.y = element_text(size=rel(1), face="bold"),
        title=element_text(size=rel(rs)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        #         legend.position = c(.1,.7),
        strip.text.x = element_text(size=rel(rs)),
        legend.position = c(.62,.82),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")
fig2B
ggsave(plot=fig2B, filename="fig2B.png",
       height = 6, width = 10,
       bg = "transparent")

# Fig 3: TRACE - Lexical Feedback  ----
trace_comb<-read.table("trace_ghd_comb_out.txt",header=TRUE)  
head(trace_comb)  
trace_comb <- trace_comb[1:11]
names(trace_comb)=c("Cycle", "PhoneInhib", "PhoneSum", "PhoneSumPos", "LexInhib", "LexSum", "LexSumPos", "PWsum", "WPsum", "Item", "Phase")
trace_comb$Phase = factor(trace_comb$Phase, levels(trace_comb$Phase)[c(2,1)]) # reorder levels of phase
levels(trace_comb$Phase)=c("Pre training", "Post training") # more informative labels for levels
levels(trace_comb$Item)=c("Baseline","Novel","Source") # more informative labels for levels of item
trace_comb$Item = factor(trace_comb$Item, levels(trace_comb$Item)[c(3,2,1)])  # reorder levels of item


lex.FB<-ddply(trace_comb, c("Phase", "Item", "Cycle"), summarise,
              N = length(WPsum),
              Feedback = mean(WPsum),
              sd = sd(WPsum),
              se = sd / sqrt(N)) # summarise total amount of feedback from word layer to phoneme layer over time

# amount of feedback flowing from word to phoneme layer over time
fig3 = ggplot(lex.FB, aes(Cycle,Feedback, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Lexical feedback") +
  #scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  #scale_y_continuous(limits = c(0, 0.51)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  coord_cartesian(ylim=c(0, 0.51), xlim=c(0,101)) + 
  geom_point(size=rel(3),data=subset(lex.FB, Cycle %% 4 == 1)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(0,20,2)) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
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
        legend.position = c(.5,.66),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")  #       legend.key = element_blank()) +
fig3
ggsave(plot=fig3, filename="fig3.png",
       height = 6, width = 10,
       bg = "transparent")

# Fig 4: TRACE - Summed Lexical Activation  ----
lex.SUM<-ddply(trace_comb, c("Phase", "Item", "Cycle"), summarise,
               N = length(LexSum),
               Competition = mean(LexSum),
               sd = sd(LexSum),
               se = sd / sqrt(N))

fig4 = ggplot(lex.SUM, aes(Cycle,Competition, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Summed lexical activation") +
  scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  #scale_y_continuous(limits = c(-0.5, 6)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  geom_point(size=rel(3),data=subset(lex.SUM, Cycle %% 4 == 1)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(0,20,2)) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
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
        legend.position = c(.5,.75),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")
fig4
ggsave(plot=fig4, filename="fig4.png",
       height = 6, width = 10,
       bg = "transparent")

# Fig 5: TRACE - Summed Phoneme Activation  ----
phon.SUM<-ddply(trace_comb, c("Phase", "Item", "Cycle"), summarise,
                N = length(PhoneSum),
                Competition = mean(PhoneSum),
                sd = sd(PhoneSum),
                se = sd / sqrt(N))

fig5 = ggplot(phon.SUM, aes(Cycle,Competition, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Summed phoneme activation") +
  scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  #scale_y_continuous(limits = c(-0.5, 6)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  geom_point(size=rel(3),data=subset(phon.SUM, Cycle %% 4 == 1)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=c(0,20,2)) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
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
        legend.position = c(.5,.75),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")
fig5
ggsave(plot=fig5, filename="fig5.png",
       height = 6, width = 10,
       bg = "transparent")

# Figure S3: TRACE Activation of Source Word ----

trace_lex <- read.table(fs::path("trace_ghd_lex_out", ext = "txt")) # read in df

names(trace_lex)=c("Cycle", "Phase", "Input", "Item", "TRACEwrd", "Word", "Trainer", "Stimulus", "Act")
# 1 = Cyle
# 2 = phase (POST/PRE)
# 3 = input type (NON/TRAIN/ORIGINAL)
# 4 = Lexical item being tracked (Original/Trained — latter only available POST)
# 5 = Form of tracked item
# 6 = Base form — form of original
# 7 = Trainer form — novel item that is added to lexicon; set to NA for PRE
# 8 = Input form — actual string given to model
# 9 = activation value
trace_lex$Phase = factor(trace_lex$Phase, levels(trace_lex$Phase)[c(2,1)])
levels(trace_lex$Phase)=c("Pre training", "Post training")
levels(trace_lex$Input)=c("Baseline","Novel","Source") # more informative item labels

# We want to track activation of the source item when the source is given as input
lex_source <-ddply(subset(trace_lex, Input == "Source" & Item == "Original"), c("Phase", "Cycle"), summarise,
            N = length(Act),
            Activation = mean(Act),
            sd = sd(Act),
            se = sd / sqrt(N))

# Make plot
figS3 = ggplot(lex_source, aes(Cycle,Activation, group=Phase, color=Phase, linetype=Phase) ) +
  geom_line(size = 1.5) + #geom_text(aes(label = phon)) +
  geom_point(size = 2, data=subset(lex_source, Cycle %% 4 == 1), position=position_dodge(width=2)) +
  xlab("Time (TRACE cycles)") + ylab("Source word activation") +
  #  scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  #  scale_y_continuous(limits = c(-0.2, 0.66)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  coord_cartesian(ylim=c(0, 1), xlim=c(0,101)) +
  scale_color_manual(values=c("#19c986", "#ffb520")) +                  # Change colors
  scale_linetype_manual(values = c("solid", "solid")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(rs), face="plain"),
        axis.text.y = element_text(size=rel(rs), face="plain"),
        axis.title.x = element_text(size=rel(1), face="bold"),
        #        axis.title.y = element_blank(),
        axis.title.y = element_text(size=rel(1), face="bold"),
        title=element_text(size=rel(rs)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        #         legend.position = c(.1,.7),
        strip.text.x = element_text(size=rel(rs)),
        legend.position = c(.25,.86),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="red")

figS3
ggsave(plot=figS3, filename="figS3.png",
       height = 8, width = 8,
       bg = "transparent")
