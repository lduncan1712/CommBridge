from database import database
import json
import argparse

def upload_contact(input_path):

    with open(input_path, 'r') as file:
        data = json.load(file) 

    database.upload_contact(data)

parser = argparse.ArgumentParser()

parser.add_argument("--input", type=str, required=True)

args = parser.parse_args()

upload_contact(args.input)