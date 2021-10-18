#%%
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib_inline

matplotlib_inline.backend_inline.set_matplotlib_formats("svg")

plt.rcParams["font.family"] = "Arial"
plt.rcParams["font.size"] = 16

LIGHTBLUE = "#03529B"
MIDDLE = "#48A9A6"
DARKBLUE = "#061953"
#%%
df1 = pd.read_csv("../Data/part1_pred_df.csv", index_col="Unnamed: 0")

#%%
# sns.heatmap(pd.pivot_table(data=df1, index="bulk_purchase", columns="source"))
# sns.pointplot(data=df1, x="source", y="pred")


#%%
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
fig, ax = plt.subplots(figsize=(8, 5))
sns.pointplot(
    data=total,
    x="source",
    y="pred",
    ci="sd",
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
# prediction by state
state_order = (
    total.groupby("state")["pred"].mean().sort_values().index
)  # .to_series().replace(state_abbrevs).values
fig, ax = plt.subplots(figsize=(5, 11))
sns.pointplot(
    data=total,  # .assign(state=total.state.replace(state_abbrevs)),
    y="state",
    x="pred",
    ci=95,
    orient="h",
    order=state_order,
    # hue="fac_mgstr",
    # palette=[LIGHTBLUE, MIDDLE, DARKBLUE],
    ax=ax,
    color=DARKBLUE,
)
ax.set_yticklabels(ax.get_yticklabels(), size=11)
sns.despine()
ax.legend([], [], frameon=False)


#%%
# map
import requests

response = requests.get(
    "https://gist.githubusercontent.com/mshafrir/2646763/raw/8b0dbb93521f5d6889502305335104218454c2bf/states_hash.json"
)
state_abbrevs = {v: k for k, v in response.json().items()}
state_abbrevs

import pandas as pd

json_states = {
    "pred": {
        "Alabama": 0.8020048282,
        "Alaska": 0.8420293315,
        "Arizona": 0.716395655,
        "Arkansas": 0.8560357271,
        "California": 0.6988490181,
        "Colorado": 0.8277620474,
        "Connecticut": 0.7702176177,
        "Delaware": 0.7880977608,
        "Florida": 0.7775196163,
        "Georgia": 0.7717533448,
        "Guam": 0.7937179992,
        "Hawaii": 0.7770724269,
        "Idaho": 0.8023101994,
        "Illinois": 0.8201584395,
        "Indiana": 0.8471150486,
        "Iowa": 0.7751653548,
        "Kansas": 0.8725840502,
        "Kentucky": 0.8324279306,
        "Louisiana": 0.8349699408,
        "Maine": 0.801868449,
        "Maryland": 0.7874300889,
        "Massachusetts": 0.8224301037,
        "Michigan": 0.7694031026,
        "Minnesota": 0.761412035,
        "Mississippi": 0.7715762649,
        "Missouri": 0.7408909586,
        "Montana": 0.8069395932,
        "Nebraska": 0.7754652803,
        "Nevada": 0.7393698566,
        "New Hampshire": 0.8073597591,
        "New Jersey": 0.8357128322,
        "New Mexico": 0.8307704716,
        "New York": 0.789885026,
        "North Carolina": 0.8282733463,
        "North Dakota": 0.8086404496,
        "Ohio": 0.7874407742,
        "Oklahoma": 0.7552475944,
        "Oregon": 0.8115837469,
        "Pennsylvania": 0.7958448202,
        "Rhode Island": 0.7831408396,
        "South Carolina": 0.7950185647,
        "South Dakota": 0.8187278806,
        "Tennessee": 0.8698380373,
        "Texas": 0.7494800561,
        "USA": 0.8423730667,
        "Utah": 0.8163802693,
        "Vermont": 0.7971760274,
        "Virginia": 0.8176408096,
        "Washington": 0.842369032,
        "Washington, DC": 0.8221822426,
        "West Virginia": 0.7994596885,
        "Wisconsin": 0.7590591921,
        "Wyoming": 0.8259626513,
    }
}
state_df = pd.DataFrame(json_states).reset_index().rename({"index": "state"}, axis=1)
state_df = state_df.assign(state=state_df.state.replace(state_abbrevs))
state_df.head()

import plotly.express as px  # Be sure to import express

fig = px.choropleth(
    state_df,  # Input Pandas DataFrame
    locations="state",  # DataFrame column with locations
    color="pred",  # DataFrame column with color values
    hover_name="state",  # DataFrame column hover info
    locationmode="USA-states",
    color_continuous_scale=px.colors.sequential.ice,
)  # Set to plot as US States
fig.update_layout(
    title_text="State Rankings",  # Create a Title
    geo_scope="usa",  # Plot only the USA instead of globe
)

fig.show()  # Output the plot to the screen
