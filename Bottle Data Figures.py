#Editable version of fuckery for generating bottle data figures
#Started 7/7/2026 BVF
#Updated to include errobars and secondary PAR axis 7/10/2026 BVF
#Updated to add PAR to legend, line at y=1, change y label and PAR unit 7/22 BVF

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
test = pd.read_excel('Mass Corr Bottle Data.xlsx', sheet_name = 'GPR NPR')
test2 = pd.read_excel('Mass Corr Bottle Data.xlsx', sheet_name = 'met station PAR')

#define columns for each subplot
columns = ['SI',
           'WM',
           'RR']
err = ['SI stdev',
       'WM stdev',
       'RR stdev']
           
#define bar width
width = 0.2

#define subplot names
names = ['Star Island',
         'Wetland Mouth',
         'Railroad']

#set variable outside loop to hold master shared axis
shared_PARax = None

#count number of subplots to adjust visibility of shared axes
total_subplots = len(columns)

#define figure structure
fig, ax = plt.subplots(nrows = 1, ncols = 3, figsize = (12,6), sharey = True)
ax = ax.flatten()

#flatten axes from matrix into 1D array
for i, (col_name, err) in enumerate(zip(columns, err)):
    phyto = test[test['Treatment'] == 'Phytoplankton']
    macro = test[test['Treatment'] == 'Macrophytes']
    epi = test[test['Treatment'] == 'Epiphyton']
    peri = test[test['Treatment'] == 'Periphyton']

    x = np.arange(len(peri))
    
    ax[i].bar(x - (1.5*width), phyto[col_name],
              width, label = 'Phytoplankton',
              color = 'limegreen', hatch = 'o')
    ax[i].bar(x - (0.5*width), macro[col_name],
              width, label = 'Macrophytes',
              color = 'royalblue', hatch = '-')
    ax[i].bar(x + (width*0.5), epi[col_name],
              width, label = 'Epiphyton', color = 'darkblue')
    ax[i].bar(x + (width*1.5), peri[col_name],
              width, label = 'Periphyton',
              color = 'darkorange', hatch = '/')

    ax[i].errorbar(x - (1.5*width), phyto[col_name],
                   fmt = 'none',
                   yerr = phyto[err],
                   ecolor = 'black',
                   capsize = 4)
    ax[i].errorbar(x - (0.5*width), macro[col_name],
                   fmt = 'none',
                   yerr = macro[err],
                   ecolor = 'black',
                   capsize = 4)
    ax[i].errorbar(x + (0.5*width), epi[col_name],
                   fmt = 'none',
                   yerr = epi[err],
                   ecolor = 'black',
                   capsize = 4)
    ax[i].errorbar(x + (1.5*width), peri[col_name],
                   fmt = 'none',
                   yerr = peri[err],
                   ecolor = 'black',
                   capsize = 4)
    
#create master shared axis
    PARax = ax[i].twinx()
    PARax.set_ylim(0, 2500)
    
#establish unit sharing between twin axes
    if shared_PARax is None:
        shared_PARax = PARax
    else:
        PARax.sharey(shared_PARax)

    PARax.plot(x, test2[col_name],
               label = 'PAR', linestyle = '-', color = 'black',
               marker = 's', linewidth = 2)

    ax[i].plot(np.nan, '-k', label = 'PAR (μmol)')

#remove secondary ax tick labels for all plots except far right
    if i != total_subplots - 1:
        PARax.tick_params(axis = 'y', labelright = False, right = False)
    else: PARax.set_ylabel('PAR (μmol)')
    
    ax[i].set_xticks(x)
    ax[i].set_xticklabels(peri['Date'].dt.strftime('%Y-%m-%d'))
    ax[0].set_ylabel('GP/R')

    ax[i].set_title(names[i], fontsize=10, fontweight='bold')

    ax[i].axhline(y=1, linewidth=2, color = 'black')

    ax[i].legend()

#lines, labels = ax.get_legend_handles_labels()
#lines2, labels2 = PARax.get_legend_handles_labels()
#ax[i].legend(lines + lines2, labels + labels2)



plt.suptitle('Ratio of Gross Productivity to Respiration in OWC',
             fontsize = 20,
             fontweight = 'bold')
#plt.subplots_adjust(left = 0.05,
                    #right = 0.95,
                    #wspace = 0.1)

plt.tight_layout()
fig.savefig('Bottles_Final.png')
plt.show()
