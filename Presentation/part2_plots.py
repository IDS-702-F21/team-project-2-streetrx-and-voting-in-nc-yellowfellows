#%%
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib_inline

#%%
#################### CONFIG ####################
matplotlib_inline.backend_inline.set_matplotlib_formats("svg")

plt.rcParams["font.family"] = "Arial"
plt.rcParams["font.size"] = 16

LIGHTBLUE = "#03529B"
# MIDDLE = "#48A9A6"
MIDDLE = "#053186"
DARKBLUE = "#061953"

#%%
df_pred = pd.read_parquet("../Data/part2_pred_df.parquet")
#%%
sns.pointplot(
    data=df_pred,
    x='party_cd',
    y='pred',
    hue="sex_code"
)

#%%
sns.pointplot(
    data=df_pred,
    x='party_cd',
    y='pred',
    hue="age",
    order="DEM REP CST GRE LIB UNA".split()
)

#%%
sns.pointplot(
    data=df_pred,
    x='race_code',
    y='pred',
    # hue="sex_code"
)