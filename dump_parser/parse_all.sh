dumps_dir='../wikia_dump_downloader/data/processed/'
wikis_list=$(ls -1b $dumps_dir)

for dir in $wikis_list; do
	echo "Processing wiki $dir"
	wiki=$dumps_dir$dir'/full/'$dir'.xml'
	./dump_parser.py $wiki
done
