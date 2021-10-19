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
library(lme4)
library(knitr)
library(xtable)
library(kableExtra)
library(lattice)
library(arrow)

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
df$source[grepl(url_regex, df$source)] = "Internet"

# Merge NAs
df$source[df$source %in% c("", "N/A", "None")] = "No Input"

# Merge Internets
df$source[df$source %in% c("google", "Internet Pharmacy", "Poopy,", "Streetrx")] = "Internet"

df$source = as.factor(df$source)


########## Fix NAs in ppm and mgstr ##########
# TODO: Distribution of IVs by ppm_misssing/not-missing
# t = table(df[c("ppm_missing", "state")])
# !!! ATTENTION, pls validate, see above:
df = drop_na(df, "ppm")
df = drop_na(df, "mgstr")  # NOTE: ppm missing -> mgstr missing so this has no effect


###################### PRETTY TABLE BELOW ######################

transpose(df %>% count(mgstr))

xtable(df %>% filter(mgstr %in% c(1, 2.5, 15)))

################################################################

######### Fix mgstr ######### 
# mgstr 1, 2.5 and 15 have a) few data points and b) outlier ppm -> REMOVE
df = df %>% filter(mgstr %in% c(5, 10, 40))


########### EDA ############
# `mgstr` Distribution: only 6 discrete values
ggplot(data=df, aes(x=mgstr)) + geom_histogram()

# ppm cutoff
ggplot(data=df, aes(x=ppm)) + geom_histogram()  # few large outliers
# Use 99th percentile to remove outliers of ppm (removes 38 data points)
## TODO: Should include reference for reasonable price to justify assumptions (i.e. typo)
percentile_cuttoff = quantile(df$ppm, 0.95)
df = df %>% filter(ppm <= percentile_cuttoff)

# ppm by source
ggplot(data=df, aes(x=source, y=ppm)) + geom_boxplot()

# ppm by mgstr
table(df$fac_mgstr)  # 40 is not FDA approved
ggplot(data=df, aes(x=fac_mgstr, y=ppm)) + geom_boxplot()

# ppm by state
# ggplot(data=df, aes(x=state, y=ppm)) + geom_boxplot()
set.seed(42)
ggplot(data=df %>% filter(state %in% sample(levels(df$state), 5)), aes(x=state, y=ppm)) + geom_boxplot()

# ppm by region
ggplot(data=df, aes(x=USA_region, y=ppm)) + geom_boxplot()

# ppm by bulk
ggplot(data=df, aes(x=bulk_purchase, y=ppm)) + geom_boxplot()
# ggplot(data=df, aes(x=ppm, color=bulk_purchase)) + geom_histogram()

# CHECK: Only one region per state
table(df$state, df$USA_region)

#### Interactions ####
# bulk_purchase x mgstr
ggplot(data=df, aes(x=fac_mgstr, y=ppm)) + geom_boxplot() + facet_wrap(~bulk_purchase)

# bulk_purchase x source
ggplot(data=df, aes(x=source, y=ppm)) + geom_boxplot() + facet_wrap(~bulk_purchase)

# mgstr x source
ggplot(data=df, aes(x=fac_mgstr, y=ppm)) + geom_boxplot() + facet_wrap(~source)

# mgstr x USA_region
ggplot(data=df, aes(x=fac_mgstr, y=ppm)) + geom_boxplot() + facet_wrap(~USA_region)

# mgstr x state (20 state sample)
set.seed(42)
ggplot(data=df %>% filter(state %in% sample(levels(df$state), 20)), aes(x=fac_mgstr, y=ppm)) + geom_boxplot() + facet_wrap(~state) # **

# DO NOT!!! LOG TRANSFORMING ppm
# df$log_ppm = log(df$ppm)
# ppm close to zero messes up log -> remove more outliers instead (95th percentile instead of 99th)

########### Modeling ############

null_model <- lm(ppm ~ 1 , data=df)
full_model <- lm(ppm ~ source + fac_mgstr + bulk_purchase, data=df)
step_model <- step(null_model,
                   scope=formula(full_model),
                   direction='both',
                   trace=0)

summary(step_model)  # FINAL MODEL


########################## PRETTY TABLE BELOW ############################

summary_step = summary(step_model)
summaryprint = data.frame(summary_step$coefficients)

stars = c("***","***","***","***","***", ".", "**")
starsdf = data.frame(stars)

summarydf = data.frame(cbind(round(summaryprint,2),starsdf))
colnames(summarydf) = c("Estimate","Std. Error","t value", "Pr(>|t|)","")
knitr::kable(summarydf, format="latex", booktabs=TRUE) %>% 
  kable_styling(latex_options=c("hold_position"))

##########################################################################


##### Interactions ##### 

# source x fac_mgstr
source_mg_model <- lm(ppm ~ source + fac_mgstr + bulk_purchase + source*fac_mgstr, data=df)
anova(source_mg_model, step_model) # NS

# source x bulk
source_bulk_model <- lm(ppm ~ source + fac_mgstr + bulk_purchase + source*bulk_purchase, data=df)
anova(source_bulk_model, step_model) # NS

# fac_mgstr x bulk
mg_bulk_model <- lm(ppm ~ source + fac_mgstr + bulk_purchase + fac_mgstr*bulk_purchase, data=df)
anova(mg_bulk_model, step_model) # NS

# source x fac_mgstr AND source x bulk
source_mg_bulk_model <- lm(ppm ~ source + fac_mgstr + bulk_purchase + source*fac_mgstr + source*bulk_purchase, data=df)
anova(source_mg_model, step_model) # NS

# Conclude: use step_model as FINAL non-hierarchical baseline

########### HIERARCHICAL MODELING #############
# Level = State only
model1 <- lmer(ppm ~ fac_mgstr + bulk_purchase + source + (1 | state), data = df)
summary(model1) 
AIC(model1)

# Level = region only
model2 <- lmer(ppm ~ fac_mgstr + bulk_purchase + source + (1 | USA_region), data = df)
summary(model2)
AIC(model2)

# Levels = state + region
model3 <- lmer(ppm ~ fac_mgstr + bulk_purchase + source + (1 | USA_region) + (1 | state), data = df)
summary(model3)
AIC(model3)

anova(model3, model1)  # CONCLUDE: Use state AND region

########## DOTPLOT ##############
dotplot(ranef(model3))

x = ranef(model3, condVar=TRUE)$state

#sqrt(attr(x, "postVar"))
#x$`(Intercept)`

xdf = data.frame(pointest=ranef(model3, condVar=TRUE)$state, err=as.vector(sqrt(attr(x, "postVar"))))
xdf$pointestimate = xdf$X.Intercept.
xdf$state = rownames(xdf)
xdf$X.Intercept. = NULL

ggplot(xdf, aes(x=rownames(xdf), y=pointestimate)) +
  geom_point() +
  geom_errorbar(aes(x=rownames(xdf), ymin=pointestimate-1.96*err, ymax=pointestimate+1.96*err))

# write_parquet(xdf, "Data/part1_dotplot_data.parquet")

# TODO export and pretty!

############## MODEL ASSESSMENT ##################
# TODO: Is this ok???
resids = resid(model3)
preds = predict(model3)
assesment_df = data.frame(resids=resids, preds=preds)

ggplot(data=assesment_df, aes(x=preds, y=resids))+ geom_point()

plot(step_model)







################# EXPORT TO CSV AREA ####################

# write.csv(df, "Data/part1_df.csv")
# conclude: Use state+region hierarchy

df_with_pred = df # copy
#                  DANGER:  vvvvvv MODEL CHOICE!
df_with_pred$pred = predict(model3, df)
# write.csv(df_with_pred, "Data/part1_df_with_predictions.csv")

# prediction plot
I_WANT_TO_EXPORT_HUNDREDS_OF_CSVs = FALSE

if(I_WANT_TO_EXPORT_HUNDREDS_OF_CSVs){
pred_df = df # copy
overwrite_cols = c("bulk_purchase", "source", "fac_mgstr", "USA_region")
overwrite_df = expand.grid(unique(df$bulk_purchase), unique(df$source), unique(df$fac_mgstr), unique(df$USA_region))
colnames(overwrite_df) = overwrite_cols

#dfs = NULL

for (row in rownames(overwrite_df)){
  pred_df = df # copy
  for (overwrite_col in overwrite_cols){
    pred_df[, overwrite_col] = rep(overwrite_df[row, overwrite_col], nrow(pred_df))
  }
  
  #   ATTENTION:  vvvvvv MODEL CHOICE
  preds = predict(model3, pred_df)
  pred_df$pred = preds
  print(class(pred_df))
 
  
  overwrite_df[row, "pred"] = mean(preds)
  print(mean(preds))
  # write.csv(pred_df, paste0("Data/PredplotsData/part1_pred_df_", row, ".csv"))
}
}


########################## END OF CSV EXPORT AREA #############################


# Resids by group
resids_by_group = function(group_by_var){
  temp_df = data.frame(resids = residuals(source_mg_bulk_model), group=df[, group_by_var])
  #return(temp_df %>% group_by(group) %>% summarize(mean=mean(abs(resids))))
  ggplot(data=temp_df, aes(x=group, y=resids)) + geom_boxplot()
}

resids_by_group("source")
resids_by_group("bulk_purchase")
resids_by_group("fac_mgstr")
resids_by_group("state")
resids_by_group("USA_region")
