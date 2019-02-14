"""
Extract URLs from Wikia Global sitemap.
The sitemap is a three-level sparse index with the URLs
of all the hosted wikis, sorted in alphabetical order.

URLs are saved to a TXT file. Each line contains the URL of a Wikia site
"""

from bs4 import BeautifulSoup
import requests
import time

url = "https://community.wikia.com/wiki/Sitemap"
baseURL = "http://www.wikia.com"


def createIndex(url, data):
    """Capture recursively the URLs of Wikia Sites.

    Keyword arguments:
    url -- url of the index page processed
    data -- list with the urls extracted up to now
    """

    def remove_trailing_slash(url):
        return url[:-1] if url[-1:] == '/' else url

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
                href = remove_trailing_slash(href)
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
