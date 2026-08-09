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
setwd('C:/Users/brynv/Documents/R/OWC data/7.22.26 Sonde vs Bottle Data/RR/RR3')
minidot <- read.csv('Cat.csv', skip=8, header = TRUE)
View(minidot)

##### Change for each new dataset #####
setwd('C:/Users/brynv/Documents/R/OWC data/7.22')      #set unique folder
path <- 'C:/Users/brynv/Documents/R/OWC data/6.15.26 Historical Data/WM2025'     #set unique folder 
df <- import_local(path, 'owcwmwq')                                              #change df name
df <- qaqc(df, qaqc_keep=c('0', '1', '-1', '4', '5'))
View(df)                                                                         #optional 

##### General workflow (O2) #####

#Code to create numeric change in time column in hours instead of minutes
df_time <- df %>% 
  mutate(datetimeUTC = lubridate::with_tz(datetimestamp, tzone = 'UTC')) %>%
  arrange(datetimeUTC) %>%
  filter(minute(datetimeUTC) == 0) %>%
  mutate(deltaT = (datetimeUTC)-lag(datetimeUTC),    
         delT = as.numeric(deltaT, units='hours'))

#Calculate DO flux
df_DOdiff <- df_time %>%
  arrange(datetimeUTC) %>%
  mutate('fluxDO' = ((do_mgl-lag(do_mgl))/delT))

### Calculate NP ###

df_NP <- df_DOdiff %>%
  filter(hour(datetimeUTC) >= 11 & hour(datetimeUTC) <= 23) %>% 
  #filter(fluxDO > 0) %>%
  group_by(day = date(datetimestamp)) %>%
  summarize(Daily_NP = sum(fluxDO, na.rm=TRUE), .groups = 'drop')  
  
### Calculate HRR ###

#Calculate HRR
df_HRR <- df_DOdiff %>%
  mutate(current_day = date(datetimeUTC),
         interval_start = ymd_hms(paste(current_day, '03:00:00')),
         interval_end = ymd_hms(paste(current_day, '08:00:00')),
         night_window = interval(interval_start, interval_end),
         night = datetimestamp %within% night_window) %>%
  filter(night == TRUE) %>%
  filter(fluxDO < 0) %>%
  mutate(day = date(interval_end)) %>%
  group_by(day) %>%
  summarize(Hourly_RR = (-1) * (((sum(fluxDO, na.rm=TRUE)) / 5)), .groups = 'drop')
  
### Calculate GPP ###

#Combine NP and HRR dataframes
df_combine <- merge(df_NP, df_HRR, by='day')

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
View(df_filter)                                                                  #Optional

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




#Create numeric change in time column (minutes)
df_time <- df %>% 
  mutate(datetimeUTC = lubridate::with_tz(datetimestamp, tzone = 'UTC')) %>%
  arrange(datetimeUTC) %>%
  mutate(deltaT = (datetimeUTC)-lag(datetimeUTC),    
         delT = as.numeric(deltaT, units='mins'))

#Code to create numeric change in time column in hours instead of minutes
df_time <- df %>% 
  mutate(datetimeUTC = lubridate::with_tz(datetimestamp, tzone = 'UTC')) %>%
  arrange(datetimeUTC) %>%
  filter(minute(datetimeUTC) == 0) %>%
  mutate(deltaT = (datetimeUTC)-lag(datetimeUTC),    
         delT = as.numeric(deltaT, units='hours'))
### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ##
##### Same calculations in C units #####
### NP in terms of C ###
NP_C <- df_time %>%
  filter(hour(datetimestamp) >= 6 & hour(datetimestamp) <= 18) %>%    
  group_by(day = date(datetimestamp)) %>%     
  summarize(Daily_NP_C = sum((((lead(do_mgl)-do_mgl) * 375)/(delT * 1.2)), na.rm=TRUE), .groups = 'drop') 

#Calculate DO difference (C)
df_DOdiff <- df_time %>%
  arrange(datetimestamp) %>%
  mutate('fluxC' = ((lead(do_mgl)-do_mgl) * 375) / (delT * 1.2))

#Calculate HRR (C)
HRR_C <- df_DOdiff %>%
  filter(hour(datetimestamp) >= 22 | hour(datetimestamp) <= 3) %>%   
  group_by(day = date(datetimestamp)) %>%
  summarize(Hourly_RR_C = (-1) * (sum(fluxC, na.rm=TRUE) / n()), .groups = 'drop')

### GPP in terms of C ###

#Combine NP and HRR dataframes
df_combine <- merge(NP_C, HRR_C, by='day')

#Calculate GPP
GPP_C <- df_combine %>%
  mutate(Daily_GPP_C = Daily_NP_C + (Hourly_RR_C * 12))

### Respiration Rate in terms of C ###

R_C <- HRR_C %>%
  group_by(day) %>%
  summarize(Daily_R_C = Hourly_RR_C * 24, .groups = 'drop')

#Filter C df
df_combine <- merge(GPP_C, R_C, by='day')

filter_C <- df_combine %>%
  filter_out(Hourly_RR_C < 0 | Daily_NP_C > Daily_GPP_C | Daily_R_C == 0)
View(filter_C)                                                                   #Optional

#Calculate monthly summary statistics (C)
month_C <- filter_C %>%
  group_by(month = month(day, label = TRUE)) %>%
  summarize(NP_mean = mean(Daily_NP_C, na.rm=TRUE),
            NP_stdev = sd(Daily_NP_C, na.rm=TRUE),
            HRR_mean = mean(Hourly_RR_C, na.rm=TRUE),
            HRR_stdev = sd(Hourly_RR_C, na.rm=TRUE),
            R_mean = mean(Daily_R_C, na.rm=TRUE),
            R_stdev = sd(Daily_R_C, na.rm=TRUE),
            GPP_mean = mean(Daily_GPP_C, na.rm=TRUE),
            GPP_stdev = sd(Daily_GPP_C, na.rm=TRUE)) %>%
  mutate(PR_C = (GPP_mean/R_mean))

write.csv(month_C, 'OL2004b Monthly C Averages.csv', row.names=TRUE)              #Add unique site name/year                                                             
#Visualize monthly P/R (C)
PR_C <- month_C %>%
  group_by(month) %>%
  summarize(PR_C)
View(PR_C)                                                                       #Optional

PR_graph_C <- ggplot(data = PR_C, aes(x = month, y = PR_C)) + 
  geom_bar(stat = 'identity') + 
  ylim(0, 2) + 
  labs(x = 'Month',
       y = 'GPP/R (g C/m2/day)',
       title = 'GPP/R in 2025 for site OL')                                      #set unique plot title
PR_graph_C
ggsave('Month C Graph b.png') 

#Calculate yearly summary statistics (C)
year_C <- filter_C %>%
  group_by(year = year(day)) %>%
  summarize(NP_mean = mean(Daily_NP_C, na.rm=TRUE),
            NP_stdev = sd(Daily_NP_C, na.rm=TRUE),
            HRR_mean = mean(Hourly_RR_C, na.rm=TRUE),
            HRR_stdev = sd(Hourly_RR_C, na.rm=TRUE),
            R_mean = mean(Daily_R_C, na.rm=TRUE),
            R_stdev = sd(Daily_R_C, na.rm=TRUE),
            GPP_mean = mean(Daily_GPP_C, na.rm=TRUE),
            GPP_stdev = sd(Daily_GPP_C, na.rm=TRUE)) %>%
  mutate(yearPR = (GPP_mean/R_mean))
View(year_C)                                                                     #Optional

write.csv(year_C, 'OL2004b Yearly C Averages.csv', row.names = FALSE)             #Add unique site name/year

### ### ### ### ### ### ### ### ### ### ### ###

##### Run code for Dr. Dave's Original Data (SU2003) #####
setwd('C:/Users/brynv/Documents/R/OWC data/6.15.26 Historical Data/SU2003')
SU03path <- 'C:/Users/brynv/Documents/R/OWC data/6.15.26 Historical Data/SU2003'
SU2003 <- import_local(SU03path, 'owcsuwq')
SU2003 <- qaqc(SU2003, qaqc_keep=c('0', '1', '-1', '4', '5'))
View(SU2003)

#Create numeric change in time column
SU2003time <- SU2003 %>%    #creates new df from old, %>% specifies changes to old df
  mutate(deltaT = lead(datetimestamp)-datetimestamp,    #creates new column which is delT from dates column
         delT = as.numeric(deltaT, units='mins'))  #changes delT class to numeric (from date)
View(SU2003time)

### Calculate NP ###
SU2003NP <- SU2003time %>%
  filter(hour(datetimestamp) >= 6 & hour(datetimestamp) <= 18) %>%    #selects only entries with times during day range
  group_by(day = date(datetimestamp)) %>%     #groups by day --> reframe should be applied for each day within time range
  summarize(Daily_NP = sum(((lead(do_mgl)-do_mgl)/(delT)), na.rm=TRUE), .groups = 'drop')   #NP calculation (per day) -- na.rm=TRUE must be inside sum function in order for it to handle missing values properly
#multiplied by 1400 --> convert minutes to days (1400 min/day)
View(SU2003NP)

### Calculate HRR ###

#Calculate DO difference
SU2003_DOdiff <- SU2003time %>%
  arrange(datetimestamp) %>%
  mutate('delDO' = (lead(do_mgl)-do_mgl)/delT)
View(SU2003_DOdiff)

#Calculate HRR
SU2003HRR <- SU2003_DOdiff %>%
  filter(hour(datetimestamp) >= 22 | hour(datetimestamp) <= 3) %>%   #use or instead of and --> greater than 22 or less than 3, vs daytime --> greater than 6 and less than 18
  group_by(day = date(datetimestamp)) %>%
  summarize(Hourly_RR = (-1) * (sum(delDO, na.rm=TRUE) / 6), .groups = 'drop')  # time quotient is hardcoded as 6 because R includes delDO values from the hour of 0300, since the hour term in datetimestamp is equal to 3, so the time range is six hours (vs 5 in excel)
View(SU2003HRR)

### Calculate GPP ###

#Combine NP and HRR dataframes
SU2003GPP <- merge(SU2003NP, SU2003HRR, by='day')
View(SU2003GPP)

#Calculate GPP
SU2003GPPcalc <- SU2003GPP %>%
  mutate(Daily_GPP = Daily_NP + (Hourly_RR*12))
View(SU2003GPPcalc)

### Calculate Respiration Rate ###
SU2003R <- SU2003HRR %>%
  group_by(day) %>%
  summarize(Daily_R = Hourly_RR * 24, .groups = 'drop')
View(SU2003R)

### Calculate P/R ###
SU2003GPPR <- merge(SU2003R, SU2003GPPcalc, by='day')
SU2003GPPRcalc <- SU2003GPPR %>%
  mutate(PR = Daily_GPP/Daily_R)
View(SU2003GPPRcalc)

#Filter for relevant dates and acceptable values
SU2003filter <- SU2003GPPRcalc %>%
  filter_out(Hourly_RR < 0 | Daily_NP > Daily_GPP | Daily_R == 0)
View(SU2003filter)

#Calculate monthly summary statistics
SU2003month <- SU2003filter %>%
  group_by(month = month(day, label = TRUE)) %>%
  summarize(NP_month_mean = mean(Daily_NP, na.rm=TRUE),
            NP_month_sd = sd(Daily_NP, na.rm=TRUE),
            HRR_month_mean = mean(Hourly_RR, na.rm=TRUE),
            HRR_month_sd = sd(Hourly_RR, na.rm=TRUE),
            R_month_mean = mean(Daily_R, na.rm=TRUE),
            R_month_sd = sd(Daily_R, na.rm=TRUE),
            GPP_month_mean = mean(Daily_GPP, na.rm=TRUE),
            GPP_month_sd = sd(Daily_GPP, na.rm=TRUE),
            PR_month_mean = mean(PR, na.rm=TRUE),
            PR_month_sd = sd(PR, na.rm=TRUE)) %>%
  mutate(monthPR = (GPP_month_mean/R_month_mean))
View(SU2003month)

write.csv(SU2003month, 'Monthly Averages.csv', row.names=FALSE)

#Visualize monthly trends
funhistograms <- SU2003month %>%
  group_by(month) %>%
  summarize(monthPR)
View(funhistograms)

SU2003PR <- ggplot(data = funhistograms, aes(x = month, y = monthPR)) + 
  geom_bar(stat = 'identity') + 
  ylim(0, 2) + 
  labs(x = 'Month',
       y = 'GPP/R (mg/L/day',
       title = 'GPP/R in 2003 for site SU')
SU2003PR
ggsave('funhistograms.png')

#Calculate yearly summary statistics
SU2003year <- SU2003filter %>%
  group_by(year = year(day)) %>%
  summarize(NP_year_mean = mean(Daily_NP, na.rm=TRUE),
            NP_year_sd = sd(Daily_NP, na.rm=TRUE),
            R_year_mean = mean(Hourly_RR, na.rm=TRUE),
            R_year_sd = sd(Hourly_RR, na.rm=TRUE),
            GPP_year_mean = mean(Daily_GPP, na.rm=TRUE),
            GPP_year_sd = sd(Daily_GPP, na.rm=TRUE),
            PR_year_mean = mean(PR, na.rm=TRUE),
            PR_year_sd = sd(PR, na.rm=TRUE)) %>%
  mutate(yearPR = (GPP_year_mean/R_year_mean))
View(SU2003year)

write.csv(SU2003year, 'Yearly Averages.csv', row.names = FALSE)



##### Extrey #####

#NP monthly average 
BR19monthNP <- BR2019NP %>%
  group_by(month = month(day, label=TRUE)) %>%   #groups by month
  reframe(NP_month_avg = mean(Daily_NP, na.rm=TRUE),    #returns monthly average and stdev of daily NP
          NP_month_sd = sd(Daily_NP, na.rm=TRUE))
View(BR19monthNP)

#NP yearly average 
BR19yearNP <- BR2019NP %>%
  reframe(NP_year_avg = mean(Daily_NP, na.rm=TRUE),
          NP_year_sd = sd(Daily_NP, na.rm=TRUE))
View(BR19yearNP)

#HRR monthly average
BR2019monthHRR <- BR2019HRR %>%
  group_by(month = month(day, label=TRUE)) %>%
  reframe(HRR_month_avg = mean(Hourly_RR, na.rm=TRUE),
          HRR_month_sd = sd(Hourly_RR, na.rm=TRUE))
View(BR2019monthHRR)

#HRR yearly average
BR2019yearHRR <- BR2019HRR %>%
  reframe(HRR_year_avg = mean(Hourly_RR, na.rm=TRUE),
          HRR_year_sd = sd(Hourly_RR), na.rm=TRUE)
View(BR2019yearHRR)

ggplot2(BR2019, 
       aes(x=DateTimeStamp, y=(DO_mgl))) + 
  geom_point() + 
  scale_y_datetime(breaks)

#GPP monthly average
BR2019monthGPP <- BR2019GPPcalc %>%
  group_by(month = month(day, label=TRUE)) %>%
  summarize(GPP_month_avg = mean(Daily_GPP, na.rm=TRUE),
            GPP_month_sd = sd(Daily_GPP, na.rm=TRUE))
View(BR2019monthGPP)

#GPP yearly average
BR2019yearGPP <- BR2019GPPcalc %>%
  summarize(GPP_year_avg = mean(Daily_GPP, na.rm=TRUE),
            GPP_year_sd = sd(Daily_GPP, na.rm=TRUE))
View(BR2019yearGPP)





#Import data using SWMPr (BR2019)
path1 <- 'C:/Users/brynv/Documents/R/OWC data/6.15.26 Historical Data/BR2019'
BR2019 <- import_local(path1, 'owcbrwq')
BR2019 <- subset(qaqc(BR2019), rem_cols=TRUE)


mutate(Day = ifelse(time >= 6:00 | time <= 18:00, yes='Day', no='not_day')) %>%
  mutate(Night = ifelse(time >= 22:00 | time <= 3:00, yes='Night', no='not_night')) %>%
  group_by(date) %>%
  filter(day == 'day') %>%
  
#Import data (BR2019) (old)
BR2019 <- read.csv('BR2019.csv', skip=2, header = TRUE)
View(BR2019)

#Format date column as dates
BR2019dates <- BR2019 %>%
  mutate(DTS = as_datetime(DateTimeStamp, format='%m/%d/%Y %H:%M'))
View(BR2019dates)

#Create numeric minutes column
BR2019dates2 <- BR2019dates %>%    #creates new df from old, %>% specifies changes to old df
  mutate(deltat = lead(DTS)-DTS,    #creates new column which is delT from dates column
         delMin = as.numeric(deltat, units='mins'))  #changes delT class to numeric (from date)
View(BR2019dates2)

#Calculate NP
BR2019NP <- BR2019dates2 %>%
  filter(hour(DTS) > 6 & hour(DTS) < 18) %>%    #selects only entries with times during day range
  group_by(day = date(DTS)) %>%     #groups by day --> reframe should be applied for each day within time range
  reframe(Daily_NP = sum(((lead(DO_mgl)-DO_mgl)/(delMin))*Depth, na.rm=TRUE))   #NP calculation (per day) -- na.rm=TRUE must be inside sum function in order for it to handle missing values properly
View(BR2019NP)

#NP monthly average
BR19monthNP <- BR2019NP %>%
  group_by(month = month(day, label=TRUE)) %>%   #groups by month
  reframe(NP_month_avg = mean(Daily_NP, na.rm=TRUE),    #returns monthly average and stdev of daily NP
          NP_month_sd = sd(Daily_NP, na.rm=TRUE))
View(BR19monthNP)

#NP yearly average
BR19yearNP <- BR2019NP %>%
  reframe(NP_year_avg = mean(Daily_NP, na.rm=TRUE),
          NP_year_sd = sd(Daily_NP, na.rm=TRUE))
View(BR19yearNP)

#Import data (SWMPr)
BR19path <- 'C:/Users/brynv/Documents/R/OWC data/6.15.26 Historical Data/BR2019'
BR2019 <- import_local(BR19path, 'owcbrwq')
BR2019 <- qaqc(BR2019, qaqc_keep=c('0', '1', '-1', '4', '5'))
View(BR2019)

#Create numeric minutes column 
BR2019days <- BR2019 %>%    #creates new df from old, %>% specifies changes to old df
  mutate(deltat = lead(datetimestamp)-datetimestamp,    #creates new column which is delT from dates column
         delDay = as.numeric(deltat, units='days'))  #changes delT class to numeric (from date)
View(BR2019days)

### Calculate NP ###
BR2019NP <- BR2019days %>%
  filter(hour(datetimestamp) >= 6 & hour(datetimestamp) <= 18) %>%    #selects only entries with times during day range
  group_by(day = date(datetimestamp)) %>%     #groups by day --> reframe should be applied for each day within time range
  reframe(Daily_NP = sum(((lead(do_mgl)-do_mgl)/(delDay))*depth, na.rm=TRUE))   #NP calculation (per day) -- na.rm=TRUE must be inside sum function in order for it to handle missing values properly
#multiplied by 1400 --> convert minutes to days (1400 min/day)
View(BR2019NP)

### Calculate the values inside the summation without summing ###
BR2019test <- BR2019days %>%
  filter(hour(datetimestamp) >= 6 & hour(datetimestamp) <= 18) %>%  
  mutate(Daily_NP = ((lead(do_mgl)-do_mgl)/(delDay))*depth, na.rm=TRUE)  
View(BR2019test)

### Calculate NP for one day ###
BR2019day <- BR2019days %>%
  filter(hour(datetimestamp) >= 6 & hour(datetimestamp) <= 18) %>%
  filter(day(datetimestamp) == 26 & month(datetimestamp) == 3) %>%
  reframe(Daily_NP = sum(((lead(do_mgl)-do_mgl)/(delDay))*depth, na.rm=TRUE))
View(BR2019day)

BR2019day1 <- BR2019days %>%
  filter(hour(datetimestamp) > 6 & hour(datetimestamp) < 18) %>%
  filter(day(datetimestamp) == 26 & month(datetimestamp) == 3)
View(BR2019day1)


### Calculate HRR ###
#Create numeric hours column 
BR2019hours <- BR2019 %>%    
  mutate(deltam = lead(datetimestamp)-datetimestamp,    #creates new column which is delT from dates column
         delHr = as.numeric(deltam, units='mins'))  #changes delT class to numeric (from date)
View(BR2019hours)

#Calculate HRR
BR2019HRR <- BR2019hours %>%
  filter(hour(datetimestamp) >= 22 | hour(datetimestamp) <= 3) %>%  #use or instead of and --> greater than 22 or less than 3, vs daytime --> greater than 6 and less than 18
  group_by(day = date(datetimestamp)) %>%
  summarize(Hourly_RR = (-1)*sum(((lead(do_mgl)-do_mgl)/delHr), na.rm=TRUE)/5)
View(BR2019HRR)

### Calculate GPP ###
#Combine NP and HRR dataframes
BR2019GPP <- merge(BR2019NP, BR2019HRR, by='day')
View(BR2019GPP)

#Calculate GPP
BR2019GPPcalc <- BR2019GPP %>%
  group_by(day = date(day)) %>%
  summarize(Daily_GPP = Daily_NP + (Hourly_RR*12))
View(BR2019GPPcalc)

### Calculate Respiration Rate ###
BR2019R <- BR2019HRR %>%
  group_by(day = date(day)) %>%
  summarize(R = Hourly_RR * 24)
View(BR2019R)

### Calculate P/R ###
BR2019GPPR <- merge(BR2019R, BR2019GPPcalc, by='day')
BR2019GPPRcalc <- BR2019GPPR %>%
  group_by(day = date(day)) %>%
  summarize(PR = Daily_GPP/R)
View(BR2019GPPRcalc)

### Combine rates for QAQC (check keep/discard criteria)
BR2019sum1 <- merge(BR2019NP, BR2019HRR, by='day')
BR2019sum2 <- merge(BR2019sum1, BR2019GPPcalc, by='day')
BR2019sum3 <- merge(BR2019sum2, BR2019R, by='day')
BR2019sum4 <- merge(BR2019sum3, BR2019GPPRcalc, by='day')
View(BR2019sum4)

#Filter for relevant dates and acceptable values
BR2019filter <- BR2019sum4 %>%
  filter(day > '2019-03-25' & day < '2019-12-11') %>%
  filter_out(Hourly_RR < 0 | Daily_NP > Daily_GPP)
View(BR2019filter)

#Calculate monthly summary statistics
BR2019month <- BR2019filter %>%
  group_by(month = month(day, label = TRUE)) %>%
  summarize(NP_month_mean = mean(Daily_NP, na.rm=TRUE),
            NP_month_sd = sd(Daily_NP, na.rm=TRUE),
            R_month_mean = mean(R, na.rm=TRUE),
            R_month_sd = sd(R, na.rm=TRUE),
            GPP_month_mean = mean(Daily_GPP, na.rm=TRUE),
            GPP_month_sd = sd(Daily_GPP, na.rm=TRUE),
            PR_month_mean = mean(PR, na.rm=TRUE),
            PR_month_sd = sd(PR, na.rm=TRUE))
View(BR2019month)

#Calculate yearly summary statistics
BR2019year <- BR2019filter %>%
  summarize(NP_year_mean = mean(Daily_NP, na.rm=TRUE),
            NP_year_sd = sd(Daily_NP, na.rm=TRUE),
            R_year_mean = mean(R, na.rm=TRUE),
            R_year_sd = sd(R, na.rm=TRUE),
            GPP_year_mean = mean(Daily_GPP, na.rm=TRUE),
            GPP_year_sd = sd(Daily_GPP, na.rm=TRUE),
            PR_year_mean = mean(PR, na.rm=TRUE),
            PR_year_sd = sd(PR, na.rm=TRUE))
View(BR2019year)

#Import Cornell+Klarer data
PaperData <- read.csv('C:/Users.brynv/Documents/R/OWC data/6.15.26 Historical Data.csv')
