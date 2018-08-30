# Index Creation

This folder contains the scripts and notebooks to create and clean the Wikia Index. 

- `generate_urls` scraps the Wikia sitemap and generates a draft version of the index (`data/YYYYMMDD-wikia_index.txt`)
- `check_index_urls` uses the draft index in order to find broken links, abandoned communities and redirects (`data/YYYYMMDD-checked_index.csv`).
- `clean_index` cleans the first index removing the broken and abandoned wiki urls and removing duplicates and redirects (`data/YYYYMMDD-wikia_CuratedIndex.txt`).
