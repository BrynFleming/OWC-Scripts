#Python script for OWC historical data
#Started 6/22/26 BVF

#load packages
import os
import openpyxl as op
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

#set wd
os.chdir("C:\\Users\\brynv\\Documents\\Python\\OWC\\Historical Data")
os.getcwd()

#import data
#df = pd.ExcelFile('GPR df.xlsx')
#print('Available sheets:', df.sheet_names)
df19 = pd.read_excel('GP df.xlsx', sheet_name = '2019')
df20 = pd.read_excel('GP df.xlsx', sheet_name = '2020')
df24 = pd.read_excel('GP df.xlsx', sheet_name = '2024')
df25 = pd.read_excel('GP df.xlsx', sheet_name = '2025')
df_list = [df19, df20, df24, df25]

sites = ['BR', 'DR', 'OL', 'WM']
years = ['2019 (High)', '2020 (High)', '2024 (Low)', '2025 (Low)']

#style dictionaries
site_colors = {'BR':'limegreen', 'DR':'royalblue',
               'OL':'darkblue', 'WM':'darkorange'}
site_markers = {'BR':'o', 'DR':'|', 'OL':'x', 'WM':'D'}

#define number of rows and columns for subplots
nrow=1
ncol=4

#define figure structure
fig, axes = plt.subplots(nrow, ncol, figsize = (10,4), sharey=True)
axs_flat = axes.flatten()

for i, ax, year in zip(df_list, axes, years): #enumerates vars from dflist and axes together
    for site in sites:
        ax.plot(i.index,
                i[site],
                label=site,
                color=site_colors[site],
                marker=site_markers[site])
        ax.legend()
        xticks = np.arange(0, 7, 1)
        xlabels = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct']
        ax.set_xticks(ticks=xticks, labels=xlabels)
        #ax.set_ylim(-1, 16)
        ax.set_title(f'{year}', fontsize=10)
fig.supylabel('GPP (mg O2/L/day)', fontsize=10)
plt.suptitle('Monthly Average Gross Productivity in Old Woman Creek',
             fontsize=16,
             fontweight='bold')
   
plt.tight_layout()
fig.savefig('Monthly GP_final.png')
plt.show()
    
    

