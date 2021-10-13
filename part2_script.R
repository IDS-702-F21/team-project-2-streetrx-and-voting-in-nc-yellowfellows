################################################################################
############################# Analysis Part II #################################
################################################################################


########### LOADING AND PREPROCESSING ############
df = read.csv("Data/voter_stats_20201103.txt", sep="\t")
library(ggplot2)
library(dplyr)
library(tidyr)
library(data.table)