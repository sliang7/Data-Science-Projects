from sodapy import Socrata
import requests
from requests.auth import HTTPBasicAuth
import json
import argparse
import sys
import os

# Creates a parser. Parser is the thing where you add your arguments. 
parser = argparse.ArgumentParser(description='NYC Fire Incident Dispatch Data')
# In the parse, we have two arguments to add.
# The first one is a required argument for the program to run. If page_size is not passed in, don’t let the program to run
parser.add_argument('--page_size', type=int, help='how many rows to get per page', required=True)
# The second one is an optional argument for the program to run. It means that with or without it your program should be able to work.
parser.add_argument('--numpages', type=int, help='how many pages to get in total')
# Take the command line arguments passed in (sys.argv) and pass them through the parser.
# Then you will ned up with variables that contains page size and num pages.  
args = parser.parse_args(sys.argv[1:])
print(args)

INDEX_NAME=os.environ["INDEX_NAME"]
DATASET_ID=os.environ["DATASET_ID"]
APP_TOKEN=os.environ["APP_TOKEN"]
ES_HOST=os.environ["ES_HOST"]
ES_USERNAME=os.environ["ES_USERNAME"]
ES_PASSWORD=os.environ["ES_PASSWORD"]

def convertAndUpload(numpages):
    for n in range(numpages):
            es_rows=[] 
            rows = client.get(DATASET_ID, limit=args.page_size, offset=n*args.page_size, where="incident_datetime IS NOT NULL and starfire_incident_id IS NOT NULL")
             #Added 10/30/22 @ 5:19pm
            for row in rows:
                try:
                    #Convert to dictionary in Elasticsearch
                    es_row = {}
                    es_row["starfire_incident_id"] = row["starfire_incident_id"]
                    es_row["incident_datetime"] = row["incident_datetime"]
                    es_row["incident_response_seconds_qy"] = float(row["incident_response_seconds_qy"])
                    es_row["incident_travel_tm_seconds_qy"] = float(row["incident_travel_tm_seconds_qy"])
                    es_row["engines_assigned_quantity"] = float(row["engines_assigned_quantity"])
                    es_row["incident_borough"] = row["incident_borough"]
                    es_row["highest_alarm_level"] = row["highest_alarm_level"]
                    es_row["zipcode"] = row["zipcode"]
                except Exception as e:
                    print (f"Error!: {e}, skipping row: {row}")
                    continue
                
                es_rows.append(es_row)

            bulk_upload_data = ""
            for line in es_rows:
                print(f'Handling row {line["incident_datetime"]}')
                action = '{"index": {"_index": "' + INDEX_NAME + '", "_type": "_doc", "_id": "' + line["incident_datetime"] + '"}}'
                data = json.dumps(line)
                bulk_upload_data += f"{action}\n"
                bulk_upload_data += f"{data}\n"
            #print(bulk_upload_data) #Commented out 10/30/22 @ 5:20pm
            
            try:
                # Upload to Elasticsearch by creating a document
                resp = requests.post(f"{ES_HOST}/_bulk",
                    # We upload es_row to Elasticsearch
                            data=bulk_upload_data,auth=HTTPBasicAuth(ES_USERNAME, ES_PASSWORD), headers = {"Content-Type": "application/x-ndjson"})
                resp.raise_for_status()
                print ('Done')
                    
                # If it fails, skip that row and move on.
            except Exception as e:
                print(f"Failed to insert in ES: {e}")
    
if __name__ == '__main__':
    try:
        #Using requests.put(), we are creating an index (db) first.
        resp = requests.put(f"{ES_HOST}/{INDEX_NAME}", auth=HTTPBasicAuth(ES_USERNAME, ES_PASSWORD),
                json={
                    "settings": {
                        "number_of_shards": 1,
                        "number_of_replicas": 1
                    },
                    "mappings": {
                        #We are specifying the columns and define what we want the data to be.
                        #However, it is not guaranteed that the data will come us clean. 
                        #We will might need to clean it in the next steps.
                        #If the data you're pushing to the Elasticsearch is not compatible with these definitions, 
                        #you'll either won't be able to push the data to Elasticsearch in the next steps 
                        #and get en error due to that or the columns will not be usable in Elasticsearch 
                        "properties": {
                            "starfire_incident_id" : {"type" : "keyword"},
                            "incident_datetime": {"type": "date"},
                            "incident_response_seconds_qy": {"type": "float"},
                            "incident_travel_tm_seconds_qy": {"type": "float"},
                            "engines_assigned_quantity": {"type": "float"},
                            "incident_borough": {"type": "keyword"},
                            "highest_alarm_level": {"type": "keyword"},
                            "zipcode": {"type": "keyword"},
                        }
                    },
                }
            )
        resp.raise_for_status()
        print(resp.json())
        #If we send another put() request after creating an index (first put() request), the pogram will give an error and crash.
    #In order to avoid it, we use try and except here.
    #If the index is already created, it will raise an excepion and the program will not be crashed. 
    except Exception as e:
        print("Index already exists! Skipping")    
    client = Socrata("data.cityofnewyork.us", APP_TOKEN, timeout=10000)
    #Num_pages=mathematical expression
    #Num_pages*page_size=totalrows
    #get the total number of rows in the dataset first
    #find such a value for the num_pages so that you can get the entire dataset
    # i.e. page_size = 10K then numpages = ???
    if args.numpages is None: #if numpages is not given, then the default for offset is 0; https://dev.socrata.com/docs/queries/
        rows_goal = client.get(DATASET_ID, where="incident_datetime IS NOT NULL and starfire_incident_id IS NOT NULL", select="COUNT(*)") #Obtain all data
        num_rows_goal = int(rows_goal[0]['COUNT']) #get the ~8m count from the dictionary
        args.numpages = int(num_rows_goal/args.page_size)
        numpages = args.numpages
        print('Total number of rows in dataset:', num_rows_goal) #Total number of rows printed out
        convertAndUpload(numpages)
    else: #numpages is given
        numpages = args.numpages
        convertAndUpload(numpages)