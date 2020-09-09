rm(list=ls()) #clear all variables
library(ggplot2); library(plyr); library(dplyr); library(car); library(reshape); library(lme4); library(cowplot); library(stringi); library(scales); library(ggrepel)

# Fig 1: Gagnepain, Henson & Davis Model ----

# Prepare df for plotting
ghd <- read.csv("GHD_DP_revised.csv") #read in df
str(ghd) # look at structure of df
ghd$PHASE = factor(ghd$PHASE, levels(ghd$PHASE)[c(2,1)]) # reorder levels of phase
levels(ghd$PHASE)=c("Pre training", "Post training") # more informative labels for phase
levels(ghd$TYPE)=c("Original","Trained","Untrained") # more informative labels for type
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
        legend.position = c(.5,.5),
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
  scale_shape_manual(values = c(20, 15, 16, 0)) +
  scale_color_manual(values = c("#19c986", "#ffb520", "#c71993", "#ffb520")) +
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  geom_vline(xintercept = 0.5, linetype = "dotted", size = rel(0.5), color = "darkblue")

# set up labels
labels <- data.frame(position_DP = rep(c(-2.45, -2, -1, 0, 1, 2,
                                         1, 2, 1, 2), 2),
                     Probability = rep(c(rep(1.05, 6),
                                         1.14, 1.14, 1.23, 1.23), 2),
                     TYPE = rep(c(rep("Original", 6),
                                  rep("Trained", 2),
                                  rep("Untrained", 2)), 2),
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
  scale_shape_manual(values = c(20, 15, 16, 0)) +
  scale_color_manual(values = c("#19c986", "#ffb520", "#c71993", "#ffb520")) +
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  geom_vline(xintercept = 0.5, linetype = "dotted", size = rel(0.5), color = "darkblue")

# update labels
labels <- data.frame(position_DP = rep(c(-2.45, -2, -1, 0, 1, 2,
                                         1, 2, 1, 2), 2),
                     Error = rep(c(rep(2.05, 6),
                                   2.2, 2.2, 2.35, 2.35), 2),
                     TYPE = rep(c(rep("Original", 6),
                                  rep("Trained", 2),
                                  rep("Untrained", 2)), 2),
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

# Fig 3: SRN ----

# Prepare df for plotting
srn <- read.csv('PC_SRN_Test_Activation_Flow_Fixed.csv', 
                header = TRUE, sep = ',', na.strings = "#N/A")
srn$Position <- as.integer(srn$Position) # set position as integer
srn$Pron <- as.factor(srn$Pron) # set pronunciation as factor
srn$Phase <- as.factor(srn$Phase) # set phase as factor
srn$Type <- as.factor(srn$Type) # set type as factor
srn$Phase <- factor(srn$Phase, levels = c("Pre", "Post")) # reorder levels for phase
levels(srn$Phase) <- c("Pre training", "Post training") # more informative labels for phase

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
                     Type = rep(c(rep("Original", 6),
                                  rep("Trained", 2),
                                  rep("Untrained", 2)), 2),
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
fig3A <-
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
  scale_shape_manual(values = c(20, 15, 16, 0)) +
  scale_color_manual(values = c("#19c986", "#ffb520", "#c71993", "#ffb520")) +
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  geom_vline(xintercept = 0.5, linetype = "dotted", size = rel(0.5), color = "darkblue")


fig3A <- fig3A +
  geom_text(data = labels,
            label = labels$text,
            size = labels$size,
            fontface = labels$fontface,
            color = labels$color,
            show.legend = FALSE)

fig3A
ggsave(plot=fig3A, filename="fig3A.png",
       height = 9.75, width = 16.25,
       bg = "transparent")

# Error plot

# Set up labels
labels <- data.frame(position_DP = rep(c(-2.45, -2, -1, 0, 1, 2,
                                         1, 2, 1, 2), 2),
                     mean = rep(c(rep(0.17, 6),
                                  0.18, 0.18, 0.19, 0.19), 2),
                     Type = rep(c(rep("Original", 6),
                                  rep("Trained", 2),
                                  rep("Untrained", 2)), 2),
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
fig3B <-
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
  scale_shape_manual(values = c(20, 15, 16, 0)) +
  scale_color_manual(values = c("#19c986", "#ffb520", "#c71993", "#ffb520")) +
  scale_linetype_manual(values = c("solid", "solid", "solid", "dashed")) +
  geom_vline(xintercept = 0.5, linetype = "dotted", size = rel(0.5), color = "darkblue")


fig3B <- fig3B +
  geom_text(data = labels,
            label = labels$text,
            size = labels$size,
            fontface = labels$fontface,
            color = labels$color,
            show.legend = FALSE)

fig3B
ggsave(plot=fig3B, filename="fig3B.png",
       height = 9.75, width = 16.25,
       bg = "transparent")

# Fig 4: TRACE Phoneme Activation ----

# Prepare df for plotting
trace.phon <- read.table(fs::path("ppc_phone_out", ext = "txt")) # read in df
head(trace.phon) # check df 
names(trace.phon)=c("Cycle","Phase","Item","Type","Phone","Act") # set up column names
trace.phon$Phase = factor(trace.phon$Phase, levels(trace.phon$Phase)[c(2,1)]) # set phase as factor 
levels(trace.phon$Phase)=c("Pre training", "Post training") # more informative phase labels
levels(trace.phon$Item)=c("Untrained","Trained","Original") # more informative item labels
levels(trace.phon$Type)=c("Replaced phoneme","Original phoneme   ") # more informative type labels
trace.phon$Type = factor(trace.phon$Type, levels(trace.phon$Type)[c(2,1)]) # set item as factor
trace.phon$Condition = as.factor(paste(sep = " | ", trace.phon$Type, trace.phon$Item)) # create condition column

trace.phon.sum <- ddply(trace.phon, c("Phase", "Condition", "Cycle"), summarise,
            N = length(Act),
            Activation = mean(Act),
            sd = sd(Act),
            se = sd / sqrt(N)) #summarise activation across time for each phase/condition

levels(trace.phon.sum$Condition) # check levels of condition
str(trace.phon.sum) # check type of each variable
trace.phon.sum$Condition=factor(trace.phon.sum$Condition) # set condition as factor
levels(trace.phon.sum$Condition) # check levels of condition

# General plotting parameters
shape_v  = c(20, 15, 16, 0, 1) # set up shapes for both Fig 4 plots
color_v = c("#19c986","#ffb520", "#c71993","#ffb520","#c71993") # set up colors for both Fig 4 plots
line_v = c("solid", "solid", "solid", "dashed", "dashed") # set up line type for both Fig 4 plots

# Plot for top panel
# Set up labels
labels <- data.frame(Cycle = c(50, 56, 71, 81, 81, 
                               50, 52, 69, 81, 81),
                     Activation = c(0.67, -0.16, 0.04, 0.57, 0.53,
                                    0.67, -0.16, 0.001, 0.57, 0.53),
                     Phase = c(rep("Pre training", 5),
                               rep("Post training", 5)),
                     Condition = rep(c("Original phoneme    | Original",
                                       "Replaced phoneme | Trained",
                                       "Replaced phoneme | Untrained",
                                       "Original phoneme    | Trained",
                                       "Original phoneme    | Untrained"), 2),
                     text = rep(c("/s/ | /art^st/",
                                  "/d/ | /art^da/",
                                  "/p/ | /art^pi/",
                                  "/s/ | /art^da/",
                                  "/s/ | /art^pi/"), 2))



# Make plot
fig4A = ggplot(trace.phon.sum, aes(Cycle, Activation,
                             group = Condition, color = Condition,
                             shape = Condition, linetype = Condition)) +
  facet_grid(. ~Phase) +
  xlab("Time (TRACE cycles)") +
  ylab("Phoneme activation") +
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
        legend.position = c(.45, .5),
        # titles & text
        axis.title.x = element_text(size = rel(2), face = "bold"),
        axis.title.y = element_text(size = rel(2), face = "bold"),
        axis.text.x = element_text(size = rel(2), face = "plain"),
        axis.text.y = element_text(size = rel(2), face = "plain"),
        strip.text.x = element_text(size = rel(2), face = "bold"), # facet labels
        legend.title = element_blank(),
        legend.text = element_text(size = rel(1.3))) +
  geom_line(size = rel(1)) +
  geom_point(size = rel(5), data = subset(trace.phon.sum, Cycle %% 4 == 1)) +
  scale_shape_manual(values = shape_v) +
  scale_color_manual(values = color_v) +
  scale_linetype_manual(values = line_v) +
  geom_vline(xintercept = 32, linetype = "dotted", size = rel(0.5), color = "darkblue")


fig4A <- fig4A +
  geom_text(data = labels,
            label = labels$text,
            size = rel(8),
            fontface = "bold",
            show.legend = FALSE)
fig4A
ggsave(plot=fig4A, filename="fig4A.png",
       height = 9.75, width = 16.25,
       bg = "transparent")

# Plot for bottom panel
# Set up labels
labels <- data.frame(Cycle = c(25, 40, 40, 25, 25, 
                               25, 40, 40, 25, 25),
                     Activation = c(-0.027, -0.092, -0.077, -0.057, -0.042, 
                                    -0.027, -0.077, -0.092, -0.057, -0.042),
                     Phase = c(rep("Pre training", 5),
                               rep("Post training", 5)),
                     Condition = rep(c("Original phoneme    | Original",
                                       "Replaced phoneme | Trained",
                                       "Replaced phoneme | Untrained",
                                       "Original phoneme    | Trained",
                                       "Original phoneme    | Untrained"), 2),
                     text = rep(c("/s/ | /art^st/",
                                  "/d/ | /art^da/",
                                  "/p/ | /art^pi/",
                                  "/s/ | /art^da/",
                                  "/s/ | /art^pi/"), 2))

# Make plot
fig4B = ggplot(trace.phon.sum, aes(Cycle, Activation,
                        group = Condition, color = Condition,
                        shape = Condition, linetype = Condition)) +
  facet_grid(. ~Phase) +
  xlab("Time (TRACE cycles)") +
  ylab("Phoneme activation") +
  coord_cartesian(xlim = c(15, 45),
                  ylim = c(-.11, .11)) +
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
        legend.position = "none",
        # titles & text
        axis.title.x = element_text(size = rel(2), face = "bold"),
        axis.title.y = element_text(size = rel(2), face = "bold"),
        axis.text.x = element_text(size = rel(2), face = "plain"),
        axis.text.y = element_text(size = rel(2), face = "plain"),
        strip.text.x = element_text(size = rel(2), face = "bold"), # facet labels
        legend.title = element_blank(),
        legend.text = element_text(size = rel(1.3))) +
  geom_line(size = rel(1)) +
  geom_point(size = rel(5), data = subset(trace.phon.sum, Cycle %% 4 == 1)) +
  scale_shape_manual(values = shape_v) +
  scale_color_manual(values = color_v) +
  scale_linetype_manual(values = line_v) +
  geom_vline(xintercept = 32, linetype = "dotted", size = rel(0.5), color = "darkblue")

fig4B <- fig4B +
  geom_text(data = labels,
            label = labels$text,
            size = rel(8),
            fontface = "bold",
            show.legend = FALSE)

fig4B 
ggsave(plot=fig4B, filename="fig4B.png",
       height = 9.75, width = 16.25,
       bg = "transparent")

# Fig 5: TRACE Lexical Feedback  ----

# Prepare df for plotting
trace.comb<-read.table(fs::path("ppc_comb_out", ext = "txt")) # read in df
head(trace.comb) # check df
names(trace.comb)=c("Cycle",
           "PhoneInhib", "PhoneSum", "PhoneSumPos",
           "LexInhib", "LexSum", "LexSumPos",
           "PWsum", "WPsum",
           "Item", "Phase") # give informative names to columns
trace.comb$Phase = factor(trace.comb$Phase, levels(trace.comb$Phase)[c(2,1)]) # reorder levels of phase
levels(trace.comb$Phase)=c("Pre training", "Post training") # more informative labels for levels
levels(trace.comb$Item)=c("Untrained", "Trained", "Original") # more informative labels for levels of item
trace.comb$Item = factor(trace.comb$Item, levels(trace.comb$Item)[c(3,2,1)]) # reorder levels of item

feedback<-ddply(trace.comb, c("Phase", "Item", "Cycle"), summarise,
                N = length(WPsum),
                Feedback = mean(WPsum),
                sd = sd(WPsum),
                se = sd / sqrt(N)) # summarise amount of feedback from word layer to phoneme layer over time

# General plotting parameters
shapeValues = c(20, 0, 1)
bluered = c("#19c986", "#ffb520", "#c71993")
fsize = 4
fface = "bold"
shape_v = c(20, 0, 1, 16, 15)
color_v = c("#19c986", "#ffb520", "#c71993")
line_v = c("solid", "dashed", "dotted",  "solid", "solid")

# Set up labels
labels <- data.frame(Cycle = c(60, 61, 83,
                               55, 55, 60),
                     Feedback = c(0.27, 0.41, 0.35,
                                  0.27, 0.30, 0.43),
                     Phase = c(rep("Pre training", 3),
                               rep("Post training", 3)),
                     Item = rep(c("Original",
                                  "Trained",
                                  "Untrained"), 2),
                     text = rep(c("/art^st/",
                                  "/art^da/",
                                  "/art^pi/"), 2))
# Make plot
fig5 = ggplot(feedback, aes(Cycle, Feedback,
                          group = Item, color = Item,
                          shape = Item, linetype = Item)) +
  facet_grid(. ~Phase) +
  xlab("Time (TRACE cycles)") +
  ylab("Lexical feedback") +
  coord_cartesian(xlim = c(0, 101),
                  ylim =c (0, 0.51)) +
  theme(text = element_text(size = 20),
        line = element_line(size = 2),
        title = element_text(size = rel(1)),
        # background & structure
        plot.background = element_rect(colour = NA, fill = "transparent"),
        panel.background = element_rect(colour = "black", fill = "transparent"),
        panel.grid.major = element_line(colour = "grey",
                                        linetype = "dotted",
                                        size = rel(0.5)),
        panel.grid.minor = element_blank(),
        legend.background = element_rect(fill = "white", colour = "black"),
        legend.position = c(0.5,0.85),
        legend.key = element_blank(),
        # titles & text
        axis.title.x = element_text(size = rel(2), face= "bold"),
        axis.title.y = element_text(size = rel(2), face= "bold"),
        axis.text.x = element_text(size = rel(2), face= "plain"),
        axis.text.y = element_text(size = rel(2), face= "plain"),
        strip.text.x = element_text(size = rel(2), face = "bold"),
        legend.text = element_text(size = rel(1.3)),
        legend.title = element_blank()) +
  geom_line(size = rel(1)) +
  geom_point(size = rel(5),
             data = subset(feedback, Cycle %% 4 == 1)) +
  scale_shape_manual(values = shape_v) +
  scale_color_manual(values = color_v) +
  scale_linetype_manual(values = line_v) +
  geom_vline(xintercept = 32,
             linetype = "dotted",
             size = rel(0.5),
             color = "darkblue")

fig5 <- fig5 +
  geom_text(data = labels,
            label = labels$text,
            size = rel(8),
            fontface = "bold",
            show.legend = FALSE)

fig5
ggsave(plot=fig5, filename="fig5.png",
       height = 9.75, width = 16.25,
       bg = "transparent")


# Bonus Fig: TRACE Lateral Inhibition ----

# Prepare df
lexcomp<-ddply(trace.comb, c("Phase", "Item", "Cycle"), summarise,
               N = length(LexSumPos),
               Competition = mean(LexSumPos),
               sd = sd(LexSumPos),
               se = sd / sqrt(N)) # summarise amount of inhibition in the lexical layer over time


head(lexcomp) # look at df

# Make plot
plot.lexcomp = ggplot(lexcomp, aes(Cycle,Competition, group=Item, color=Item, shape=Item, linetype=Item) ) +
  geom_line(size=.5) + #geom_text(aes(label = phon)) +
  xlab("Time (TRACE cycles)") + ylab("Lexical competition index") +
  scale_x_continuous(limits = c(0, 101)) + #, breaks=c(0,10,20,30)) +
  scale_y_continuous(limits = c(-0.5, 6)) + #scale_shape_discrete(solid=T) + #geom_point(shape = a)
  geom_point(size=rel(3),data=subset(lexcomp, Cycle %% 4 == 1)) +
  #  scale_fill_discrete(name="Noise level") +
  scale_shape_manual(values=shapeValues) +                  # Change shapes
  scale_color_manual(values=bluered) +                  # Change colors
  scale_linetype_manual(values = c("solid", "dashed", "dotted",  "solid", "solid")) +
  #  scale_linetype_manual(values=c(rep("solid",17))) +
  facet_grid(.~Phase) +
  theme(panel.background = element_rect(colour="black", fill="white"),
        axis.text.x = element_text(size=rel(1.5), face="plain"),
        axis.text.y = element_text(size=rel(1.5), face="plain"),
        axis.title.x = element_text(size=rel(1), face="bold"),
        axis.title.y = element_text(size=rel(1), face="bold"),
        #axis.title.y = element_blank(),
        title=element_text(size=rel(1.5)),
        legend.text = element_text(size = rel(1.5)),
        legend.title = element_blank(),
        #         legend.position = c(.1,.7),
        strip.text.x = element_text(size=rel(1.5)),
        legend.position = c(.5,.75),
        legend.background = element_rect(fill="white", colour="black"),
        panel.grid.major.y = element_line(colour = "grey", linetype = "dotted"),
        legend.key = element_blank()) +
  geom_vline(xintercept=32, linetype="dotted", size=0.5, color="darkblue")

plot.lexcomp

