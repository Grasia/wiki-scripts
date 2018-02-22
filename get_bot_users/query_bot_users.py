#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
   query_bot_users.py

   Descp: A simple script to download the bot users of a certain wiki
   and output the user ids in an output file readable for pandas.
   It uses the mediawiki endpoint api.php to do the queries.

   Created on: 09-feb-2018

   Copyright 2018 Abel 'Akronix' Serrano Juste <akronix5@gmail.com>
"""

import requests
import sys
import json
import re

endpoint = '/api.php?action=query&list=groupmembers&gmgroups=bot|bot-global&gmlimit=500&format=json'


def get_bots_ids(base_url, offset=0):
   """
   Query the enpoint and returns a list of bot userids
   """
   url = base_url + endpoint + '&gmoffset={}'.format(offset)
   #~ print(url)
   r = requests.get(url)
   res = r.json()
   bots_ids = [ str(bot['userid']) for bot in res['users'] ]
   if 'query-continue' in res:
      return bots_ids + get_bots_ids(base_url, offset=res['query-continue']['groupmembers']['gmoffset'])
   else:
      return bots_ids

def write_outputfile(filename, bots):
   import numpy as np
   np.array(bots_ids).tofile(filename, sep=',')


def main():
   help = """This script gives you the bot user ids for a given set of wikis.\n
            Syntax: python3 query_bot_users url1 [url2, url3,...]""";

   if(len(sys.argv)) >= 2:
      if sys.argv[0] == 'help':
         print(help);
         exit(0)

      for url in sys.argv[1:]:
         if not (re.search('^http', url)):
            url = 'http://' + url
         print("Retrieving data for: " + url)
         bots_ids = get_bots_ids(url)
         print("These are the bots ids:")
         print(json.dumps(bots_ids))
         print("<" + "="*50 + ">")
   else:
      print("Error: Invalid number of arguments. Please specify one or more wiki urls to get the bots from.", file=sys.stderr)
      print(help)
      exit(1)

if __name__ == '__main__':
   main()



