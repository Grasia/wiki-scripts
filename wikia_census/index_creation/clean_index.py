#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
import time


# # Curated Wikia index
# 
# This notebook analyzes the checked URLs in order to:
# 
# - Remove dead wikis
# - Remove redirects
# - Resolve url anomalies

# In[2]:


df = pd.read_csv("../data/20190122-checked_index.csv")
df.head()


# In[3]:


len(df)


# In[4]:


len(df[df['redirect-short']=="NOT AVAILABLE"])


# In[5]:


len(df[df['redirect'].str.startswith('4')]['url'])


# There are some wikis that do not provide a canonical URL so the redirect column contains a 2xx code but the redirect-short column shows a NOT AVAILABLE message. These urls must be resolved manually (no more than 10-15 links)

# In[6]:


df[df['redirect'].str.startswith('2')]['url']


# `redirect-short` column contains information about the actual URL of the links in the Wikia Sitemap. First we will analyse repeated target urls.

# In[15]:


df[df['redirect-short'] == 'NOT AVAILABLE']


# In[7]:


repetitions = df.groupby(by="redirect-short")['url'].count()
repetitions.sort_values(ascending=False)


# There are 8144 urls pointing to Wikia Community wiki (`NOT AVAILABLE`). We will see if it is the same URL studying the content of the `redirect` column.

# In[8]:


pd.set_option('max_colwidth',90)
df[df['redirect-short']=="http://community.wikia.com/"].groupby(by="redirect").count()


# As we can see, additionally to the "NOT AVAILABLE" Wikis, we also have to remove the "dead" wikis, the urls that point to the special Wikia page that informs that the Wiki is not a valid community.
# 
# Additionally, we have checked manually the rest of the wikis pointing to community.wikia and we will update the actual urls.

# In[9]:


df.loc[df['redirect']=="http://community.wikia.com/wiki/Community_Central:Not_a_valid_community",['redirect-short']]="NOT AVAILABLE"

df.loc[df['redirect']=="http://community.wikia.com/wiki/Hub:Lifestyle",['redirect-short']]=df['url']
df.loc[df['redirect']=="http://community.wikia.com/wiki/Special:Chat",['redirect-short']]=df['url']
df.loc[df['redirect']=="http://community.wikia.com/wiki/Special:Forum",['redirect-short']]=df['url']


# In[10]:


repetitions = df.groupby(by="redirect-short")['url'].count()
repetitions.sort_values(ascending=False)


# Finally, we will remove the "NOT AVAILABLE" wikis

# In[11]:


curatedIndex = df[df['redirect-short']!="NOT AVAILABLE"].copy()
len(curatedIndex)


# In[12]:


curatedIndex.drop_duplicates(subset="url", inplace=True)
len(curatedIndex)


# In[13]:


repetitions = curatedIndex.groupby(by="redirect-short")['url'].count()
repetitions.sort_values(ascending=False)


# Finally, we save only the urls in `redirect-short`, removing duplicates

# In[14]:


timestr = time.strftime("%Y%m%d")
thefile = open('../data/{}-{}.txt'.format(timestr,'curatedIndex'), 'w')
for item in curatedIndex['redirect-short'].unique():
    thefile.write("%s\n" % item)

