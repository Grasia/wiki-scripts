# Wikia Index

This folder includes the scripts for the extraction of Wikia information and a former analysis of the compiled data in February, 2018.

The scripts, notebooks and data contained in this folder are organized according to the following process:

1. We extract information from four data sources using for different scripts in the root folder:

    - Wikia Index (`generate_urls`): urls extracted from <http://www.wikia.com/Sitemap>
    - Wiki stats info (`generate_wiki_statistics.py`): Statistics about wikis extracted using [the Wikia API](http://www.wikia.com/api/v1). Data is extracted making requests to the service that gets extended information about wikis which name or topic match a keyword (` /api/v1/Wikis/ByString?expand=1`). 
    - Wiki Birth date (`get_wiki_birthdate.py`): Scrapping of wiki mainPage History in order to estimate its birthdate.
    - Wiki users (`get_wiki_users.pl`): Scraping of wiki Users page in order to find the number of users in this page acording to the number of editions.

2. The information is aggregated using the `data_aggregation` Python notebook. The execution of this script will generate two CSV files in the `data` folder:

    - wikia_stats_users.csv
    - wikia_stats_users_birthdate.csv

3. We performed two different analysis of the Wikia dataset. Both analysis are stored in the `analysis` folder.