# Index Creation

This folder contains the scripts and notebooks to create and clean the Wikia Index. 

- `generate_urls.py` scraps the Wikia sitemap and generates a draft version of the index. Generates the raw index: `data/YYYYMMDD-wikia_index.txt`
- `check_index_urls.py` uses the draft index in order to find broken links, abandoned communities and redirects. Generates data that clean_index will need to clean the raw index: `data/YYYYMMDD-checked_index.csv`.
- `clean_index.ipynb` uses the output of `check_index_urls.py` to clean the raw index by removing the broken and abandoned wiki urls and removing duplicates and redirects. Generates the curated index: `data/YYYYMMDD-wikia_CuratedIndex.txt`.
