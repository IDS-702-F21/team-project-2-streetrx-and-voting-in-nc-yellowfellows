################################################################################
############################# Analysis Part II #################################
################################################################################


########### LOADING AND PREPROCESSING ############
voters = read.csv("Data/voter_stats_20201103.txt", sep="\t")
library(ggplot2)
library(dplyr)
library(tidyr)
library(data.table)

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
agg_by = list(history$county_desc, history$precinct_abbrv, history$vtd_abbrv, history$age, history$party_cd, history$race_code, history$ethnic_code, history$sex_code)
history_agg <- aggregate(history$total_voters, agg_by, sum)
colnames(history_agg) = c("county_desc", "precinct_abbrv", "vtd_abbrv", "age", "party_cd", "race_code", "ethnic_code", "sex_code", "total_voters")

# Joining
df = inner_join(voters, history_agg, suffix=c(".voters", ".history"), by=c("county_desc", "precinct_abbrv", "vtd_abbrv", "age", "party_cd", "race_code", "ethnic_code", "sex_code"))







