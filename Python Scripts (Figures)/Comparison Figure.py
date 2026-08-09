#Comparing bottle data and spatial data
#Started 7/15/2026 BVF

#load required packages
import os
import openpyxl as op
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

#set wd
os.chdir("C:\\Users\\brynv\\Documents\\Python\\OWC\\Bottle Data\\Actual Figures")
os.getcwd()

#import file
df = pd.read_excel('Mass Corr Bottle Data.xlsx', sheet_name = 'GPR NPR')

#define columns for each subplot
columns = ['SI',
           'WM',
           'RR']
err = ['SI stdev',
       'WM stdev',
       'RR stdev']

#define bar width
width = 0.2

#define figure structure
fig, ax = plt.subplots(sharey = True, sharex = True)

sonde = df[df['Method'] == 'Sonde']
bottle = df[df['Method'] == 'Bottle']

x = np.arange(len(bottle))

ax1 = fig.add_subplot(2,2,1)
ax2 = fig.add_subplot(2,2,2)
ax3 = fig.add_subplot(2,2,3)

for i, (col_name, err) in enumerate(zip(columns, err)):
    sonde = df[df['Method'] == 'Sonde']
    bottle = df[df['Method'] == 'Bottle']

    x = np.arange(len(bottle))
                                    
    ax1[i].bar(x - (0.5*width), bottle[col_name],
              width, label = 'Bottle',
              color = 'limegreen', hatch = 'o')
    ax1[i].bar(x + (0.5*width), sonde[col_name],
              width, label = 'Sonde',
              color = 'royalblue', hatch = '-')

    ax2[i].bar(x - (0.5*width), bottle[col_name],
              width, label = 'Bottle',
              color = 'limegreen', hatch = 'o')
    ax2[i].bar(x + (0.5*width), sonde[col_name],
              width, label = 'Sonde',
              color = 'royalblue', hatch = '-')

    ax3[i].bar(x - (0.5*width), bottle[col_name],
              width, label = 'Bottle',
              color = 'limegreen', hatch = 'o')
    ax3[i].bar(x + (0.5*width), sonde[col_name],
              width, label = 'Sonde',
              color = 'royalblue', hatch = '-')

    
    ax1[i].errorbar(x - (0.5*width), bottle[col_name],
                   fmt = 'none',
                   yerr = bottle[err],
                   ecolor = 'black',
                   capsize = 4)
    ax1[i].errorbar(x + (0.5*width), sonde[col_name],
                    fmt = 'none',
                    yerr = sonde[err],
                    ecolor = 'black',
                    capsize = 4)

    ax2[i].errorbar(x - (0.5*width), bottle[col_name],
                    fmt = 'none',
                    yerr = bottle[err],
                    ecolor = 'black',
                    capsize = 4)
    ax2[i].errorbar(x + (0.5*width), sonde[col_name],
                    fmt = 'none',
                    yerr = sonde[err],
                    ecolor = 'black',
                    capsize = 4)

    ax3[i].errorbar(x - (0.5*width), bottle[col_name],
                    fmt = 'none',
                    yerr = bottle[err],
                    ecolor = 'black',
                    capsize = 4)
    ax3[i].errorbar(x + (0.5*width), sonde[col_name],
                    fmt = 'none',
                    yerr = sonde[err],
                    ecolor = 'black',
                    capsize = 4)

plt.tight_layout()
plt.show()
    
