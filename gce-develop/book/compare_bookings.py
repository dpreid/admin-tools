#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Feb 26 22:01:59 2023

@author: tim
"""
import json
from deepdiff import DeepDiff 
import pyrfc3339 as rfc3339
   
with open("generated_bookings.json") as file:
    gb = json.load(file)
    
with open("exported_bookings.json") as file:
    eb = json.load(file)    
 

gbr = {}

for item in gb:
    gbr[item["name"]]={
           "user": item["user"],
           "slot": item["slot"],
           "policy": item["policy"],
           "when": {
               "start": rfc3339.parse(item["when"]["start"]),
               "end": rfc3339.parse(item["when"]["end"]),
               }
        }
    

    
ebr = {}

for item in eb:
    ebr[item["name"]]={
            "user": item["user"],
           "slot": item["slot"],
           "policy": item["policy"],
           "when": {
               "start": rfc3339.parse(item["when"]["start"]),
               "end": rfc3339.parse(item["when"]["end"]),
               }
        }
    
    
ddiff = DeepDiff(gbr, ebr, ignore_order=True)
print (ddiff)
    
    