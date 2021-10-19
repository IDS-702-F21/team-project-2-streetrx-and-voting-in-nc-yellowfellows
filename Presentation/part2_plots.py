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
df_long = pd.read_parquet("../Data/part2_df_long.parquet")
#%%
df_long