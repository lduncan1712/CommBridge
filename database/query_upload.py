

import argparse
from database import database
import json

parser = argparse.ArgumentParser()

parser.add_argument("--contacts", type=str, required=False)
parser.add_argument("--path",type=str, required=True)

args = parser.parse_args()


if args.contacts:
    
    with open(args.contacts, 'r') as file:
        contacts = json.load(file)
    database.contact_setup(contacts)

else:
    with open(args.path, 'r') as file:
        query = file.read()

    database.apply_query(query)