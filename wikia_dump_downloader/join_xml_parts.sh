#!/bin/sh

## Variables declaration ##
data_dir='data'
processed_dir="$data_dir/processed"
prefix=$1


## Variables definition and directories creation ##
# Setting a directory to place output based on prefix (script argument)
if [ -z $prefix ]; then
  xml_list=$(ls -1b ${data_dir}/*.xml)
  prefix='output'
  output_xml="$processed_dir/$prefix/full/output.xml"
else
  xml_list=$(ls -1b ${data_dir}/${prefix}*.xml)
  output_xml="$processed_dir/$prefix/full/$prefix.xml"
fi


## Initialization part ##

# Create directories for moving procesed file and output joined XML file
mkdir -p "$processed_dir/$prefix/parts"
mkdir -p "$processed_dir/$prefix/full"
# Clean output_xml just in case there's been previous processed data with same name
`cat /dev/null > ${output_xml}`


## Processing and joining files ##
# iterating over data xml files and join them removing redudant info
i=0
xml_no=`echo $xml_list | wc -w`
echo "Number of parts to join: $(($xml_no))"

for file in $xml_list; do
        echo "Processing file $file"
        `cp $file aux.xml`
        if [ $i -ne 0 ]; then
                sed '1d' aux.xml > tmp.xml; # deleting first line
                sed '/<siteinfo>/,/<\/siteinfo>/d' tmp.xml > aux.xml # deleting <siteinfo> element
        fi
        if [ $i -ne $(($xml_no-1)) ]; then
                sed '$d' aux.xml > tmp.xml; # deleting last line
                mv tmp.xml aux.xml;
        fi
        
        cat aux.xml >> $output_xml;
        i=$(($i+1));
        filename=`echo $file | cut -d '/' -f 2`
        mv $file "$processed_dir/$prefix/parts/$filename"
done

# Cleaning temporary files
`rm aux.xml`
`rm tmp.xml`


## Validation ##
# validating xml through xmliint
# echo -n "Validating .xml..."
# xmllint --noout --valid ${output_xml} --dtdvalid output.dtd && echo 'OK'
