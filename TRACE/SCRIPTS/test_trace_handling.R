library(ggplot2)
library(tidyverse)
library(foreach)
library(data.table)


filelist <- commandArgs(trailingOnly = TRUE)

# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}

someplots = list()
atplot = 0
#filename = ii
foreach(filename = filelist)%do%{
  atplot = atplot + 1
  sf <- as.data.frame(fread(filename))
  ts = seq(0,98)
  tst = paste0("t",ts)
  names(sf) = c("Unk", "Feature", "Level", tst)
  sf$FeatLev = paste0(sf$Feature,sf$Level)
  
  sf.long <- gather(sf, Time, Value, t0:t98)[,4:6]
  #gsub( "t", "", as.character(sf.long$Time) n)
  sf.long$Time = gsub("t", "", sf.long$Time)
  sf.long$Time = as.integer(sf.long$Time)
  sf.long$FeatLev = as.factor(sf.long$FeatLev)
  
  sf <- sf.long[sf.long$Time < 51,]
  
  p <- ggplot(sf, aes(x=Time, y=FeatLev)) +
    geom_tile(aes(fill = Value), colour="white") +
    scale_fill_gradient(low="white",high="black") +
    #scale_fill_distiller(palette = "YlGnBu") +
    labs(title = filename,
         y = "Feature-Level")
  someplots[[atplot]] = p + 
    scale_y_discrete(limits = rev(levels(sf.long$FeatLev))) + 
    scale_x_continuous(limits = c(0,51)) + 
    geom_hline(yintercept=c(-0.5,9.5,18.5,27.5,36.5,45.5,54.5,63.5),colour="grey",lty=2) + 
    geom_vline(xintercept=seq(6,96,6),colour="grey",lty=3)
}

pdf("feature_plots.pdf", width=36, height=12)
multiplot(plotlist = someplots, cols=6)
dev.off()
