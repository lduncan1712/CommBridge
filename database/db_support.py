import argparse
from database import database
import json

parser = argparse.ArgumentParser()

parser.add_argument("--function", type=str, required=True)
parser.add_argument("--contacts", type=str, required=False)

args = parser.parse_args()

if args.function == "upload_contact":

    with open(args.contacts, 'r') as file:
        data = json.load(file) 
    database.upload_contact(data)

elif args.function == "clear_directional":
    database.clear_directional()

else:
    print("Invalid Function Entered")