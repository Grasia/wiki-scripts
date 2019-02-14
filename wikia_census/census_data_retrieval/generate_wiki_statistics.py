"""
Extract the main stats of the wikis in Wikia requesting the Wikia API (http://www.wikia.com/api/v1)
The requests use the url and the ByString endpoint and it returns a JSON object
with the stats of the wiki. Some URLs in the Wikia Index fail when requesting the API.

After gathering API stats, the JSON objects are flattened (some stats are prefixed with "stats."
because they are inside a "stats" object in the original JSON object) and some
information (like the description, information related with images and top users)
is removed. Additionally, the number of nonarticles is computed using
stats.articles (the number of content pages) and stats.pages (the total number of pages contained in the wiki)

Finally, the stats are stored in a CSV file with the following columns:
- 'date_last_action'
- 'creation_date'
- 'domain'
- 'founding_user_id'
- 'hub'
- 'id'
- 'lang'
- 'name'
- 'stats.activeUsers'
- 'stats.admins'
- 'stats.articles'
- 'stats.discussions'
- 'stats.edits'
- 'stats.images'
- 'stats.pages'
- 'stats.users'
- 'stats.videos'
- 'title'
- 'topic'
- 'url'
- 'wam_score'
- 'stats.nonarticles'
- 'page_views'
"""

import requests
import json
import time
from pandas.io.json import json_normalize
import pandas as pd
from datetime import datetime


wikia_api_endpoint = 'http://www.wikia.com/api/v1/Wikis/ByString?expand=1&limit=25&batch=1&includeDomain=true&string='

mw_api_endpoint = 'api.php?'

def get_wikia_stats(link):
    """Request the stats of a wiki characterized by its url

    Keyword arguments:
    link -- url of the wiki involved in the request

    Return:
    An object with the stats of the wiki or None
    """
    req = requests.get(wikia_api_endpoint+link)
    statusCode = req.status_code
    if statusCode == 200:
        o = json.loads(req.text)
        if (len(o['items'])==1):
            return o['items'][0]
        else:
            return None
    else:
        print (statusCode)
        return None


def get_date_for_last_edit(link):
    req = requests.get(link + mw_api_endpoint + 'action=query&list=recentchanges&format=json')
    statusCode = req.status_code
    if statusCode == 200:
        raw = json.loads(req.text)
        if (not 'recentchanges' in raw['query']):
            return None
        else:
            recent_changes = raw['query']['recentchanges']
        if (len(recent_changes)==0):
            return 'NA'
        else:
            date_last_revision = recent_changes[0]['timestamp']
            return date_last_revision
    else:
        print (statusCode)
        return None


def count_all_page_views(link):
    total_page_views = 0
    url_req = link + mw_api_endpoint + 'action=query&generator=allpages&prop=info&inprop=views&gaplimit=500&format=json'

    req = requests.get(url_req)

    # initial vars for entering loop
    statusCode = req.status_code
    continue_query = True

    while (statusCode == 200 and continue_query):
        raw = json.loads(req.text)
        pages = raw['query']['pages']
        for page in pages.values():
            total_page_views += page['views']

        if 'query-continue' in raw:
            continue_query = True
            # next iteration vars:
            #~ print(raw['query-continue'])
            next_page = raw['query-continue']['allpages']['gapfrom']
            req = requests.get(url_req + '&gapfrom=' + next_page)
            raw = json.loads(req.text)
            statusCode = req.status_code
        else:
            continue_query = False

    if statusCode == 200:
        return total_page_views
    else:
        print (statusCode)
        return None


wikia = []
i=0
output_filename = "wikia_stats"

# Read the wikia index file
with open('../data/20190125-curatedIndex.txt') as f:
    links = [line.strip() for line in f]

# Repeat for every URL (it takes about 1500ms per query, so take it easy)
for link in links:
    data = get_wikia_stats(link)
    if (data is None):
        print ("Error processing link to Wikia API: {} ({})".format(i,link))
        continue

    last_date = get_date_for_last_edit(link)
    if (last_date is None):
        print ("Error processing link to mediawiki API for getting last date: {} ({})".format(i,link))
        continue

    if last_date == 'NA':
        data['date_last_action'] = pd.NaT
    else:
        data['date_last_action'] = datetime.strptime(last_date, '%Y-%m-%dT%H:%M:%SZ')

    page_views = count_all_page_views(link)
    if (page_views is None):
        print ("Error processing link to mediawiki API for getting page views: {} ({})".format(i,link))
        continue

    #~ print(page_views)
    data['page_views'] = page_views


    #~ print(data)
    wikia.append(data)
    i += 1
    #~ if i > 20:
        #~ break;


# Load the stats using json_normalize in order to flatten the objects
df = json_normalize(wikia)

# Remove unnecessary columns
#~ df.drop(columns=['desc','flags', 'image', 'topUsers', 'wordmark'], inplace=True) #TOBECHANGED by the columns we actually want

# Instead above ^, keep wanted columns (more reliable approach)
columns =  ['id', 'url', 'title', 'topic', 'domain', 'founding_user_id',
            'hub', 'lang', 'name',
            'stats.activeUsers', 'stats.admins', 'stats.articles', 'stats.edits',
            'stats.images', 'stats.pages', 'stats.videos',
            'wam_score', 'creation_date',
            'date_last_action', 'page_views']

df = df[columns]

# Compute nonarticles
df['stats.nonarticles'] = df['stats.pages']-df['stats.articles']

# Save to CSV
timestr = time.strftime("%Y%m%d")
df.to_csv('../data/{}-{}.csv'.format(timestr,output_filename), index=False)
