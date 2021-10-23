#%%
from os import pread
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
#################### Pred by party age ####################
fig, axes = plt.subplots(1, 2, figsize=(16, 5))

party_colors = {
    "CST": "purple",
    "DEM": "#0015BC",
    "GRE": "#0F8040",
    "LIB": "#FBD02A",
    "REP": "#E21D26",
    "UNA": "0.5",
}

# Faded other parties
sns.pointplot(
    data=df_pred.query("not party_cd.isin(('DEM', 'REP'))"),
    y="pred",
    x="age",
    hue="party_cd",
    palette=party_colors,
    ax=axes[0],
)

# set alpha
_ = [c.set_alpha(0.3) for c in axes[0].collections]
_ = [l.set_alpha(0.3) for l in axes[0].lines]

# DEM & REP
sns.pointplot(
    data=df_pred.query("party_cd.isin(('DEM', 'REP'))"),
    y="pred",
    x="age",
    hue="party_cd",
    palette=party_colors,
    ax=axes[0],
)


def party_positioner(party: str):
    label_ys = (
        df_pred.query("age == 'Age 18 - 25'")
        .groupby("party_cd")["pred"]
        .mean()
        .to_dict()
    )

    if party == "REP":
        return label_ys[party] - 0.0125
    elif party == "CST":
        return label_ys[party] + 0.0125
    else:
        return label_ys[party]


for party in df_pred["party_cd"].unique():
    axes[0].text(
        x=-0.1,
        y=party_positioner(party),
        s=party,
        ha="right",
        va="center",
        weight="bold",
        color=party_colors[party],
        size=14,
    )

sns.despine()
axes[0].legend([], frameon=False)
axes[0].set_xlabel("Age Group")
axes[0].set_ylabel("Turnout Prediction")
axes[0].set_title("Predicted Turnout by Age Group", weight="bold")



#################### Pred by party sex ####################

# fig, axes = plt.subplots(figsize=(8, 5))

party_colors = {
    "CST": "purple",
    "DEM": "#0015BC",
    "GRE": "#0F8040",
    "LIB": "#FBD02A",
    "REP": "#E21D26",
    "UNA": "0.5",
}

# Faded other parties
sns.pointplot(
    data=df_pred.query("not party_cd.isin(('DEM', 'REP'))"),
    y="pred",
    x="sex_code",
    hue="party_cd",
    palette=party_colors,
    ax=axes[1],
)

# set alpha
_ = [c.set_alpha(0.3) for c in axes[1].collections]
_ = [l.set_alpha(0.3) for l in axes[1].lines]

# DEM & REP
sns.pointplot(
    data=df_pred.query("party_cd.isin(('DEM', 'REP'))"),
    y="pred",
    x="sex_code",
    hue="party_cd",
    palette=party_colors,
    ax=axes[1],
)


label_ys = df_pred.query("sex_code == 'F'").groupby("party_cd")["pred"].mean().to_dict()


for party in df_pred["party_cd"].unique():
    axes[1].text(
        x=-0.1,
        y=label_ys[party],
        s=party,
        ha="right",
        va="center",
        weight="bold",
        color=party_colors[party],
        size=14,
    )

sns.despine()
axes[1].legend([], frameon=False)
axes[1].set_xlabel("Sex")
axes[1].set_ylabel("Turnout Prediction")
axes[1].set_title("Predicted Turnout by Sex", weight="bold")
axes[1].set_xticklabels(['Female', 'Male', 'Undesignated'])
plt.tight_layout()
plt.savefig(
    "../Presentation/Images/part2_turnout_predplot_2in1.png", dpi=300, facecolor="white"
)
