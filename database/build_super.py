import argparse
from database import database
import json

parser = argparse.ArgumentParser()

parser.add_argument("--contacts",type=str, required=False)

args = parser.parse_args()

#Upload Any Manually Given Contacts
if args.contacts:
    with open(args.contacts, 'r') as file:
        contacts = json.load(file)
    database.build_manual_superparticipants(contacts)

#Set Rest Using Remaining Query
database.apply_query("database\\queries\\build_remaining_super_participants.sql")
    
database.apply_query("database\\queries\\build_super_rooms.sql")
