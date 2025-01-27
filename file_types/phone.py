from .template import template
from datetime import datetime, timedelta

class phone(template):

    def __init__(self, file, file_name):

        print("MAKING")
        
        super().__init__(file, file_name)

        self.reply_type =          template.CONNECT_NA
        self.inner_reactions =     False
        self.outer_reaction_type = template.CONNECT_NA
        self.call_type =           template.CALL_SINGLE
        self.chronological =       True
        self.multi_room =          False

        self.process()

    

    def is_instance(open_file, file_name ):
        try: 
            if open_file[0][0] == "Call type":
                return True
            else:
                return False
        except:
            return False    


    def get_datetime_format(self,time):

        try:
            return datetime.strptime(time, '%Y-%m-%d %H:%M:%S')
        except:
            return datetime.strptime(time, '%Y-%m-%d %H:%M')

    def get_comms(self):
        return self.file[1:]


    def get_participants(self):
        parts =  [("You", None, "You"), (self.clean_participants(self.comms[0][4]), None, self.clean_participants(self.comms[0][3]))]
        return parts


    def clean_participants(self,name:str) -> str:
        
        if len(name) == 12 and name[0] == "+":
            name = name[1:]

        #Starts With 1
        if len(name) == 11 and name[0] == 1 and name.isdigit():
            name = name[1:]

        return name

    def get_comm_sender(self,comm,comm_type:int):
        if comm[0] == "Outgoing":
            return "You"
        else:

            orig = self.clean_participants(comm[3][:99])

            return orig
            
    def get_comm_time(self,comm):
        return comm[1]

 
    def get_call_end_time(self,comm):

        time = self.get_datetime_format(comm[1])

        hours, minutes, seconds = map(int, comm[2].split(':'))

        time_quantity = timedelta(hours=hours, minutes=minutes, seconds=seconds)

        end_datetime = time + time_quantity

        return end_datetime
   
    def get_comm_id(self,comm):
        return None

    def get_comm_call(self,comm):
        return comm[6]
