#%%
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib_inline

matplotlib_inline.backend_inline.set_matplotlib_formats("svg")

plt.rcParams["font.family"] = "Arial"
plt.rcParams["font.size"] = 16

LIGHTBLUE = "#03529B"
# MIDDLE = "#48A9A6"
MIDDLE = "#053186"
DARKBLUE = "#061953"

COL_DTYPES = {
    "ppm": "float",
    "state": "category",
    "USA_region": "category",
    "source": "category",
    "bulk_purchase": "category",
    "fac_mgstr": "category",
    "mgstr": "category",
    "pred": "float",
}
#%%
df1 = pd.read_csv("../Data/part1_pred_df.csv", index_col="Unnamed: 0")

clean_df = pd.read_csv(
    "../Data/part1_df_with_predictions.csv", index_col="Unnamed: 0", dtype=COL_DTYPES,
)

#%%
#################### Data Loading ####################
USE_RAW_DATA = False
if USE_RAW_DATA:
    print(f"[INFO] Using raw data!")
    dfs = [
        pd.read_csv(
            f"../Data/PredplotsData/part1_pred_df_{i}.csv", index_col="Unnamed: 0"
        ).assign(dfidx=i)
        for i in range(1, 121)
    ]

    total = pd.concat(dfs)
    # total.to_parquet("../Data/PredplotsTotal.parquet")

else:
    print(f"[INFO] Using parquet file!")
    total = pd.read_parquet("../Data/PredplotsTotal.parquet")

cat_cols = "state USA_region source bulk_purchase".split()
total[cat_cols] = total[cat_cols].astype("category")

#%%
#################### pred by source ####################
fig, ax = plt.subplots(figsize=(8, 5))
sns.pointplot(
    data=clean_df,
    x="source",
    y="pred",
    ci=95,
    hue="fac_mgstr",
    ax=ax,
    palette=[LIGHTBLUE, MIDDLE, DARKBLUE],
)
sns.despine()
ax.legend([], [], frameon=False)

y_vals = total.query("source == 'Personal'").groupby("fac_mgstr")["pred"].mean().items()
for tup in y_vals:
    ax.text(3.2, tup[1] - 0.02, f"{tup[0]}mg", size=16, weight="bold")


#%%
#################### Prediction by State ####################
state_order = (
    total.groupby("state")["pred"].mean().sort_values().index
)  # .to_series().replace(state_abbrevs).values
fig, ax = plt.subplots(figsize=(5, 11))
sns.pointplot(
    data=total,
    y="state",
    x="pred",
    ci=95,
    orient="h",
    order=state_order,
    ax=ax,
    color=DARKBLUE,
)
ax.set_yticklabels(ax.get_yticklabels(), size=11)
sns.despine()
ax.legend([], [], frameon=False)


#%%
#################### US Map ####################

import requests

response = requests.get(
    "https://gist.githubusercontent.com/mshafrir/2646763/raw/8b0dbb93521f5d6889502305335104218454c2bf/states_hash.json"
)
state_abbrevs = {v: k for k, v in response.json().items()}
state_abbrevs

import pandas as pd

state_df = (
    total.groupby("state")["pred"]
    .mean()
    .to_frame()
    .reset_index()
    .rename({"index": "state"}, axis=1)
)
state_df = state_df.assign(state=state_df.state.replace(state_abbrevs))
# state_df.head()

#%%
import plotly.express as px  # Be sure to import express

fig = px.choropleth(
    state_df,
    locations="state",
    color="pred",
    hover_name="state",
    locationmode="USA-states",
    color_continuous_scale=px.colors.sequential.Viridis,
)

fig.update_layout(
    title_text="State Rankings", geo_scope="usa",
)

fig.show()


#%%


