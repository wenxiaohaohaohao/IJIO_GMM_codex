import pandas as pd
f='D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks/results/data/ivdrop_C_G1_17_19_drop_mlag.dta'
df=pd.read_stata(f)
print(df.columns.tolist())
print(df.head(1).to_string(index=False))
