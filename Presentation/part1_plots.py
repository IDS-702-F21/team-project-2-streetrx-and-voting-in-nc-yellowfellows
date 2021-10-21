#%%
import matplotlib.pyplot as plt
import matplotlib_inline
import pandas as pd
import numpy as np
import seaborn as sns

#%%
#################### CONFIG ####################
matplotlib_inline.backend_inline.set_matplotlib_formats("svg")

plt.rcParams["font.family"] = "Arial"
plt.rcParams["font.size"] = 16

LIGHTBLUE = "#00539B"
# MIDDLE = "#48A9A6"
MIDDLE = "#053186"
DARKBLUE = "#012169"

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
#################### Data Loading ####################
df1 = pd.read_csv("../Data/part1_pred_df.csv", index_col="Unnamed: 0")

clean_df = pd.read_csv(
    "../Data/part1_df_with_predictions.csv", index_col="Unnamed: 0", dtype=COL_DTYPES,
)

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

raw_data = pd.read_parquet("../Data/part1_raw_data.parquet")
#%%
#################### Univariate ppm ####################
fig, ax = plt.subplots(figsize=(10, 10))
sns.histplot(raw_data["ppm"], bins=60)

for patch in ax.patches:
    patch.set_color(DARKBLUE)
    patch.set_edgecolor("0.9")

# pct_line_ymaxs = [1750, 1500, 1000]
pct_to_plot = [0.95, 0.99, 0.995]
pct_line_ymaxs = [0.5, 0.35, 0.25]
for pct, ymax in zip(pct_to_plot, pct_line_ymaxs):
    COLOR = "red" if pct == 0.95 else "0.4"
    percentile = np.quantile(raw_data["ppm"].dropna(), pct)
    ax.axvline(percentile, ls="--", color=COLOR, ymax=ymax * 0.97, ymin=0)
    ax.text(
        x=percentile + 0.7,
        y=ymax * 1900,
        s=f"{pct*100}th\npercentile",
        color=COLOR,
        va="top",
    )

# ax.text(x=20, y=500, s="Removing outliers > 95th percentile\ndeletes XXX data points.", bbox=dict(boxstyle='round', facecolor='white', alpha=0.5))
ax.set_title("Distribution of ppm", weight="bold")
sns.despine()
plt.tight_layout()
plt.savefig("Images/part1_univariate_ppm.png", facecolor="white", dpi=300)

#%%
#################### ppm by state for sample states ####################

# clean_df.groupby("state")["ppm"].agg(["median", "min", "max", "count"]).sort_values(
#     "median"
# )

states_to_boxplot = [
    "Alaska",
    "California",
    "Pennsylvania",
    "New York",
    "Louisiana",
    "Iowa",
]

fig, ax = plt.subplots(figsize=(10, 10))
_plot_df = clean_df.query("state.isin(@states_to_boxplot)").copy()
_plot_df["state"] = _plot_df["state"].cat.remove_unused_categories()
_count_df = _plot_df.groupby('state')['state'].count()
sns.boxplot(
    data=_plot_df,
    y="state",
    x="ppm",
    orient="h",
    color=LIGHTBLUE,
    medianprops=dict(color="0.9", linewidth=3),
    boxprops=dict(ec='k'),
    flierprops=dict(marker='x'),
)
sns.despine()
ax.spines["left"].set_visible(False)
ax.yaxis.set_tick_params(which="both", length=0)
ax.set_yticklabels([f"{lab.get_text()}\n(n = {_count_df[lab.get_text()]})" for lab in ax.get_yticklabels()])
ax.set_title("ppm per State (Sample)", weight='bold')
ax.set_ylabel(None)
plt.tight_layout()
plt.savefig("Images/part1_ppm_per_state.png", facecolor="white", dpi=300)


#%%
#################### pred by source ####################
fig, ax = plt.subplots(figsize=(10, 5))
palette3 = [MIDDLE, DARKBLUE, LIGHTBLUE]

sns.pointplot(
    data=clean_df,
    x="source",
    y="pred",
    ci=95,
    hue="fac_mgstr",
    ax=ax,
    palette=palette3,
)
sns.despine()
ax.legend([], [], frameon=False)

y_vals = (
    clean_df.query("source == 'Personal'").groupby("fac_mgstr")["pred"].mean().items()
)
for idx, tup in enumerate(y_vals):
    ax.text(
        3.2, tup[1] - 0.02, f"{tup[0]}mg", size=16, weight="bold", color=palette3[idx]
    )

ax.set_title("Predicted ppm per source by mgstr\n", weight="bold")
ax.set_xlabel("Source")
ax.set_ylabel("Predicted ppm\n")

plt.savefig("Images/ppm_source_mgstr.png", facecolor="white", dpi=300)

#%%
#################### Random Intercepts by State ####################

df_dotplot_state = pd.read_parquet(
    "../Data/part1_dotplot_data_state.parquet"
).sort_values(by="pointestimate")
df_dotplot_state["state"] = df_dotplot_state["state"].astype("category")

fig, ax = plt.subplots(figsize=(8, 10))

sns.pointplot(
    data=df_dotplot_state,
    y="state",
    x="pointestimate",
    xerr=df_dotplot_state["err"],
    order=df_dotplot_state["state"],
    ax=ax,
    color=DARKBLUE,
    zorder=10,
)

highlight_states = ["California", "Arizona", "Tennessee"]
ax.set_yticklabels(ax.get_yticklabels(), size=11)
for label in ax.get_yticklabels():
    label.set_color("k" if label.get_text() in highlight_states else "0.6")
    label.set_weight("bold" if label.get_text() in highlight_states else "normal")
    label.set_size(11.5 if label.get_text() in highlight_states else 10)

ax.errorbar(
    df_dotplot_state["pointestimate"],
    df_dotplot_state["state"],
    xerr=1.96 * df_dotplot_state["err"],
    zorder=0,
    color=DARKBLUE,
    ecolor=[
        DARKBLUE if label.get_text() in highlight_states else "0.7"
        for label in ax.get_yticklabels()
    ],
)
sns.despine()
ax.axvline(0, zorder=-1, color="0.6", linestyle="--")
ax.set_xlabel("(Intercept)")
ax.set_ylabel("State")
ax.set_title("Random Intercepts for States", weight="bold")
ax.spines["left"].set_visible(False)
ax.yaxis.set_tick_params(which="both", length=0)
plt.savefig("Images/intercept_by_state.png", facecolor="white", dpi=300)

#%%
#################### Random Intercepts by Region ####################

df_dotplot_region = (
    pd.read_parquet("../Data/part1_dotplot_data_region.parquet")
    .sort_values(by="pointestimate")
    .rename({"state": "region"}, axis=1)
)
df_dotplot_region["region"] = df_dotplot_region["region"].astype("category")

fig, ax = plt.subplots(figsize=(8, 10))

sns.pointplot(
    data=df_dotplot_region,
    y="region",
    x="pointestimate",
    xerr=df_dotplot_region["err"],
    order=df_dotplot_region["region"],
    ax=ax,
    color=DARKBLUE,
    zorder=10,
)

highlight_regions = ["South"]
for label in ax.get_yticklabels():
    label.set_weight("bold" if label.get_text() in highlight_regions else "normal")

ax.errorbar(
    df_dotplot_region["pointestimate"],
    df_dotplot_region["region"],
    xerr=1.96 * df_dotplot_region["err"],
    capsize=5,
    zorder=0,
    color=DARKBLUE,
)
sns.despine()
ax.axvline(0, zorder=-1, color="0.6", linestyle="--")
ax.set_xlabel("(Intercept)")
ax.set_ylabel("Region")
ax.set_title("Random Intercepts for Regions", weight="bold")
ax.spines["left"].set_visible(False)
ax.yaxis.set_tick_params(which="both", length=0)
plt.savefig("Images/intercept_by_region.png", facecolor="white", dpi=300)


#%%
# states_to_plot = ["Alabama", "Massachusetts", "California", "Kansas"]
# sns.catplot(
#     data=clean_df,
#     x="source",
#     y="ppm",
#     col="state",
#     col_wrap=5,
#     n_boot=None,
#     kind="box",
# )


#%%
#################### US Map ####################

import requests

response = requests.get(
    "https://gist.githubusercontent.com/mshafrir/2646763/raw/8b0dbb93521f5d6889502305335104218454c2bf/states_hash.json"
)
state_abbrevs = {v: k for k, v in response.json().items()}
state_abbrevs

import pandas as pd

state_df = df_dotplot_state.copy()

state_df = state_df.assign(state=state_df.state.replace(state_abbrevs)).rename(
    {"pointestimate": "Intercept"}, axis=1
)


#%%
import plotly.express as px

fig = px.choropleth(
    state_df,
    locations="state",
    color="Intercept",
    hover_name="state",
    locationmode="USA-states",
    color_continuous_scale=px.colors.sequential.Viridis,
)

fig.update_layout(
    title_text="State Rankings", geo_scope="usa",
)

fig.show()
fig.write_image("Images/us-map.png", scale=5)


#%%
############### QQ Plot ################
from statsmodels.graphics.gofplots import qqplot

#%%
fig, ax = plt.subplots(figsize=(8, 8))
qqplot(clean_df.pred.values, line="45", ax=ax)

#%%
import scipy.stats as stats
import statsmodels.api as sm
fig, ax = plt.subplots(figsize=(8, 8))

resids = clean_df.pred - clean_df.ppm
sm.qqplot(resids, stats.norm(loc=resids.mean(), scale=resids.std()), ax=ax, line="45")

#%%
sns.histplot(clean_df.pred - clean_df.ppm)