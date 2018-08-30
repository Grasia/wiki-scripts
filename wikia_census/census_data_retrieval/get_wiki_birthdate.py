"""
Estimation of the birth date of a wiki in Wikia.
We suppose that the first page created is the wiki landing page.
We look for the date of the first edition in the history of the landing page.
Wikia index contains url from wikis that are not longer available or deleted
so this script also store these facts. 

The result is a csv file with the following columns:
- The URL of the wiki landing page
- Estimated birthdate. It is an empty string if the page was not available or deleted
- State: AVAILABLE, NOT-AVAILABLE, DELETED
"""

from bs4 import BeautifulSoup
import requests
import pandas as pd
import time

suffix = "?dir=prev&action=history"
wikiaIndex = '20180220-wikia_index.txt'
output_filename = 'wikia_birthdate'

url = sample_url+suffix

def requestDate(url):
    """Looks for the date of the firs edition of the landing page of a wiki.
    Returns the estimated birthdate (or an empty string) and the state result
    of the request.

    Keyword arguments:
    url -- url of the index page processed
    
    Return:
    date: Estimated date or empty string
    state: AVAILABLE, NOT-AVAILABLE, DELETED
    """

    # Request the history page in reverse order
    req = requests.get(url+suffix)

    # Check Success code (200)
    statusCode = req.status_code
    state = "NOT-AVAILABLE"
    date = ""
    if statusCode == 200:
        html = BeautifulSoup(req.text,"lxml")
        try:
            # Look for the last entry in the history page
            pagehistory = html.select("#pagehistory > li")
            lastDiff  = pagehistory[-1].find("span", {"class":"mw-history-histlinks"})
            date=lastDiff.findNextSibling("a").text
            state = "AVAILABLE"
        except Exception as inst:
            # Looks for a message that informs that the page was deleted
            warning = html.select_one(".mw-warning-with-logexcerpt p")
            if ("deleted" in warning.text):
                state = "DELETED"  
        finally:
            return date,state
            
    else:
        # The url was not available. Return an empty date and NOT-AVAILABLE
        return date,state


# Load the wikia Index
with open(wikiaIndex) as f:
    links = [line.strip() for line in f]

i=0
part = 0
dates = []
errors = []
lenght = len(links)
for i in range(0, lenght-1):
    url = links[i]
    try:
        date,state = requestDate(url)
        dates.append([url,date,state])
    except Exception as inst:
        errors.append(url)
        # Print the last index to rerun the script starting
        # at this index if the script fails
        print("Index of last URL: "+ i)
    if i%20000==0:
        # Save every 20000 urls to avoid losing work if the script fails.
        dfDates = pd.DataFrame(dates)
        dfDates.columns = ['URL', "date", "state"]
        dfDates.to_csv('{}-{}.csv'.format(output_filename,i), index=False)

# Save the complete file
dfDates = pd.DataFrame(dates)
dfDates.columns = ['URL', "date", "state"]
timestr = time.strftime("%Y%m%d")
dfDates.to_csv('{}-{}.csv'.format(timestr,output_filename), index=False)

