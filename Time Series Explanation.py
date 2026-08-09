#Plotting one day to illustrate why we sum over an hour
#Started 7/15/2026 BVF

#load packages
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse
from matplotlib.text import OffsetFrom
import matplotlib.dates as mdates

#set wd
os.chdir("C:\\Users\\brynv\\Documents\\Python\\OWC\\Time Series Figure")
os.getcwd()

#import data
df_hour = pd.read_excel('df_hour.xlsx')
df_minute = pd.read_excel('df_minute.xlsx')

df_hour['Time'] = pd.to_datetime(df_hour['datetimestamp'],
                                          format = '%H:%M', errors = 'coerce')
df_minute['Time'] = pd.to_datetime(df_minute['datetimestamp'],
                                            format = '%H:%M', errors = 'coerce')
                                            
#define figure
fig, ax = plt.subplots(2, 1, sharey = True)
ax = ax.flatten()

ax[0].plot(df_minute['Time'], df_minute['do_mgl'],
        label = '15 minutes', color = 'royalblue')
ax[0].xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
ax[0].set_title('Interval = 15 minutes', fontsize = 10, color = 'royalblue')

ax[0].axvspan(xmin = '2025-07-15 06:00:00',
              xmax = '2025-07-15 18:00:00',
              color = 'darkorange', alpha = 0.2)
ax[0].axvspan(xmin = '2025-07-15 22:00:00',
              xmax = '2025-07-16 03:00:00',
              color = 'darkblue', alpha = 0.2)

ax[1].plot(df_hour['Time'], df_hour['do_mgl'],
        label = '1 hour', color = 'limegreen')
ax[1].xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
ax[1].set_title('Interval = 1 hour', fontsize = 10, color = 'limegreen')

ax[1].axvspan(xmin = '2025-07-15 06:00:00',
              xmax = '2025-07-15 18:00:00',
              color = 'darkorange', alpha = 0.2)
ax[1].axvspan(xmin = '2025-07-15 22:00:00',
              xmax = '2025-07-16 03:00:00',
              color = 'darkblue', alpha = 0.2)

fig.supylabel('[O2](mg/L)', fontsize = 8)

plt.suptitle('Effects of integrating over different time intervals',
             weight = 'bold', fontsize = 14)

plt.tight_layout()
fig.savefig('Timeseries.png')
plt.show()


