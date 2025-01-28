import json
from .template import template
from datetime import datetime

class discord(template):

    def __init__(self, file, file_name):

        super().__init__(file, file_name)

        self.reply_type =          template.CONNECT_ID   #when item is a reply, how is the communication its replying to represented
        self.outer_reaction_type = template.CONNECT_NA   #when item is a reaction, how is the communication its replying to stored
        self.inner_reactions = True
        self.call_type =           template.CALL_SINGLE
        self.chronological =       True
        self.multi_room =          False

        self.process()
        
    def is_instance(open_file, file_name):
        try:
            if "guild" in open_file:
                return True
        except:
            return False

    def get_comms(self):
        return self.file["messages"]

    def get_participants(self):
        return {(message["author"]["name"], message["author"]["nickname"], message["author"]["id"]) for message in self.comms}

    def get_datetime_format(self,time):

        if time is None:
            return None
        try:
            return datetime.strptime(time, '%Y-%m-%dT%H:%M:%S.%f%z')
        except:
            return datetime.strptime(time, '%Y-%m-%dT%H:%M:%S%z')

    def clean_participants(self,name:str) -> str:
        return name

    def get_comm_sender(self,comm,comm_type):
        return comm["author"]["id"]

    def get_comm_time(self,comm):
        return comm["timestamp"]

    def get_comm_id(self,comm):
        return comm["id"]

    def get_comm_root(self,comm, comm_type):
        if "reference" in comm:
            return comm["reference"]["messageId"]

    def get_comm_message(self,comm):
        if comm["type"] in ["Reply", "Default"]:
            return comm["content"]

    def get_comm_call(self,comm):
        if comm["type"] == "Call": 
            return comm["content"]

    def get_comm_media(self,comm):
        return [{"content":attach["url"], "location":None} for attach in comm["attachments"]]
        
    def get_comm_sticker_gif(self,comm):
        if comm["embeds"]:
            return [embed["url"] for embed in comm["embeds"] if ("https://cdn.discordapp.com" in embed["url"]) or \
                                                            ("https://tenor.com" in embed["url"])]
        if comm["stickers"]:
            return [sticker["sourceUrl"] for sticker in comm["stickers"]]
        
    def get_comm_alter(self,comm):
        if comm["type"] in ["RecipientAdd", "ChannelPinnedMessage","ChannelNameChange"]:
            return comm["content"]

    def get_comm_link(self,comm):
        return [{"location":embed["url"], "content":embed["title"]} for embed in comm["embeds"] if (not "https://cdn.discordapp.com" in embed["url"]) and \
                                                            (not "https://tenor.com" in embed["url"])]
        
    def get_call_end_time(self,comm):
        return comm["callEndedTimestamp"]

    def get_inner_reactions(self,comm):
        return [{"content": reaction_symbol["emoji"]["name"], "participant": user["id"], "datetime": None}
                for reaction_symbol in comm["reactions"]
                for user in reaction_symbol["users"]]

    #N/A
    def get_comm_native(self,comm):
        pass
    def get_comm_reaction(self,comm):
        pass
    def get_comm_removed(self,comm):   
        pass

        