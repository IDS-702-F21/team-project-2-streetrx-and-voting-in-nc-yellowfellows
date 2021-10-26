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
library(arrow)
library(lme4)
library(arm)
library(lattice)

# Subset 25 counties
# TODO: Report on which ones were chosen!
unique_counties = unique(voters$county_desc)
set.seed(42); used_counties = sample(unique_counties, size=25)
# print(paste("Used counties: ", as.vector(used_counties)))
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
agg_by = list(history$county_desc, history$age, history$voted_party_cd, history$race_code, history$ethnic_code, history$sex_code)
history_agg <- aggregate(history$total_voters, agg_by, sum)
colnames(history_agg) = c("county_desc", "age", "voted_party_cd", "race_code", "ethnic_code", "sex_code", "total_voters")

# Aggregate the voters data set
agg_by = list(voters$county_desc, voters$age, voters$party_cd, voters$race_code, voters$ethnic_code, voters$sex_code)
voters_agg <- aggregate(voters$total_voters, agg_by, sum)
colnames(voters_agg) = c("county_desc", "age", "party_cd", "race_code", "ethnic_code", "sex_code", "total_voters")


# Joining
# voters$voted_party_cd = voters$party_cd  # Aliasing so the join works
colnames(history_agg)[3] = "party_cd"
df = left_join(voters_agg, history_agg, suffix=c(".registered", ".actual"), by=c("county_desc", "age", "party_cd", "race_code", "ethnic_code", "sex_code"))

# replace NA voters with 0
# df$total_voters.actual = replace_na(df$total_voters.actual, 0)
df = df %>% drop_na(total_voters.actual)

# Transform: Lower number of actual voters to be at max number of registered voters
deltas = df$total_voters.actual - df$total_voters.registered
df[deltas > 0, "total_voters.actual"] = df[deltas > 0, "total_voters.actual"] - deltas[deltas > 0]

# Fix dtypes
factor_vars = c("county_desc", "party_cd", "race_code", "ethnic_code", "sex_code", "age")
for (fvar in factor_vars){
  df[,fvar] = as.factor(df[,fvar])
}


# Voter Turnout
df$turnout = df$total_voters.actual / df$total_voters.registered

#################### EDA ######################
# -> when you have a lot of data, they will all be significant so it's more about what you're interested in

ggplot(data=df, aes(x=turnout)) + geom_histogram(bins=10)

##### Bivariate Prop Tables #####
# for EDA: disaggregate 
df_long = df %>% mutate(new_response = map2(total_voters.actual, total_voters.registered, ~ c(rep(1, .x), rep(0, .y - .x)))) %>% unnest(cols = c(new_response))
# write_parquet(df_long, "Data/part2_df_long.parquet")


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
# POI: Pretty up for report
ggplot(data = df_long, aes(x=party_cd, y=new_response, color=age)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + theme_classic() # **

# party_cd x sex
# POI: Pretty up for report
ggplot(data = df_long, aes(x=party_cd, y=new_response, color=sex_code)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + theme_classic() # ***

# party_cd x race
ggplot(data = df_long, aes(x=party_cd, y=new_response, color=race_code)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + theme_classic() # ***

# age x sex
ggplot(data = df_long, aes(x=age, y=new_response, color=sex_code)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + theme_classic() # ***


# turnout vs. age by county
ggplot(data = df_long, aes(x=age, y=new_response)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + facet_wrap(~ county_desc) + theme_classic() # NS

# turnout vs. party by county
ggplot(data = df_long, aes(x=party_cd, y=new_response)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + facet_wrap(~ county_desc) + theme_classic() # *?


# turnout vs. sex by county
ggplot(data = df_long, aes(x=sex_code, y=new_response)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + facet_wrap(~ county_desc) + theme_classic() # *?


# turnout vs. race by county
# ggplot(data = df_long, aes(x=race_code, y=new_response)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + facet_wrap(~ county_desc) + theme_classic() # *?

# turnout vs. ethnic_code by county
# ggplot(data = df_long, aes(x=ethnic_code, y=new_response)) + geom_bar(position = "dodge", stat = "summary", fun.y = "mean") + facet_wrap(~ county_desc) + theme_classic() # *?
# -> too few data points in HL cat


############# MODELING #############
null_model = glm(cbind(total_voters.actual, total_voters.registered - total_voters.actual) ~ 1, family=binomial(), data=df)
full_model = glm(cbind(total_voters.actual, total_voters.registered - total_voters.actual) ~ party_cd + race_code + ethnic_code + sex_code + age, family=binomial(), data=df)

summary(null_model)
summary(full_model)
step_model = step(null_model,
                scope=formula(full_model),
                direction='both',
                trace=0)
summary(step_model)  # keeps all variables


I_WANT_TO_WAIT_AGES_FOR_TRAINING = FALSE
if (I_WANT_TO_WAIT_AGES_FOR_TRAINING){
  model4 <- glmer(cbind(total_voters.actual, total_voters.registered - total_voters.actual) ~ party_cd + race_code + ethnic_code + sex_code + age + (1 | county_desc) + sex_code:party_cd + age:party_cd, data=df, family=binomial, control=glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5)))
} else {
 load("model4.Rdata")
}


pred_df = df
pred_df$pred = fitted(model4)
# write_parquet(pred_df, "Data/part2_pred_df.parquet")

ggplot(data=pred_df, aes(x=race_code, y=pred)) + geom_boxplot()

############# Model Interpretation #############
summary(model4)
dotplot(ranef(model4))  # consistent with EDA



############ PRETTY TABLE BELOW ############
summaryprint = summary(model4)

knitr::kable(summaryprint, format="latex", booktabs=TRUE) %>% 
  kable_styling(latex_options=c("hold_position"))

#############################################



######### Export data for plotting #########
# County-level
x = ranef(model4, condVar=TRUE)$county_desc
xdf = data.frame(pointest=ranef(model4, condVar=TRUE)$county_desc, err=as.vector(sqrt(attr(x, "postVar"))))
xdf$pointestimate = xdf$X.Intercept.
xdf$county_desc = rownames(xdf)
xdf$X.Intercept. = NULL
# write_parquet(xdf, "Data/part2_dotplot_data_county.parquet")

############# Basic Model Assessment #############
assess_df = data.frame(preds = fitted(model4), ytrue=df$turnout)
assess_df$residuals = assess_df$preds - assess_df$ytrue

# ggplot(data=assess_df, aes(x=ytrue, y=preds)) + geom_point()
ggplot(data=assess_df, aes(x=preds, y=residuals)) + geom_point(alpha=0.2)


############ Trying out Random Slopes ###########
# model5 <- glmer(cbind(total_voters.actual, total_voters.registered - total_voters.actual) ~ party_cd + race_code + ethnic_code + age + (1 | county_desc) + age:party_cd + (sex_code | county_desc), data=df, family=binomial, control=glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5)))
# Convergence errors: (sex_code | county_desc) & (party_cd | county_desc)


