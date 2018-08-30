"""
Remove duplicates, redirects and dead wikis.
For every link in the file extracted from the Sitemap, we check if it points to a valid wiki.
Additionally, we retrieve the canonical url of the actual target, in order to find redirects,
i.e. different urls in the sitemap that link to the same Wiki.
"""
from bs4 import BeautifulSoup
import requests
import time
import pandas as pd


with open('../data/20180220-wikiaIndex.txt') as f:
    links = [line.strip() for line in f]

i=0
max = len(links)
output_filename = "checked_index"

# Loop with i instead of iterator in order to retry the execution 
# if network fails
while i<max:
    url = links[i]
    i+=1
    try:
        req = requests.get(url)
        statusCode = req.status_code

        # Check if request was ok
        if statusCode == 200:
            html = BeautifulSoup(req.text,"lxml")
            canonical =html.select('link[rel=canonical]')
            if len(canonical)>0:
                canonical = canonical[0]['href']
                pos = canonical.find('wikia.com/')
                # Save the canonical url and its short version
                newURLs.append([url,canonical,canonical[:pos+10]])
            else:
                # Canonical url was not available. This fact only occurs with
                # 10-15 wikis so later will be resolved by a human.
                newURLs.append([url, req.status_code, "NOT AVAILABLE"])
        else:
            # Save the link with its status 
            newURLs.append([url, req.status_code, "NOT AVAILABLE"])
    except Exception:
        newURLs.append([url, "REQUEST ERROR", "NOT AVAILABLE"])
    
    # Dump to file every 5000 urls    
    if (i%5000) == 0:
        print("Dump i={}".format(i))
        df = pd.DataFrame(newURLs)
        df.columns=['url','redirect','redirect-short']
        df.to_csv('{}-{}.csv'.format(output_filename,i), index=False)

print("Dump i={}".format(i))

# Save to a CSV file
df = pd.DataFrame(newURLs)
df.columns=['url','redirect','redirect-short']
timestr = time.strftime("%Y%m%d")
df.to_csv('../data/{}-{}.csv'.format(timestr,output_filename), index=False)
