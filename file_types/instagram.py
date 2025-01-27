import database.database as database
import json, emoji,os
from os.path import basename, dirname
from datetime import datetime, timedelta, timezone

from .template import template

class instagram(template):

    


    def __init__(self, file, file_name):
        
        super().__init__(file, file_name)

        self.reply_type =          template.CONNECT_NA
        self.inner_reactions =     True
        self.outer_reaction_type = template.CONNECT_NA
        self.call_type =           template.CALL_SPLIT
        self.chronological =       False
        self.multi_room =          False

        self.process()



    
    def get_inner_reactions(self,comm):

        if "reactions" in comm:
            return [{"content":reaction["reaction"], "participant":reaction["actor"], "datetime":reaction.get("timestamp")} for reaction in comm["reactions"]]
    

    def is_instance(open_file, file_name):
        try:
            if "magic_words" in open_file:
                return True
            else:
                return False
        except:
            return False

    def get_participants(self):
        
        parts = {(item["sender_name"], None, item["sender_name"]) for item in self.comms} | \
                {(item["name"], None, item["name"]) for item in self.file["participants"]}

        return parts

        
    def get_comms(self):
        return self.file["messages"]

    def get_datetime_format(self,date):

        #print(date)
        if not date is None:
            
            

            if date > 999999999999:
                dt_in_secs = date/1000
            else:
                dt_in_secs = date

            time_delta = timedelta(seconds=dt_in_secs)

            # Create a datetime object representing the epoch (1970-01-01 00:00:00 UTC)
            epoch = datetime(1970, 1, 1, tzinfo=timezone.utc)

            new_v =  epoch + time_delta
            #print(new_v)

            return new_v

    def clean_participants(self,name:str) -> str:
        return name

    def get_comm_sender(self,comm,comm_type):
        return comm["sender_name"]

    def get_comm_time(self,comm):
        return comm["timestamp_ms"]


    def get_call_end_time(self,comm):
        return comm["timestamp_ms"]


    def get_comm_message(self,comm):
        return comm.get("content")


    def get_comm_call(self,comm):
        if ("content" in comm) and \
             any(s in comm["content"] for s in [ "started an audio call", "started a video chat",
                                                         "Video chat ended", " Audio call ended",
                                                         "missed an audio call", "missed a video chat"]):

                return comm["content"]


    def get_comm_media(self,comm):
        if "photos" in comm:
            return [{"content":media.get("uri"), "location":media.get("backup_uri")} for media in comm["photos"]]
        elif "videos" in comm:
            return [{"content":media.get("uri"), "location":media.get("backup_uri")} for media in comm["videos"]]

    def get_comm_sticker_gif(self,comm):
        pass


    def get_comm_native(self,comm):
        if "share" in comm:
            return {
                "location": comm["share"]["link"],
                "content": comm["share"].get("share_text")
            }
            
    def get_comm_reaction(self,comm):
        if "content" in comm:
            #Owner Liked
            if comm["content"] == "Liked a message":
                return comm["content"]

            #Anouther Person
            elif  " liked a message" in comm["content"]:
                return comm["content"]
            
            #
            elif "eacted " in comm["content"] and " to your message" in comm["content"]:

                s1 = comm["content"].split("eacted ")[1]
                s2 = s1.split(" to")[0]

                return s2

    def get_comm_deleted_native(self,comm):

        #no share
        if all(key not in comm for key in ["share", "video", "photos"]):
            
            #no content or says sent 
            if not "content" in comm or " sent an attachment" in comm["content"]:
                return "deleted"

        #some share, nothing inside
        if "share" in comm and not "link" in comm["share"]:
                return "removed"

    def get_comm_alter(self,comm):
        
        if "content" in comm:
            if any(s in comm["content"] for s in [ " left the group.", " to the group.", " named the group ", 
                                                    " created the group.", " changed the theme to", "changed the group photo."]):
                return comm["content"]

    def get_comm_link(self,comm):
        if "content" in comm:
            st = comm["content"]
            if (st.startswith("http") and st.endswith(".com")):
                return {"content":"Link", "location":str}
            
    