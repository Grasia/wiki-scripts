#!/bin/sh

data_dir='data/'
#~ xml_path=$data_dir + 'parts/'
output_xml="output.xml"

#if [ ! -d xml_path/processed ]; then
  #mkdir -p xml_path
#fi

`cat /dev/null > ${output_xml}`

# getting data dump name


# joining xml files in xml_path
i=0
xml_list=$(ls -1b ${data_dir}/*.xml)
xml_no=`echo $xml_list | wc -w`
for file in $xml_list; do
        `cp $file aux.xml`
        if [ $i -ne 0 ]; then
                sed '1d' aux.xml > tmp.xml;
                mv tmp.xml aux.xml;
        fi
        if [ $i -ne $(($xml_no-1)) ]; then
                echo $(($xml_no-1))
                sed '$d' aux.xml > tmp.xml;
                mv tmp.xml aux.xml;
                cat aux.xml;
        fi
        
        cat aux.xml >> $output_xml;
        i=$(($i+1));
done

`rm aux.xml`

# validating xml through xmliint
# echo -n "Validating .xml..."
# xmllint --noout --valid ${output_xml} --dtdvalid output.dtd && echo 'OK'
