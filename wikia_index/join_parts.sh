output_csv="wikia_birthdate.csv"
csv_list=$(ls -1b *.csv)


for file in $csv_list; do
  echo "Processing file $file"
  `cp $file aux.csv`
  if [ $i -ne 0 ]; then       # if it isn't first csv
          sed '1d' -i aux.csv; # deletes first line
  fi
  cat aux.csv >> $output_csv;
  i=$(($i+1));
done

# Cleaning temporary files
`rm aux.csv`
