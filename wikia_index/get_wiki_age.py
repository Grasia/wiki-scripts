from bs4 import BeautifulSoup
import requests

suffix = "?dir=prev&action=history"
sample_url = "http://10low46japreligion.wikia.com/"
wikiaIndex = '20180220-wikiaIndex.txt'
output_filename = 'wikia_ages'

url = sample_url+suffix

def requestDate(url):
    # Realizamos la petición a la web
    req = requests.get(url)

    # Comprobamos que la petición nos devuelve un Status Code = 200
    statusCode = req.status_code
    if statusCode == 200:

        # Pasamos el contenido HTML de la web a un objeto BeautifulSoup()
        html = BeautifulSoup(req.text,"lxml")
        pagehistory = html.select("#pagehistory > li")
        lastDiff  = pagehistory[-1].find("span", {"class":"mw-history-histlinks"})
        return lastDiff.findNextSibling("a").text
    else:
        print (statusCode)

with open(wikiaIndex) as f:
    links = [line.strip() for line in f]


import csv
def write_to_csv(dates, part):
    with open('{}-{0:02}.csv'.format(output_filename, part), 'w') as myfile:
        myfile.write("%s\n" % ('url, creation'))
        wr = csv.writer(myfile, quoting=csv.QUOTE_ALL)
        for date in dates:
            wr.writerow(date)


i=0
part = 0
dates = []

for link in links:
    if i>0 and i%5000==0:
        write_to_csv(dates, part)
        part += 1
        dates = []
    url = link+suffix
    try:
        date = requestDate(url)
        dates.append([link,date])
    except Exception as inst:
        print("Link: {} / {}".format(url,inst))

    i+=1


