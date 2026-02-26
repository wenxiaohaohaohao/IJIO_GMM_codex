import pandas as pd, glob, os, re
base='D:/paper/IJIO_GMM_codex_en/1017/1022_non_hicks'
res_data=f'{base}/results/data'
files=sorted(glob.glob(f'{res_data}/ivdrop_C_*.dta'))
rows=[]
for f in files:
    name=os.path.basename(f).replace('.dta','')
    m=re.match(r'ivdrop_C_(G[12]_\d+_\d+)_drop_(.+)',name)
    if not m:
        continue
    grp,drop=m.group(1),m.group(2)
    df=pd.read_stata(f)
    d=df[df['group']==grp] if 'group' in df.columns else df
    if d.empty: d=df
    r=d.iloc[0].to_dict()
    out={'spec':'dropone','group':grp,'drop':drop,'source':name}
    for k in ['J_opt','J_df','J_p','N','b_k','b_l','b_m','b_amc','b_as','elas_k_mean','elas_l_mean','elas_m_mean','elas_k_negshare','elas_l_negshare','elas_m_negshare']:
        out[k]=r.get(k)
    rows.append(out)

bfile=f'{base}/data/work/nonhicks_points_by_group.dta'
if os.path.exists(bfile):
    bdf=pd.read_stata(bfile)
    for grp in ['G1_17_19','G2_39_41']:
        d=bdf[bdf['group']==grp] if 'group' in bdf.columns else bdf
        if len(d)==0: continue
        r=d.iloc[0].to_dict()
        out={'spec':'baseline_C','group':grp,'drop':'(none)','source':'nonhicks_points_by_group'}
        for k in ['J_opt','J_df','J_p','N','b_k','b_l','b_m','b_amc','b_as','elas_k_mean','elas_l_mean','elas_m_mean','elas_k_negshare','elas_l_negshare','elas_m_negshare']:
            out[k]=r.get(k)
        rows.append(out)

outdf=pd.DataFrame(rows)
outdf['rank_in_group']=outdf.groupby('group')['J_p'].rank(ascending=False,method='min')
outdf['jp_gate_pass']=outdf['J_p']>=1e-4
outdf=outdf.sort_values(['group','rank_in_group','spec','drop'])
out_path=f'{res_data}/r1_c_dropone_ranked_20260226.csv'
outdf.to_csv(out_path,index=False,encoding='utf-8-sig')
print('WROTE',out_path)
print(outdf[['group','spec','drop','J_p','J_opt','rank_in_group','jp_gate_pass','b_k','b_l','b_m','elas_k_mean','elas_l_mean','elas_m_mean']].to_string(index=False))
