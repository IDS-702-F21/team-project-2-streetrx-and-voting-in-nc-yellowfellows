#%%
import statsmodels.formula.api as smf
import statsmodels.api as sm
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

plt.rcParams["font.family"] = "Arial"
plt.rcParams["font.size"] = 14

LIGHTBLUE = "#03529B"
MIDDLE = "#48A9A6"
DARKBLUE = "#061953"
#%%
df1 = pd.read_csv("../Data/part1_pred_df.csv", index_col="Unnamed: 0")

#%%
sns.heatmap(pd.pivot_table(data=df1, index="bulk_purchase", columns="source"))


#%%
sns.pointplot(data=df1, x="source", y="pred")


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
sns.pointplot(data=total, x="source", y="pred", hue="fac_mgstr", ax=ax, palette=[LIGHTBLUE, MIDDLE, DARKBLUE])
sns.despine()
ax.legend([], [], frameon=False)

y_vals = total.query("source == 'Personal'").groupby("fac_mgstr")["pred"].mean().items()
for tup in y_vals:
    ax.text(3.2, tup[1] - 0.02, f"{tup[0]}mg", size=16, weight="bold")

