# solution from https://stackoverflow.com/questions/4090169/elegant-way-to-check-for-missing-packages-and-install-them
packages.we.need <- c("ggplot2", "reshape2", "gridExtra", "plyr", "scales")
new.packages <- packages.we.need[!(packages.we.need %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

