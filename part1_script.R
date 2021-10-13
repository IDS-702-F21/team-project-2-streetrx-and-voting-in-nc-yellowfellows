################################################################################
############################# Analysis Part I ##################################
################################################################################
# Group 1: Methadone


########### LOADING AND PREPROCESSING ############
load("Data/streetrx.RData")
library(ggplot2)
library(dplyr)
library(tidyr)
library(data.table)

# subset for methadone
df = streetrx[streetrx$api_temp == "methadone",]

# remove unused variables & subset
vars_to_remove = c("yq_pdate", "price_date", "city", "Primary_Reason", "country", "api_temp")
for (var in vars_to_remove){
  df[var] = NULL
}

########### MISSING VALUE ANALYSIS ############
apply(is.na(df), 2, mean)


########### Fix source variable ############
# replace urls with "URL"
df$source = as.character(df$source)
url_regex = "(http://|\\.)"
df$source[grepl(url_regex, df$source)] = "URL"

# Merge NAs
df$source[df$source %in% c("", "N/A", "None")] = "No Input"

# Merge Internets
df$source[df$source %in% c("google", "Internet Pharmacy", "Poopy,", "Streetrx")] = "Internet"

df$source = as.factor(df$source)

# TODO: Distribution of IVs by ppm_misssing/not-missing
# t = table(df[c("ppm_missing", "state")])
# !!! ATTENTION, pls validate, see above:
df = drop_na(df, "ppm")


