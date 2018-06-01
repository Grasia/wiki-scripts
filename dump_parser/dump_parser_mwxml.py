#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
   dump_parser_mwxml.py

   Alternative version of the script using the mediawiki-utilities/python-mwxml library.
   Script to convert xml to a csv files with readable useful data\
for pandas processing within wikichron app.


   Copyright 2018 Abel 'Akronix' Serrano Juste <akronix5@gmail.com>
"""

import sys

from mwxml import Dump, Page


def xml_to_csv(filename):
    # Construct dump file iterator
    input_file = Dump.from_file(open(filename))

    # Open output file
    output_csv = open(filename[0:-3]+"csv",'w')

    # writing header for output csv file
    output_csv.write(";".join(["page_id","page_title","page_ns",
                                "revision_id","timestamp",
                                "contributor_id","contributor_name",
                                "bytes"]))
    output_csv.write("\n")

    # Parsing xml and writting proccesed data to output csv
    print("Processing...")

    # Iterate through pages
    for page in input_file.pages:

        # Iterate through a page's revisions
        for revision in page:
            if revision != None:
                revision_id = str(revision.id)
                timestamp = str(revision.timestamp)
                revision_bytes = '-1' if revision.bytes == None else str(revision.bytes)
            else:
                print("A line has imcomplete info about the REVISION metadata "
                        "and therefore it's been removed from the dataset.")
                continue

            page_id = str(page.id)
            page_title = '|{}|'.format(page.title)
            page_ns = str(page.namespace)

            if revision.user == None:
                print("Revision {} has imcomplete info about the USER metadata "
                        "and therefore it's been removed from the dataset."
                        .format(revision.id))
                continue
            else:
                contributor_id = str(revision.user.id)
                contributor_name = '|{}|'.format(revision.user.text)

            revision_row = [page_id,page_title,page_ns,
                            revision_id,timestamp,
                            contributor_id,contributor_name,
                            revision_bytes]
            #~ print(revision_row)
            output_csv.write(";".join(revision_row) + '\n')

    print("Done processing")
    output_csv.close()
    return True


if __name__ == "__main__":
  print (sys.argv)
  if(len(sys.argv)) >= 2:
    for xmlfile in sys.argv[1:]:
      print("Starting to parse file " + xmlfile)
      if xml_to_csv(xmlfile):
        print("Data dump {} parsed succesfully".format(xmlfile))
  else:
    print("Error: Invalid number of arguments. Please specify one or more .xml file to parse", file=sys.stderr)
