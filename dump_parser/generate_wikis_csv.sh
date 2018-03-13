dumps_dir='../wikia_dump_downloader/data/processed/'
wikis_list=$(ls -1b $dumps_dir)

echo "url, csvfile" > wikis.csv
for dir in $wikis_list; do
	echo "$dir, $dir.csv" >> wikis.csv
done
