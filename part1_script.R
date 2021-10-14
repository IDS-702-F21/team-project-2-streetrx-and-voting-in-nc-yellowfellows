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

# REMOVE unused variables & subset
# Note: form_temp is ALWAYS pill/tablet -> REMOVE it
vars_to_remove = c("yq_pdate", "price_date", "city", "Primary_Reason", "country", "api_temp", "form_temp")
for (var in vars_to_remove){
  df[var] = NULL
}

# Helper Variables
df$fac_mgstr = as.factor(df$mgstr)

########### MISSING VALUE ANALYSIS & DATA CLEANING ############
levels(df$bulk_purchase) = c("Not Bulk", "Bulk")
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

######### Fix mgstr ######### 
# mgstr 1, 2.5 and 15 have a) few data points and b) outlier ppm -> REMOVE
df = df %>% filter(mgstr %in% c(5, 10, 40))

########## Fix NAs in ppm and mgstr ##########
# TODO: Distribution of IVs by ppm_misssing/not-missing
# t = table(df[c("ppm_missing", "state")])
# !!! ATTENTION, pls validate, see above:
df = drop_na(df, "ppm")
df = drop_na(df, "mgstr")  # NOTE: ppm missing -> mgstr missing so this has no effect




########### EDA ############
# `mgstr` Distribution: only 6 discrete values
ggplot(data=df, aes(x=mgstr)) + geom_histogram()

# ppm
ggplot(data=df, aes(x=ppm)) + geom_histogram()  # few large outliers
# Use 99th percentile to remove outliers of ppm (removes 38 data points)
## TODO: Should include reference for reasonable price to justify assumptions (i.e. typo)
percentile_cuttoff = quantile(df$ppm, 0.99)
df = df %>% filter(ppm <= percentile_cuttoff)

# ppm by source
ggplot(data=df, aes(x=source, y=ppm)) + geom_boxplot()

# ppm by mgstr
table(df$fac_mgstr)  # 40 is not FDA approved
ggplot(data=df, aes(x=fac_mgstr, y=ppm)) + geom_boxplot()

# ppm by state
# ggplot(data=df, aes(x=state, y=ppm)) + geom_boxplot()

# ppm by region
ggplot(data=df, aes(x=USA_region, y=ppm)) + geom_boxplot()

# ppm by bulk
ggplot(data=df, aes(x=bulk_purchase, y=ppm)) + geom_boxplot()
# ggplot(data=df, aes(x=ppm, color=bulk_purchase)) + geom_histogram()



# CHECK: Only one region per state
table(df$state, df$USA_region)
