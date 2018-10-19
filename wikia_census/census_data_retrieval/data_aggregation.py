
# coding: utf-8

# In[58]:


import pandas as pd
import numpy as np
import dateparser
import datetime
import time


# # Helper functions

# In[59]:


def remove_trailing_slash(url):
    return url[:-1] if url[-1:] == '/' else url


# # Aggregating stats and users
#
#

# In[60]:


# Load users data
#dfUsers = pd.read_csv("../data/wikia_users.csv", names=['url', 'users_1', 'users_5', 'users_10', 'users_20', 'users_50',
       #' users_100', ' bots'], header=0, skiprows=0)
dfUsers = pd.read_csv("../data/wikia_users.csv", skipinitialspace=True)
dfUsers.drop_duplicates(subset=['url'], inplace=True)
dfUsers.dropna(subset=['url'], inplace=True)
# Remove trailing slash / in case there is at the end of urls
dfUsers['url'] = dfUsers['url'].apply(remove_trailing_slash)
#dfUsers.columns
dfUsers.head()


# In[61]:


# Load stats data
dfStats = pd.read_csv("../data/20180921-wikia_stats.csv")
dfStats.drop_duplicates(subset=['url'], inplace=True)
dfStats.head()


# In[62]:


dfStats.count()


# In[63]:


dfStats[['url', 'id']].head()


# In[64]:


dfIndex = pd.read_csv("../data/20180917-curatedIndex.txt", header=None, names=['url'])
dfIndex.drop_duplicates(inplace=True)

dfIndex.head()


# In[65]:


# Remove trailing slash / in case there is at the end of urls
dfIndex['url'] = dfIndex['url'].apply(remove_trailing_slash)
dfIndex.head()


# In[66]:


# Merge index and stats in order to identify the wikis without stats according to the Wikia API
mergedStatUserData = pd.merge(dfIndex, dfStats[['url', 'id']], how='left', on='url')
mergedStatUserData.head()


# In[67]:


# Merge index, stats and users in order to identify the wikis without stats or without users' information
mergedStatUserData = pd.merge(mergedStatUserData, dfUsers[['url', 'users_1']], how='left', on='url')
mergedStatUserData.head()


# In[68]:


print('Wikia Index size: {}'.format(len(dfIndex)))
print('  Wikis with stats: {}'.format(len(mergedStatUserData[~mergedStatUserData['id'].isna()])))
print('  Wikis with number of users: {}'.format(len(mergedStatUserData[~mergedStatUserData['users_1'].isna()])))
print('  Wikis with stats AND number of users: {}'.format(len(mergedStatUserData[(~mergedStatUserData['id'].isna()) & (~mergedStatUserData['users_1'].isna())])))


# In[69]:


dfStatsUsers = pd.merge(dfIndex, dfStats, how='left', on=['url'])
dfStatsUsers = pd.merge(dfStatsUsers, dfUsers, how='inner', on=['url'])
dfStatsUsers.dropna(subset=['id'], inplace=True)

dfStatsUsers.head()


# In[70]:


# Save to CSV
import time
timestr = time.strftime("%Y%m%d")
dfStatsUsers.to_csv('../data/{}-wikia_stats_users.csv'.format(timestr), index=False)


# # Aggregating birthdate

# In[71]:


# Load birthdate data
dfBirthDate = pd.read_csv("../data/20180919-wikia_birthdate.csv", names = ['url', 'birthDate'], header=0, usecols=['url', 'birthDate'])
dfBirthDate.drop_duplicates(subset=['url'], inplace=True)
# Remove trailing slash / in case there is at the end of urls
dfBirthDate['url'] = dfBirthDate['url'].apply(remove_trailing_slash)

# Create a new column with the birthdate in datetime format
dfBirthDate['datetime.birthDate'] = pd.to_datetime(dfBirthDate['birthDate'], infer_datetime_format=True, errors='coerce')
dfBirthDate.head()


# In[72]:


mergedBirthData = pd.merge(dfIndex, dfBirthDate, how='left', on=['url'])
mergedBirthData.head()


# In[73]:


# Merge index, stats, users and birthdate in order to identify the wikis that lack from any kind of information
mergedStatUserBirthData = pd.merge(dfStatsUsers, dfBirthDate, how='left', on=['url'])
mergedStatUserBirthData.head()


# In[74]:


print('Wikia Index size: {}'.format(len(dfIndex)))
print('  Wikis with birthDate: {}'.format(len(mergedBirthData[~mergedBirthData['birthDate'].isna()])))
print('  Wikis with stats AND users AND birthDate: {}'.format(len(mergedStatUserBirthData[(~mergedStatUserBirthData['id'].isna()) & (~mergedStatUserBirthData['birthDate'].isna())])))
print('  Wikis with birthDate in correct datetime format: {}'.format(len(mergedStatUserBirthData[~mergedStatUserBirthData['datetime.birthDate'].isna()])))


# In[75]:


mergedStatUserBirthData.dropna(subset=['birthDate'], inplace=True)
len(mergedStatUserBirthData)


# ## New parsing of birthdates
#
# Previous stats show that there are around 100k dates in a non valid datetime format. The reason is that the birthdate string is language dependant so some string were not correctly parsed after loading the birthdate data. We will use the [dateparser module](https://dateparser.readthedocs.io/en/v0.3.0/) and the Wiki language in order to parse the non valid birthdates.

# In[56]:


dates = mergedStatUserBirthData[mergedStatUserBirthData['datetime.birthDate'].isna()]['birthDate'].values
languages = mergedStatUserBirthData[mergedStatUserBirthData['datetime.birthDate'].isna()]['lang'].values

i = 0
newDates = {}
for d in dates:
    try:
        newDates[d] = dateparser.parse(d, languages=[languages[i]])
    except Exception:
        newDates[d] = "NONVALID"
    i+=1


# In[57]:


languages


# In[37]:


dates


# In[76]:


nanBirthDates = mergedStatUserBirthData[mergedStatUserBirthData['datetime.birthDate'].isna()].copy()
noNanBirthDates = mergedStatUserBirthData.dropna(subset=['datetime.birthDate'])

# Add new parsed birthdates
nanBirthDates['datetime.birthDate'] = nanBirthDates['birthDate'].map(newDates)

# Remove the birthdates that remain NA
nanBirthDates.dropna(subset=['datetime.birthDate'], inplace=True)

# Remove NONVALID birthdates
nanBirthDates = nanBirthDates[~nanBirthDates['datetime.birthDate'].isin(['NONVALID'])].copy()


# In[81]:


wikiaDataset = pd.concat([noNanBirthDates,nanBirthDates])
print(len(wikiaDataset))


# In[85]:


wikiaDataset[wikiaDataset['url'] == 'http://de.bibel.wikia.com']


# ## Thailand calendar
#
# Change date for Thailand calendar: [On 6 September 1940, Prime Minister Phibunsongkhram decreed 1 January 1941 as the start of the year 2484 BE, so year 2483 BE had only nine months. To convert dates from 1 January to 31 March prior to that year, the number to add or subtract is 542; otherwise, it is 543.](https://en.wikipedia.org/wiki/Thai_solar_calendar)

# In[86]:


def changeCalendar(row):
    if row['lang']=='th':
        date = row['datetime.birthDate']
        thYear = date.year
        return date.replace(year = thYear-543)
    else:
        return row['datetime.birthDate']

wikiaDataset['datetime.birthDate'] = wikiaDataset.apply(changeCalendar, axis=1)


# In[87]:


print('Wikis with stats AND users AND valid birthdates: {}'.format(len(wikiaDataset)))


# In[89]:


# Save to CSV
import time
timestr = time.strftime("%Y%m%d")
wikiaDataset.to_csv('../data/{}-wikia_stats_users_birthdate.csv'.format(timestr), index=False)

