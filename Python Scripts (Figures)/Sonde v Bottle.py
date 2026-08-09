#Sonde vs Bottle
#Started 7/22/26 BVF

#load required packages
import os
import openpyxl as op
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

#set wd
os.chdir("C:\\Users\\brynv\\Documents\\Python\\OWC\\Sonde vs Bottle Figure")
os.getcwd()

#import file
#df = pd.read_excel('pySummer Sonde.xlsx', sheet_name = 'GPP')
df = pd.read_excel('pySummer Sonde.xlsx', sheet_name = 'GPP 300')

#name series and subplots
series = ['Daily_GPP', 'Phyto', 'Macro','Epi', 'Peri']

SI = df[df['site'] == 'SI']
WM = df[df['site'] == 'WM']
RR = df[df['site'] == 'RR']

SIdate = ['06-05-26', '06-29-26', '07-16-26']
WMdate = ['06-08-26', '06-26-26', '07-17-26']
RRdate = ['06-09-26', '06-30-26', '07-20-26']

x1 = np.arange(len(SI))
x2 = np.arange(len(WM))
x3 = np.arange(len(RR))
width = 0.15

#define figure structure
fig, ax = plt.subplots(sharey = True)

ax1 = fig.add_subplot(2,2,1)
ax2 = fig.add_subplot(2,2,2)
ax3 = fig.add_subplot(2,2,3)

#Wetland Mouth
ax1.bar(x2 - (2*width), WM['Daily_GPP'], width, label = 'Sonde', color = 'black')
ax1.bar(x2 - (width), WM['Phyto'], width, label = 'Phytoplankton',
        color = 'limegreen', hatch = 'o')
ax1.bar(x2, WM['Macro'], width, label = 'Macrophytes',
        color = 'royalblue', hatch = '-')
ax1.bar(x2 + (width), WM['Epi'], width, label = 'Epiphyton',
        color = 'darkblue')
ax1.bar(x2 + (2*width), WM['Peri'], width, label = 'Periphyton',
        color = 'darkorange', hatch = '/')

ax1.set_xticks(x2)
ax1.set_xticklabels(WMdate)
ax1.set_ylim(0, 15)
#ax1.legend()
ax1.set_title('Wetland Mouth', fontsize = 10)
ax1.set_ylabel('[O2] (mg/L)')

#Star Island
ax2.bar(x1 - (2*width), SI['Daily_GPP'], width, label = 'Sonde', color = 'black')
ax2.bar(x1 - width, SI['Phyto'], width, label = 'Phytoplankton',
        color = 'limegreen', hatch = 'o')
ax2.bar(x1, SI['Macro'], width, label = 'Macrophytes',
        color = 'royalblue', hatch = '-')
ax2.bar(x1 + width, SI['Epi'], width, label = 'Epiphyton',
        color = 'darkblue')
ax2.bar(x1 + (2*width), SI['Peri'], width, label = 'Periphyton',
        color = 'darkorange', hatch = '/')

ax2.set_xticks(x1)
ax2.set_xticklabels(SIdate)
ax2.set_ylim(0,15)
#ax2.legend()
ax2.set_title('Star Island', fontsize = 10)
ax2.set_ylabel('[O2] (mg/L)')

#Railroad
ax3.bar(x3 - (2*width), RR['Daily_GPP'], width, label = 'Sonde', color = 'black')
ax3.bar(x3 - width, RR['Phyto'], width, label = 'Phytoplankton',
        color = 'limegreen', hatch = 'o')
ax3.bar(x3, RR['Macro'], width, label = 'Macrophytes',
        color = 'royalblue', hatch = '-')
ax3.bar(x3 + width, RR['Epi'], width, label = 'Epiphyton',
        color = 'darkblue')
ax3.bar(x3 + (2*width), RR['Peri'], width, label = 'Periphyton',
        color = 'darkorange', hatch = '/')

ax3.set_xticks(x3)
ax3.set_xticklabels(RRdate)
ax3.set_ylim(0, 15)
#ax3.legend()
ax3.set_title('Railroad', fontsize = 10)
ax3.set_ylabel('[O2] (mg/L)')

ax.axis('off')
#ax3.legend(loc = 'center left', bbox_to_anchor = (1, 0.5))
fig.suptitle('Overall GP vs Individual GP', fontsize = 14, weight = 'bold')

plt.tight_layout()
fig.savefig('Sonde v Bottle Daily300.png')
plt.show()

    

