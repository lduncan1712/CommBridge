import argparse
import os, json, csv
from pathlib import Path

from file_types.discord import discord
from file_types.instagram import instagram
from file_types.message import message
from file_types.phone import phone

type_list = {
    "discord": discord,
    "instagram": instagram,
    "message": message,
    "phone": phone
}  


def open_file(path):

    #Extension
    __, extension = os.path.splitext(path)

    with open(path, 'r', encoding='utf-8') as open_file:

        #JSON
        if extension == ".json":
            return json.load(open_file)
        #CSV
        elif extension == ".csv":
            return list(csv.reader(open_file))
        #OTHER
        else:
            return None

def upload_file(path,type=None):

    opened = open_file(path)

    if opened is None:
        return

    #Known Platform Type
    if not type is None:
        type_list.get(type)(opened, path)

    #Determine Manually
    else:
        for key,value in type_list.items():
            if value.is_instance(opened,path):
                value(opened,path)

def upload(path,type=None):

    #print(f"UPLOADING: {path}")


    #File
    if os.path.isfile(path):
        #print("FILE")
        upload_file(path, type)

    #Folder
    elif os.path.isdir(path):
        #print("FOLDER")

        for item in os.listdir(path):
            full = os.path.join(path,item)
            upload(full,type)

    #Invalid
    else:
        print("Invalid Path Entered")






parser = argparse.ArgumentParser()

parser.add_argument("--path", type=str, required=True)
parser.add_argument("--type", type=str, required=False)

args = parser.parse_args()

upload(args.path, args.type)










