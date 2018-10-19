# Wikia Census

_You can find a repo with all the raw and processed data of the census as well as the notebooks for its analysis in [kaggle](https://www.kaggle.com/abeserra/wikia-census/)._

This folder includes the scripts for the extraction of Wikia information and subsequent analysis of the compiled data in February, 2018.

The scripts, notebooks and data contained in this folder are organized according to the following process:

1. We extract information from four data sources using four different scripts in the root folder:

    - Wikia Index (`generate_urls`): urls extracted from <http://www.wikia.com/Sitemap>
    - Wiki stats info (`generate_wiki_statistics.py`): Statistics about wikis extracted using [the Wikia API](http://www.wikia.com/api/v1). Data is obtained making requests to the service that gets extended information about wikis which name or topic match a keyword (` /api/v1/Wikis/ByString?expand=1`).
    - Wiki Birth date (`get_wiki_birthdate.py`): Scrapping of the wiki *Main* page history in order to estimate its birthdate.
    - Wiki users (`get_wiki_users.pl`): Scrapping of *Special:ListUsers* page to retrieve the *actual* number of users of each wiki.

2. The information is aggregated using the `data_aggregation.py` Python script. The execution of this script will generate two CSV files in the `data` folder:

    - wikia_stats_users.csv
    - wikia_stats_users_birthdate.csv

    You can see what this script is actually doing more visually using the notebook version: `data_aggregation.ipynb`.

3. We performed two different analysis of the Wikia dataset. Both analysis are stored in the `analysis` folder.
