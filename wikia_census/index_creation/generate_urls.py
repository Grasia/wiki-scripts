"""
Extract URLs from Wikia Global sitemap.
The sitemap is a three-level sparse index with the URLs 
of all the hosted wikis, sorted in alphabetical order.

URLs are saved to a TXT file. Each line contains the URL of a Wikia site
"""

from bs4 import BeautifulSoup
import requests
import time

url = "http://www.wikia.com/Sitemap"
baseURL = "http://www.wikia.com"


def createIndex(url, data):
    """Capture recursively the URLs of Wikia Sites.

    Keyword arguments:
    url -- url of the index page processed
    data -- list with the urls extracted up to now
    """

    # Request
    req = requests.get(url)

    # Check Success code (200)
    statusCode = req.status_code

    if statusCode == 200:

        html = BeautifulSoup(req.text,"lxml")

        links = html.select(".sitemap-top-level a")

        # Internal node: Traverse recursively the links contained in this page
        if len(links) > 0:
            for link in links:
                href = link['href']
                if '/Sitemap?level=' in href:
                    createIndex(baseURL+href, data)
        
        # Leaf node: contains the URLs of wikia sites
        else:
            links = html.select("a.title")
            for link in links:
                href = link['href']
                data.append(href)
    else:
        print (statusCode)



# Index creation traversing the sitemap
links = []
createIndex(url, links)


# The index contains duplicated URLs, so the index must be cleaned before saving it.
links = list(set(links))

 
# Save the index on a TXT file.
# Each line contains the URL of a Wikia site
timestr = time.strftime("%Y%m%d")
with open(timestr+'-wikia_index.txt','w') as thefile:
    for item in links:
        thefile.write("%s\n" % item)
