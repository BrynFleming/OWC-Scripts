#Processing historical Sonde DO and Temp data
#Started 6.15.26 BVF
#Most recent iteration 7.22.26 BVF

#Set working directory
setwd('C:/Users/brynv/Documents/R/OWC data/6.15.26 Historical Data/Dr Dave Data')

#Import packages
library(dplyr)
library(SWMPr)
library(tidyverse)
library(scales)
library(lubridate)

#Import data
setwd('C:/Users/brynv/Documents/R/OWC data/7.22.26 Sonde vs Bottle Data/SI miniDOT')
minidot <- read.csv('Cat.csv', skip=8, header = TRUE)
View(minidot)

setwd('C:/Users/brynv/Documents/R/OWC data/7.22.26 Sonde vs Bottle Data/WM')
WMraw <- read.csv('WM070726_RAW.csv', skip=8, header = TRUE)
View(WMraw)

##### Change for each new dataset #####
setwd('C:/Users/brynv/Documents/R/OWC data/7.22.26 Sonde vs Bottle Data/RR/RR3')      #set unique folder
path <- 'C:/Users/brynv/Documents/R/OWC data/7.22.26 Sonde vs Bottle Data/RR/RR3'     #set unique folder 
df <- import_local(path, 'owcrrwq')                                              #change df name
df <- qaqc(df, qaqc_keep=c('0', '1', '-1', '4', '5'))
View(df)                                                                         #optional 

##### General workflow (O2) #####

#SONDE Code to create numeric change in time column in hours instead of minutes (Sonde)
df_time <- df %>% 
  mutate(datetimeUTC = lubridate::with_tz(datetimestamp, tzone = 'UTC')) %>%
  arrange(datetimeUTC) %>% 
  mutate(day1 = ymd_hms('2026-07-20 13:15:00'),
         day2 = ymd_hms('2026-07-21 09:00:00'),
         date_window = interval(day1, day2),
         RR1 = datetimeUTC %within% date_window) %>% 
  filter(RR1 == TRUE) %>%
  filter(minute(datetimeUTC) == 0) %>%
  mutate(deltaT = (datetimeUTC)-lag(datetimeUTC),    
         delT = as.numeric(deltaT, units='hours'))

#MINIDOT Create numeric delT column for miniDOT
df_time <- minidot %>%
  mutate(datetimeUTC = as.POSIXct(datetimeUTC, format = '%Y-%m-%d %H:%M:%S', tz = 'utc')) %>%
  mutate(day1 = ymd_hms('2026-07-16 04:01:00'),
         day2 = ymd_hms('2026-07-18 04:01:00'),
         date_window = interval(day1, day2),
         SI1 = datetimeUTC %within% date_window) %>% 
  filter(SI1 == TRUE) %>%
  #mutate(day = date(day1)) %>%
  #group_by(day) %>%
  arrange(datetimeUTC) %>%
  filter(minute(datetimeUTC) == 01) %>%
  mutate(deltaT = (datetimeUTC)-lag(datetimeUTC),    
         delT = as.numeric(deltaT, units='hours'))

#WMRAW Create numeric delT column for miniDOT
df_time <- WMraw %>%
  mutate(datetimeUTC = as.POSIXct(paste(WMraw$date, WMraw$time), format = '%m/%d/%Y %H:%M:%S', tz = 'utc')) %>%
  mutate(day1 = ymd_hms('2026-07-17 05:00:00'),
         day2 = ymd_hms('2026-07-19 05:00:00'),
         date_window = interval(day1, day2),
         WM1 = datetimeUTC %within% date_window) %>% 
  filter(WM1 == TRUE) %>%
  arrange(datetimeUTC) %>%
  filter(minute(datetimeUTC) == 00) %>%
  mutate(deltaT = (datetimeUTC)-lag(datetimeUTC),    
         delT = as.numeric(deltaT, units='hours'))


#Calculate DO flux
df_DOdiff <- df_time %>%
  arrange(datetimeUTC) %>%
  mutate('fluxDO' = ((do_mgl-lag(do_mgl))/delT))

write.csv(df_DOdiff, 'DOdiff.csv', row.names = TRUE)

### Calculate NP ###

df_NP <- df_DOdiff %>%
  filter(hour(datetimeUTC) >= 11 & hour(datetimeUTC) <= 23) %>% 
  #filter(fluxDO > 0) %>%
  group_by(day = date(datetimeUTC)) %>%
  summarize(Daily_NP = sum(fluxDO, na.rm=TRUE)/9, .groups = 'drop')  

### Calculate HRR ###

#Calculate HRR
df_HRR <- df_DOdiff %>%
  mutate(current_day = date(datetimeUTC),
         interval_start = ymd_hms(paste(current_day, '03:00:00')),
         interval_end = ymd_hms(paste(current_day, '08:00:00')),
         night_window = interval(interval_start, interval_end),
         night = datetimeUTC %within% night_window) %>%
  filter(night == TRUE) 
  filter(fluxDO < 0) %>%
  mutate(day = date(interval_end)) %>%
  group_by(day) %>%
  summarize(Hourly_RR = (-1) * (((sum(fluxDO, na.rm=TRUE)) / 5)), .groups = 'drop')

### Calculate GPP ###

#Combine NP and HRR dataframes
df_combine <- merge(df_NP, df_HRR, by='day')

write.csv(df_combine, 'RR3.csv')





#Calculate GPP
df_GPP <- df_combine %>%
  mutate(Daily_GPP = Daily_NP + (Hourly_RR*12))

### Calculate Respiration Rate ###

df_R <- df_HRR %>%
  group_by(day) %>%
  summarize(Daily_R = (Hourly_RR*24), .groups = 'drop')

#Filter for relevant dates and acceptable values
df_combine2 <- merge(df_GPP, df_R, by='day')

df_filter <- df_combine2 %>%
  filter(Hourly_RR > 0 & Daily_NP <= Daily_GPP)
View(df_filter) 

write.csv(df_filter, 'WM1.csv', row.names = TRUE)



#Calculate monthly summary statistics (O2)
df_month <- df_filter %>%
  group_by(month = month(day, label = TRUE)) %>%
  summarize(NP_mean = mean(Daily_NP, na.rm=TRUE),
            NP_stdev = sd(Daily_NP, na.rm=TRUE),
            HRR_mean = mean(Hourly_RR, na.rm=TRUE),
            HRR_stdev = sd(Hourly_RR, na.rm=TRUE),
            R_mean = mean(Daily_R, na.rm=TRUE),
            R_stdev = sd(Daily_R, na.rm=TRUE),
            GPP_mean = mean(Daily_GPP, na.rm=TRUE),
            GPP_stdev = sd(Daily_GPP, na.rm=TRUE)) %>%
  mutate(PR = (GPP_mean/R_mean))

write.csv(df_month, 'WM2025 Monthly Averages.csv', row.names=TRUE)               #Add unique site name/year

#Visualize monthly P/R (O2)

PR_graph <- ggplot(data = df_month, aes(x = month, y = PR)) + 
  geom_bar(stat = 'identity') + 
  ylim(0, 2) + 
  labs(x = 'Month',
       y = 'GPP/R (g O2/m3/day)',
       title = 'PR WM2025')                                      #set unique plot title
PR_graph
ggsave('PR WM2025.png') 

GP_graph <- ggplot(data = df_month, aes(x = month, y = GPP_mean)) + 
  geom_point(stat = 'identity') +
  ylim(0, 16) + 
  labs(x = 'Month',
       y = 'GPP (g/m3/day)',
       title = 'GP WM2025')
GP_graph
ggsave('GP WM2025.png')

#Calculate yearly summary statistics (O2)
df_year <- df_filter %>%
  group_by(year = year(day)) %>%
  summarize(NP_mean = mean(Daily_NP, na.rm=TRUE),
            NP_stdev = sd(Daily_NP, na.rm=TRUE),
            HRR_mean = mean(Hourly_RR, na.rm=TRUE),
            HRR_stdev = sd(Hourly_RR, na.rm=TRUE),
            R_mean = mean(Daily_R, na.rm=TRUE),
            R_stdev = sd(Daily_R, na.rm=TRUE),
            GPP_mean = mean(Daily_GPP, na.rm=TRUE),
            GPP_stdev = sd(Daily_GPP, na.rm=TRUE)) %>%
  mutate(yearPR = (GPP_mean/R_mean))
View(df_year)                                                                    #Optional

write.csv(df_year, 'WM2025 Yearly Averages.csv', row.names = FALSE)              #Add unique site name/year