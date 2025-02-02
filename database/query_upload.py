import argparse
from database import database
import json

parser = argparse.ArgumentParser()

parser.add_argument("--path",type=str, required=True)

args = parser.parse_args()

database.apply_query(args.path)