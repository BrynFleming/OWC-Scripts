#Python script for those damn barplots bc i gave up on loops sorry
#started 7/13/2026 BVF

import os
import openpyxl as op
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

#set wd
os.chdir("C:\\Users\\brynv\\Documents\\Python\\OWC\\Historical Data")
os.getcwd()

#import files
#df = pd.read_excel('GPR df.xlsx', sheet_name = '1997 GPR')
#df = pd.read_excel('GPR df.xlsx', sheet_name = '1998 GPR')
#df = pd.read_excel('GPR df.xlsx', sheet_name = '2003 GPR')
df = pd.read_excel('GPR df.xlsx', sheet_name = '2004 GPR')
#df = pd.read_excel('GPR df.xlsx', sheet_name = '2019 GPR')
#df = pd.read_excel('GPR df.xlsx', sheet_name = '2020 GPR')
#df = pd.read_excel('GPR df.xlsx', sheet_name = '2024 GPR')
#df = pd.read_excel('GPR df.xlsx', sheet_name = '2025 GPR')

width = 0.2
x = np.arange(0,7)

fig, ax = plt.subplots()
#ax = ax.flatten()

ax.bar(x - 1.5*width, df['BR'],
       width, label = 'BR', color = 'limegreen', hatch = 'o')
ax.bar(x - 0.5*width, df['SU'],
       width, label = 'SU', color = 'royalblue', hatch = '-')
ax.bar(x + 0.5*width, df['OL'],
       width, label = 'OL', color = 'darkblue')
ax.bar(x + 1.5*width, df['WM'],
       width, label = 'WM', color = 'darkorange', hatch = '/')

ax.set_ylim(0,2)
ax.set_ylabel('GP/R')
ax.set_xticks(x)
ax.set_xticklabels(df['Month'])

plt.legend()
plt.axhline(y = 1, xmin = 0, xmax = 1, color = 'black')
plt.suptitle('GP/R in 2004')

plt.tight_layout()
fig.savefig('GPR 2004.png')
plt.show()
       
