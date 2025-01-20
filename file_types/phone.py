from .template import template
from datetime import datetime, timedelta

class phone(template):

    def __init__(self, file, file_name):
        pass

    def determine_if_instance(open_file, file_name):
        try: 
            if open_file[0][0] == "Call type":
                return True
            else:
                return False
        except:
            return False      












#     def __init__(self, file, file_name):

#         super().__init__(file, file_name)
        
#         self.replies_info = super_file.REPLY_LINKED_STR
#         self.inner_reactions_info = super_file.REACTION_NOT_STORED
#         self.outer_reactions_info = super_file.REACTION_LINKED_STR
#         self.calls_info = super_file.CALL_SPLIT
#         self.comms_chronologial = True
#         self.multi_room = True

#         self.setup(file, file_name)
        


# #*********************************
#     # Boolean Method Whether File Is Of Given Type
#     #**********************************
      
#     #***********************************            
#     #Opens to chronological, iterable, comms list
#     #***********************************
#     def load_file_and_comms(self):
#         return self.file[1:]

#     #************************************************
#     #Returns a list of participant name
#     #************************************************
#     def identify_participants(self):

#         list = []

#         for line in self.comms:
#             if line[4] in list:
#                 continue
#             else:
#                 list.append(line[4])

#         #Adding Unique Person
#         list.append("My Name")

#         return list





#         pass

#     #*********************************************
#     #Returns Normalized DateTime
#     #********************************************
#     def normalize_datetime(self, time):
#         #print(time)
#         return datetime.strptime(time, '%Y-%m-%d %H:%M:%S')


#     #********************************************
#     #*******************************************
#     #
#     #  Methods About Extracting Types Of Content
#     #
#     #********************************************
#     #********************************************
#     def content_type_message(self, comm):
#         pass

#     def content_type_call(self,commm):
#         return None

#     def content_type_media(self, comm):
#         pass

#     def content_type_sticker_gif(self, comm):
#         pass

#     def content_type_native_media(self, comm):
#         pass

#     def content_type_reaction(self, comm):
#         pass

#     def content_type_removed_media(self, comm):
#         pass


#     #*************************************
#     #Returns formatted TIME, SENDER
#     # Returns Sender As List (When Required, MultiRoom)
#     #***********************************
#     def content_consistant(self, comm):
#         time = self.normalize_datetime(comm[1])

#         #Person Sent, Name Recieved
#         if comm[0] == "Outgoing":
#             sender = [list(self.participant_cyper.keys())[-1], comm[4]]
#         #Name Sent, Person Recieved
#         else:
#             sender = [comm[4]]

#         return time, sender

#     #*************************************8
#     #Determines Type of comm
#     #**************************************
#     def determine_type(self, comm):
#         return super_file.COMM_CALL

#     #************************************
#     #Determines CALL_END_TIME
#     #***********************************
#     def determine_call_end_time(self, comm):
#         time = datetime.strptime(comm[1], '%Y-%m-%d %H:%M:%S')

#         hours, minutes, seconds = map(int, comm[2].split(':'))

#         time_quantity = timedelta(hours=hours, minutes=minutes, seconds=seconds)

#         end_datetime = time + time_quantity


#         return end_datetime


#     #*************************************************
#     # Returns Reference To Root, Marked As Unavailable, or None
#     #************************************************
#     def determine_root_message(self, comm, comm_type):
#         pass

#     #***************************************************
#     # Obtains all inner reactions stored
#     #***********************************************
#     def extract_inner_reactions(self, comm):
#         pass


#     def get_id(self, comm):
#         return None
        


