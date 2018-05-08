# Wikia Index

This folder includes the scripts for the extraction of Wikia information and a former analysis of the compiled data in February, 2018.

## Organization

We extract information from four data sources:

- Wikia Index (`generate_urls`): urls extracted from <http://www.wikia.com/Sitemap>
- Wiki stats info (`generate_wiki_statistics.py`): Statistics about wikis extracted using [the Wikia API](http://www.wikia.com/api/v1). Data is extracted making requests to the service that gets extended information about wikis which name or topic match a keyword (` /api/v1/Wikis/ByString?expand=1`). 
- Wiki Birth date (`get_wiki_birthdate.py`): Scrapping of wiki mainPage History in order to estimate its birthdate.
- Wiki users (`get_wiki_users.pl`): Scraping of wiki Users page in order to find the number of users in this page acording to the number of editions.