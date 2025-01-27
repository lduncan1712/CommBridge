from database import database
from typing import Dict,Optional,Union,Any,List

class template:

    #Communication Formats
    COMM_UNKNOWN = -2      #Unlinked Reaction
    COMM_REMOVED = -1      #Removed, Either Shell, or reaction/reply exists
    COMM_MESSAGE = 0       #Text/Emojis
    COMM_CALL = 1          #Voice Call
    COMM_MEDIA = 2         #Photo/Video Attachment
    COMM_STICKER_GIF= 3    #Attached Sticker or Gif
    COMM_NATIVE_MEDIA = 4  #Platform Specific
    COMM_REACTION = 5      #Reaction
    COMM_ALTER = 6         #Modification To Chat
    COMM_LINK = 7          #Linking Website/App
    COMM_DELETED_NATIVE = 8


    #Communication Connection Format
    CONNECT_ID = 0     #Internal References Are Done By ID
    CONNECT_STR = 1    #Internal References Are Done Using Message Content
    CONNECT_NA = 2     #Internal References Should Exist, but dont
    CONNECT_UNLINKED = 3 #Internal References Dont Exist

    #Call Formats:
    CALL_SINGLE = 0   #Call Stored As Singular Object
    CALL_SPLIT = 1    #Call Stored As Split Object
    CALL_NA =    2    #Call Not Within This Format


    """
    Initializes A Superclass Template For A Given Filetype

        Args: 
            file: an opened file storing data in object specific format
            file_name: the pathname of a file
    """
    def __init__(self, file: Union[dict,list], file_name: str) -> None:
        
        self.reply_type = None          #How Message Replies Are Linked
        self.inner_reactions = None     #Whether Reactions Are Stored Within Messages
        self.outer_reaction_type =  None #How Reactions Outside Are Stored
        self.call_type = None            #How Calls Are Represented
        self.chronological = None         #Whether Data is Stored Chronologically
        self.multi_room = None            #Whether Any Communication Is Subdivided by People 
    
        self.file = file
        self.file_name = file_name

        self.TYPE_RESPONSE_DICTIONARY = {
            template.COMM_CALL: self.get_comm_call,
            template.COMM_ALTER: self.get_comm_alter,
            template.COMM_REMOVED: self.get_comm_removed,
            template.COMM_MEDIA: self.get_comm_media,
            template.COMM_STICKER_GIF: self.get_comm_sticker_gif,
            template.COMM_DELETED_NATIVE: self.get_comm_deleted_native,
            template.COMM_NATIVE_MEDIA: self.get_comm_native,
            template.COMM_REACTION: self.get_comm_reaction,
            template.COMM_LINK: self.get_comm_link,
            template.COMM_MESSAGE: self.get_comm_message
        }
    
    
    """
    Determines The Database Reference To A Communication comm is replying to, if comm is a Reply

    Args:
        comm: the formatted communication
        relation: the constant representing the reference of root reference

    Returns:
        Optional[int]: the database primary key of root message if one exists
    """        
    def link_root(self,comm: Any, relation: int, comm_type: int) -> Optional[int]:

        root_value = self.get_comm_root(comm,comm_type)

        #No Root
        if root_value is None:
            root = None

        #Reference To Unknown Communication
        elif root_value == template.COMM_UNKNOWN:
            root = template.COMM_UNKNOWN

        #Some Known Communication
        else:

            #Linked Using Native ID
            if relation == template.CONNECT_ID:

                root = database.get_row_matching(self.platform_id, self.room_id, native_id=root_value)
            
            #Linked Using Communication Value
            elif relation == template.CONNECT_STR:

                root = database.get_row_matching(self.platform_id, self.room_id, content=root_value)

            else:
                ...

            #Link Not In Database: Communication Removed
            if root is None:
                root = template.COMM_REMOVED

        #print(root)
        
        return root

    """
    Obtains And Formats Data Within The Communication comm To Be Uploaded According To This File Template    
    """
    def prep_comm(self,comm: Any) -> List:

        #Core Communication Information

        time_sent = self.get_datetime_format(self.get_comm_time(comm))

        

        native_id = self.get_comm_id(comm)


        content = comm_type = location = time_ended = root = None


        #Determine Communication Type And Contents
        for key, is_type in self.TYPE_RESPONSE_DICTIONARY.items():
            result = is_type(comm)
            if result:
                comm_type = key
                content = result
                break

        sender = self.participant_legend[self.get_comm_sender(comm,comm_type)]


        

        ##TODO: MULTIPLE MEDIA:
        if isinstance(content,list):
            content = content[0]


        #NATIVE MEDIA
        if comm_type in [template.COMM_NATIVE_MEDIA, template.COMM_MEDIA, template.COMM_LINK]:
            location = content["location"]
            content = content["content"]

        #Call
        if comm_type == template.COMM_CALL:

            #Stored In 2 Parts
            if self.call_type == template.CALL_SPLIT:

                #If This Is Second Part (Cache Isnt Empty)
                if self.cache:
                    time_ended = time_sent
                    time_sent = self.cache.pop()
                
                #This Is The First Part
                else:
                    self.cache.append(time_sent)
                    return None

            #All Information Contained
            else:
                time_ended = self.get_call_end_time(comm)

        #Any Other Comm Type (That Can Be Repliable/Reactible)
        else:

            #If This Communication Is A Distinct Reaction (No SubReaction)
            if comm_type == template.COMM_REACTION:

                if self.outer_reaction_type == template.CONNECT_NA:
                    root = None

                #If Reactions Arent Linked (Unknown)
                if self.outer_reaction_type == template.CONNECT_UNLINKED:
                    root = super_file.COMM_UNKNOWN
                
                #Some Form Of Tracking
                else:
                    root = self.link_root(comm, self.outer_reaction_type, comm_type)

            #Non Reaction (SubReaction Possible)
            else:

                #A Reply Possible
                if self.reply_type != template.CONNECT_NA:

                    root = self.link_root(comm, self.reply_type, comm_type)



        items =  [comm_type, time_sent, time_ended, content, root, native_id, sender, self.platform_id, self.room_id, location]

        return items

    """
    Uploads Each Individual Communication Into The Database
    """
    def upload_comms(self):

        self.cache = []

        for comm in self.comms:

      

            data = self.prep_comm(comm)

            if data is None:
                continue
            else:

                #print(data)

                comm_id = database.set_communication(data)

                if self.inner_reactions:

                 

                    reaction_list = self.get_inner_reactions(comm)

                    if not reaction_list is None:

                     

                        for reaction in reaction_list:
                            

                            database.set_communication([template.COMM_REACTION,
                                                        self.get_datetime_format(reaction["datetime"]),   #no time
                                                        None,
                                                        reaction["content"],
                                                        comm_id,
                                                        None,   #content
                                                        self.participant_legend[reaction["participant"]],
                                                        self.platform_id,
                                                        self.room_id,
                                                        None #location
                                                        ])

    """
    The Process Of Setting Up, Formatting, then Uploading The Data In This File Template Into The Database
    """
    def process(self) -> None:


        self.comms = self.get_comms()

        if not self.chronological:
            self.comms.reverse()

        #Get The Platform ID
        self.platform_id = database.get_or_set_platform(str(self.__class__.__name__))

        #Obtain The Info Of Participants
        self.participants = self.get_participants()

        #print("PAR:")
        #print(self.participants)

        #Create A Legend For Their IDS
        self.participant_legend = database.set_participant_legend(self.participants,self.platform_id)

        #print(self.participant_legend)

        #Store The Room Number This Data Is Going Into
        self.room_id = database.set_room_participation(self.participant_legend, self.platform_id,self.file_name)

        #Upload The Core Communication
        self.upload_comms()


    #""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    # IMPLEMENT BELOW AS REQUIRED
    #""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


    """
    Returns whether a file represents an instance of this classes unique file structure

    Args:
        open_file (varies): all information within an opened uniquely stored format
        file_name (str): the full filepath name of open_file

    Return:
        bool: Whether open_file is an instance of this classes file_type
    """
    def is_instance(open_file: Union[Dict,List], file_name: str) -> bool:
        pass

    """
    Returns datetime within a postgres interpretable DATETIME format

    Args:
        date (varies): time format representing when communications were sent

    Returns:
        datetime: a datetime representing of when communications were sent
    """
    def get_datetime_format(self,datetime:Any) -> Any:
        pass


    
    """
    Returns the list of communications within the file

    Return:
        List: containing all distinct communication within the file 
    """
    def get_comms(self) -> List:
        pass


    """
    Returns any participants within this file

    Return:
        A list of participants, each with a name, username, and native name: the name
        by which they are internally referenced
    """
    def get_participants(self) -> set[(str,str,str)]:
        pass


    """
    Returns Cleaned Participant Information

    Args: 
        name: the unclean name to be remade (IE: +1905... -> 905)

    Returns:
        the cleanest participant
    """
    def clean_participants(self,name:str) -> str:
        pass


    #""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    #""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    #""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    #The Methods Below Represents Getters For Unique Data Groups/Types
    #Within The Data Format This Class Represents
    #
    #Args:
    #    comm: (Union[List,Dict]): all stored information for a distinct communication within
    #                               this sub-class' unique file format
    #""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    #""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    #""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

    """
    Returns The Internally Referenced Identify Of This Communication's Sender
    """
    def get_comm_sender(self,comm:Any,comm_type:int) -> str:
        pass

    """
    Returns The Time Of This Communication's Sending

        Returns: (varies): the file_type specific time format
    """
    def get_comm_time(self,comm:Any) -> Any:
        pass

    """
    The EndTime Within A Call Communication

        Returns (varies): the file_type specific time format
    """
    def get_call_end_time(self,comm:Any) -> Any:
        pass

    """
    The Internally Referenced Identity Of This Communication
    """
    def get_comm_id(self,comm:Any) -> str:
        pass

    """
    The Content Of This Communication If It Represents A Text Based Message
    """
    def get_comm_message(self,comm:Any) -> str:
        pass

    """
    The Content Of This Communication If It Represents A Call
    """
    def get_comm_call(self,comm:Any) -> Optional[str]:
        pass

    """
    The Content Of This Communication If It Represents A Media, (IE: Photos Or Videos)
    
        Returns ["content"]: the file path name
                ["location"]: the location of file
    """
    def get_comm_media(self,comm:Any) -> Optional[Dict[str,str]]:
        pass

    """
    The Content Of This Communication If It Represents A Sticker Or Gif
    """
    def get_comm_sticker_gif(self,comm:Any) -> Optional[str]:
        pass

    """
    The Content Of This Communication If It Represents A Piece Of Native Media (IE: "Instagram Reel")

        Returns ["content"]: the content/description of this media
                ["location"]: the link/location of this media
    """
    def get_comm_native(self,comm:Any) -> Optional[Dict[str,str]]:
        pass

    """
    The Content Of This Communication If It Represents A Reaction (IE: "Reacting to a message")
    """
    def get_comm_reaction(self,comm:Any) -> Optional[str]:
        pass

    """
    The Content Of This Communication If It Represents A Removed Item:

        Returns: "removed" or "deleted" depending on source of deletion if known
    """
    def get_comm_removed(self,comm:Any) -> Optional[str]: 
        pass

    """
    The Content Of This Communication If It Represents A Communication Structure Alteration (IE: "adding participants")
    """
    def get_comm_alter(self,comm:Any) -> Optional[str]:
        pass

    """
    The Content Of This Communication If It Represents A Link To A Website

        Returns ["content"]: the content/description of this media
                ["location"]: the link/location of this media
    """
    def get_comm_link(self,comm:Any) -> Optional[Dict[str,str]]:
        pass

    """
    The content of a piece of native media removed
    """
    def get_comm_deleted_native(self,comm:Any) -> Optional[str]:
        pass

    """
    Returns The Identifier To The Communication This comm, of type comm_type Is Replying To, If It Represents A Marked Reply
    """
    def get_comm_root(self,comm:Any,comm_type:int) -> Optional[str]:
        pass

    """
    Returns The Reactions To This Communication Stored Within It, If Any

        Returns: ["participant"]: internally referenced id of reacter
                 ["content"]: the reaction
                 ["datetime"]: the time of reaction occurance
    """
    def get_inner_reactions(self, comm: Any) -> Optional[List[Dict]]:
        pass


    



 





    