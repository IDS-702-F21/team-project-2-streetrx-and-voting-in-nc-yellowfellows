################################################################################
############################# Analysis Part II #################################
################################################################################


########### LOADING AND PREPROCESSING ############
voters = read.csv("Data/voter_stats_20201103.txt", sep="\t")
library(ggplot2)
library(dplyr)
library(tidyr)
library(data.table)
library(purrr)

# Subset 25 counties
unique_counties = unique(voters$county_desc)
set.seed(42); used_counties = sample(unique_counties, size=25)
voters = voters %>% filter(county_desc %in% used_counties)
assertthat::are_equal(sort(unique(voters$county_desc)), sort(used_counties))

# Load & Subset History
history = read.csv("Data/history_stats_20201103.txt", sep="\t") %>%
  filter(county_desc %in% used_counties)

# Remove unused variables 
vars_to_remove = c("stats_type", "election_date", "update_date")
for (var in vars_to_remove){
  voters[var] = NULL
  history[var] = NULL
}

# Aggregate the history data set 
# TODO: User voter_party_cd instead of party_cd!!??
agg_by = list(history$county_desc, history$precinct_abbrv, history$age, history$party_cd, history$race_code, history$ethnic_code, history$sex_code)
history_agg <- aggregate(history$total_voters, agg_by, sum)
colnames(history_agg) = c("county_desc", "precinct_abbrv", "age", "party_cd", "race_code", "ethnic_code", "sex_code", "total_voters")

# Joining 
## NOTE: simplified assumptions if any :)
## TODO consider replacing NAs with zeros; for actual > registered, consider lowering the actual to match
df = left_join(voters, history_agg, suffix=c(".registered", ".actual"), by=c("county_desc", "precinct_abbrv", "age", "party_cd", "race_code", "ethnic_code", "sex_code"))

# replace NA voters with 0
df$total_voters.actual = replace_na(df$total_voters.actual, 0)

# Transform: Lower number of actual voters to be at max number of registered voters
deltas = df$total_voters.actual - df$total_voters.registered
df[deltas > 0, "total_voters.actual"] = df[deltas > 0, "total_voters.actual"] - deltas[deltas > 0]

# Fix dtypes
factor_vars = c("county_desc", "precinct_abbrv", "party_cd", "race_code", "ethnic_code", "sex_code", "age")
for (fvar in factor_vars){
  df[,fvar] = as.factor(df[,fvar])
}

# Delete VTD column now
df$vtd_abbrv = NULL

# Voter Turnout
df$turnout = df$total_voters.actual / df$total_voters.registered

#################### EDA ######################
# TODO: KEEP ALL DEMOGRAPHIC DATA SO FOCUS ONLY ON INTERACTIONS 
# -> when you have a lot of data, they will all be significant so it's more about what you're interested in

ggplot(data=df, aes(x=turnout)) + geom_histogram(bins=10)

##### Bivariate Prop Tables #####
# for EDA: disaggregate 
df_long = df %>% mutate(new_response = map2(total_voters.actual, total_voters.registered, ~ c(rep(1, .x), rep(0, .y - .x)))) %>% unnest(cols = c(new_response))

# vote vs sex
prop.table(table(df_long$new_response, df_long$sex_code), 2)

# vote vs age
prop.table(table(df_long$new_response, df_long$age), 2) # ***

# vote vs ethnicity
prop.table(table(df_long$new_response, df_long$ethnic_code), 2) # ***

# vote vs race
prop.table(table(df_long$new_response, df_long$race_code), 2) # *** but n for P[acific Islander] too small

# vote vs party_cd
prop.table(table(df_long$new_response, df_long$party_cd), 2) # **; GRE=green, CST=constitutional, both n < 1000

# vote vs county
prop.table(table(df_long$new_response, df_long$county_desc), 2) # *
# TODO: KEY IS TO SHOW THAT RESPONSE (TURNOUT) VARIES BY COUNTY TO JUSTIFY THE HIERARCHY 
# TODO: SIMILARLY SHOULD INCLUDE A VISUALIZATION OF VOTE VS SAMPLE OF PRECINCTS TO OBSERVE

#### Interactions ####
cond_prob <- function (df, col1, col2) {
  round(apply(table(df[, c(col1, col2)]) / sum(table(df[, c(col1, col2)])), 2, function(x) x/sum(x)), 2)
}

# party_cd x age
ggplot(data = df_long, aes(x=party_cd, y=new_response, color=age)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + theme_classic() # **

# party_cd x sex
ggplot(data = df_long, aes(x=party_cd, y=new_response, color=sex_code)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + theme_classic() # ***

# party_cd x race
ggplot(data = df_long, aes(x=party_cd, y=new_response, color=race_code)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + theme_classic() # ***

# age x sex
ggplot(data = df_long, aes(x=age, y=new_response, color=sex_code)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + theme_classic() # ***


############# MODELING #############




