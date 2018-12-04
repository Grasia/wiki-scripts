#!/bin/sh

# Cleaning temporary files
`rm tmp.xml`
`rm aux.xml`

## Variables declaration ##
output_xml="20181203_wikia_edits.xml.all"
`rm ${output_xml}` # clean previous output_xml file
xml_list=$(ls -1b *.xml)

xml_no=`echo $xml_list | wc -w`
echo "Number of parts to join: $(($xml_no))"


## Processing and joining files ##
i=0
for file in $xml_list; do
  echo "Processing file $file..."

  cp $file tmp.xml

  # Replacing invalid xml values. Note that we need a different file for input and for output.
  sed -i 's/\&/\&amp;/g' tmp.xml # replacing & by XML form
  sed -i "s/'/\&apos;/g" tmp.xml # replacing ' by XML form
  perl substitute-wrong-quotes.pl < tmp.xml > aux.xml # replacing " by XML form if they are not enclosing an attribute

  xmllint --schema wikia_edits.xsd aux.xml --noout \
  && cp aux.xml $file.clean \
  && echo "The $file has been transformed to a good XML format and the result is saved in ${file}.clean";

  echo "Proceed to join cleaned part with the rest..."

  if [ $i -ne 0 ]; then       # if it isn't first xml
    sed -i '1,2d' aux.xml; # deleting first 2 lines (<?xml version?> and <wikis> opening tag)
  fi
  if [ $i -ne $(($xml_no-1)) ]; then # if it isn't last xml
    sed -i '$d' aux.xml; # deleting last line: </wikis> closing tag
  fi

  cat aux.xml >> $output_xml;
  i=$(($i+1));
done

# Cleaning temporary files
`rm aux.xml`
`rm tmp.xml`

## Validation ##
# validating xml through xmllint
echo -n "Validating full .xml... "
xmllint --schema wikia_edits.xsd ${output_xml} --noout

echo "Done!"
