from datetime import datetime
from .template import template

class message(template):

    def __init__(self, file, file_name):

        super().__init__(file, file_name)

        self.reply_type =          template.CONNECT_STR
        self.inner_reactions =     False
        self.outer_reaction_type = template.CONNECT_STR
        self.call_type =           template.CALL_SPLIT
        self.chronological =       True
        self.multi_room =          False

        self.process()




    def is_instance(open_file, file_name):
        try:
            first_row = open_file[0]
            if first_row[0] == "Chat Session":
                return True
            else:
                return False
        except:
            return False

    
    def get_datetime_format(self,dt):
        try:
            return datetime.strptime(dt, '%Y-%m-%d %H:%M')
        except:
            return datetime.strptime(dt,  '%Y-%m-%d %H:%M:%S')

    def get_comms(self):
        return self.file[1:]


   
    def get_participants(self):

        participants = {(self.clean_participants(row[8]),
                        None, 
                        self.clean_participants((row[7]))) for row in self.comms}

        #Since Self Is Represented As Blank In This Form
        participants.add(("You", None, "You"))

        #print("PARTS")
        #print(participants)
        
        return participants

    def clean_participants(self,name:str) -> str:
        
        if len(name) == 12 and name[0] == "+":
            name = name[1:]

        #Starts With 1
        if len(name) == 11 and name[0] == 1 and name.isdigit():
            name = name[1:]

        return name

  
    def get_comm_sender(self,comm,comm_type:int):

        if comm[7] == "":
            return "You"
        return self.clean_participants(comm[7])


    def get_comm_time(self,comm):
        return comm[1]

    def get_comm_message(self,comm):
        if self.get_comm_media(comm) is None and \
            self.get_comm_reaction(comm) is None:
                return comm[12]


    def get_comm_media(self,comm):
        if comm[13] != "":
            return {"content":comm[13],"location":None}

    def get_comm_sticker_gif(self,comm):
        pass

    def get_comm_reaction(self,comm):
        if any(word in comm[12] for word in ['Liked “', 'Loved “', 'Disliked “', 'Liked an image']):
            
            words = comm[12]

            if 'Liked' in words:
                return "👍"

            elif 'Loved' in words:
                return "❤️"

            else: 
                return "👎"

    def get_comm_removed(self,comm): 
        if comm[6] == 'Notification':
            return comm[12]

    def get_comm_alter(self,comm):
        text = comm[12]

        if ("added" in text and " to the conversation." in text) or \
            ("removed" in text and " from the conversation." in text) or \
                ("named the conversation '" in text and "'." in text):
            return text
        
   
    def get_comm_link(self,comm):
        if comm[12].startswith("https://"):
            return {"content":comm[12], "location":comm[12]}

    def get_comm_root(self,comm,comm_type):
        
        if comm_type == template.COMM_REACTION:
        
            if comm[12] == "Liked an image":
                return template.COMM_UNKNOWN
            else:
                start_marker = '“'
                end_marker = '”'

                words = comm[12]

                start_index = words.find(start_marker)
                end_index = words.find(end_marker)
            
                inner_portion = words[start_index + len(start_marker):end_index].strip()

                if inner_portion[-1:] == '…':
                    inner_portion = inner_portion[:-1].strip()

        else:

            if comm[10] == "":
                return None
        
            else:
                

                start_marker = '« '
                end_marker = ' »'

                words = comm[10]

                start_index = words.find(start_marker)
                end_index = words.find(end_marker)

                inner_portion = words[start_index + len(start_marker):end_index].strip()

            
            if len(inner_portion) > 3:
                
                last = inner_portion[-3:]

                if last == "...":
                    inner_portion = inner_portion[:-3]      
                    
        if inner_portion.strip() == "":
            return None

        return inner_portion.strip()