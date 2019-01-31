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
- 'creation_date'
- 'domain'
- 'founding_user_id'
- 'headline'
- 'hub'
- 'id'
- 'lang'
- 'language'
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
"""

import requests
import json
import time
from pandas.io.json import json_normalize

url = 'http://www.wikia.com/api/v1/Wikis/ByString?expand=1&limit=25&batch=1&includeDomain=true&string='

def requestStats(link):
    """Request the stats of a wiki characterized by its url

    Keyword arguments:
    link -- url of the wiki involved in the request

    Return:
    An object with the stats of the wiki or None
    """
    req = requests.get(url+link)
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


wikia = []
i=0
output_filename = "wikia_stats"

# Read the wikia index file
with open('../data/20190125-curatedIndex.txt') as f:
    links = [line.strip() for line in f]

# Repeat for every URL (it takes about 1500ms per query, so take it easy)
for link in links:
    data = requestStats(link)
    if (data is None):
        print ("Error processing link: {} ({})".format(i,link))
    else:
        #~ print(data)
        wikia.append(data)
        i+=1


# Load the stats using json_normalize in order to flatten the objects
df = json_normalize(wikia)

# Remove unnecessary columns
df.drop(columns=['desc','flags', 'image', 'original_dimensions.height','original_dimensions.width', 'topUsers', 'wordmark'], inplace=True) #TOBECHANGED by the columns we actually want

# Compute nonarticles
df['stats.nonarticles'] = df['stats.pages']-df['stats.articles']

# Save to CSV
timestr = time.strftime("%Y%m%d")
df.to_csv('../data/{}-{}.csv'.format(timestr,output_filename), index=False)
