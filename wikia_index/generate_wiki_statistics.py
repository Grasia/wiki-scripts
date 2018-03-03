from bs4 import BeautifulSoup
import requests

sample_url = "http://clashofclans.wikia.com/wiki/Special:Statistics"

rowSelector = "tr.mw-statistics-"
stats = ["articles",'pages','files','edits','edits-average','users','users-active']
groupStats = ['bot', 'sysop']
wikiaIndex = '20180220-wikiaIndex.txt'

with open(wikiaIndex) as f:
    links = [line.strip() for line in f]

def procesaURL(url, data):
     # Realizamos la petición a la web
    req = requests.get(url)

    # Comprobamos que la petición nos devuelve un Status Code = 200
    statusCode = req.status_code
    if statusCode == 200:

        # Pasamos el contenido HTML de la web a un objeto BeautifulSoup()
        html = BeautifulSoup(req.text,"lxml")
        name = html.select_one('div.wds-community-header__sitename a').text

        result = [name,url]
        for stat in stats:
            row = html.select_one(rowSelector+stat+" td.mw-statistics-numbers")
            text = row.text.replace(',','')
            if '.' not in text:
                value = int(text)
            else:
                value = float(text)
            result.append(value)

        for stat in groupStats:
            row = html.select_one('tr.statistics-group-'+stat+" td.mw-statistics-numbers")
            text = row.text
            value = int(text)
            result.append(value)

        data.append(result)
        return data
    else:
        print (statusCode)

procesaURL(sample_url, [])

data = []
i=0
for link in links:
    procesaURL(link+"wiki/Special:Statistics", data)

import pandas as pd

df = pd.DataFrame(data=data, columns=['name','url']+stats+groupStats)
df.to_csv('wikia_statistics.csv')
