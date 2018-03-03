from bs4 import BeautifulSoup
import requests

url = "http://www.wikia.com/Sitemap"
baseURL = "http://www.wikia.com"
def createIndex(url, data):
     # Realizamos la petición a la web
    req = requests.get(url)

    # Comprobamos que la petición nos devuelve un Status Code = 200
    statusCode = req.status_code

    if statusCode == 200:

        # Pasamos el contenido HTML de la web a un objeto BeautifulSoup()
        html = BeautifulSoup(req.text,"lxml")

        #print("Procesando "+url)
        links = html.select(".sitemap-top-level a")
        if len(links) > 0:
            for link in links:
                href = link['href']
                if '/Sitemap?level=' in href:
                    createIndex(baseURL+href, data)
        else:
            links = html.select("a.title")
            for link in links:
                href = link['href']
                data.append(href)
    else:
        print (statusCode)

links = []
createIndex(url, links)

import time
timestr = time.strftime("%Y%m%d")
with open(timestr+'-wikiaIndex.txt','w') as thefile:
    for item in links:
        thefile.write("%s\n" % item)
