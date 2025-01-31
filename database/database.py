import psycopg2, json, sys, argparse

# Opens database connection using credentials
with open("credentials/db_creds.json", 'r') as creds:
    creds = json.load(creds)
    myConn = psycopg2.connect(
        dbname= creds["dbname"],
        user= creds["user"],
        host= creds["host"],
        password= creds["password"],
        port= creds["port"]
    )

cur = myConn.cursor()

def __init__(self):
    pass



def get_or_set_platform(name):

    #Find Matching ID
    cur.execute("SELECT id FROM platform where name = %s", (name,))
    result = cur.fetchone()

    #If No ID
    if result is None:
        cur.execute("INSERT INTO platform(name) VALUES (%s) RETURNING id", (name,))
        result = cur.fetchone()
        myConn.commit()
      

    return result[0]
    
def get_or_set_participant(name,username,native_name,platform):

    #Find Matching ID
    cur.execute("SELECT id FROM participant where native_id = %s and platform = %s", (native_name,platform,))
    result = cur.fetchone()

    if result is None:
        cur.execute("INSERT INTO participant(username, name,native_id,platform) VALUES (%s, %s, %s, %s) RETURNING id", (username, name,native_name,platform))
        result = cur.fetchone()
        myConn.commit()
      

    return result[0]

def set_participant_legend(participants,platform):

    legend = {}
    for name, username, native, in participants:

        if native is None or native == "":
            continue

        legend[native] = get_or_set_participant(name,username,native, platform)

    return legend

def set_room_participation(participant_legend, platform,name):

    cur.execute("""INSERT INTO room(platform,name) VALUES (%s,%s) RETURNING id""", (platform,name))
    result = cur.fetchone()[0]
    myConn.commit()

    for key, index in participant_legend.items():

        cur.execute("""INSERT INTO room_participation(room,participant) VALUES (%s, %s)""", (result, index))
    myConn.commit()

    return result

def get_row_matching(platform, room, native_id=None, content=None):

    #print("ROW MATCHING")
    
    #Using ID
    if not native_id is None:
        cur.execute("""
            SELECT id from communication where platform = %s and room = %s and native_id = %s
        """, (platform, room, native_id))

        attempt = cur.fetchone()

    #Using Content Field
    elif not content is None:
        #print(f"CONTENT: {content}")
        cur.execute("""
            SELECT id from communication where platform = %s and room = %s and
            content LIKE %s ORDER BY time_sent DESC LIMIT 1
        """, (platform, room, '%' + content.strip() + '%'))
        attempt = cur.fetchone()

        #print(f"RESULT: {attempt}")

    else:
        ...

    #print(attempt)

    return attempt

def set_communication(data):

    cur.execute("""
        INSERT INTO communication(communication_type, time_sent, time_ended, content, reply, native_id, participant,
            platform, room, location)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING id
    """, data)

    id = cur.fetchone()[0]

    myConn.commit()

    return id

#------------------------------------------------------------------

def contact_setup(contacts):

    cur.execute("SELECT id, name from platform")

    dictionary = {row[1]:row[0] for row in cur.fetchall()}

    for contact in contacts:

        cur.execute("SELECT id from super_participant where name = %s", (contact["preferred"],))

        id = cur.fetchone()

        if id is None:
            cur.execute("INSERT INTO super_participant(name,family) VALUES (%s, %s) returning id", (contact["preferred"],bool(contact["family"])))
            id = cur.fetchone()



        for comm_type in ["discord","instagram","message","phone"]:
            if comm_type in contact:
                comm_id = dictionary[comm_type]
                print("DO")
                query = f"UPDATE participant SET super_participant = %s where native_id = %s and platform = %s"
                for account in contact[comm_type]:
                    cur.execute(query, (id, account,comm_id))
                myConn.commit()
        myConn.commit()


    #TODO: mark all others as non?

#------------------------------------------------------


def apply_query(args):
    cur.execute(args)
    myConn.commit()






def set_weights():

    #WEIGHTS:

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

    #ATTEMPT TO EQUALIZE INFORMATION CONTENT

    #number of characters
    cur.execute(""" UPDATE communication SET weight = LENGTH(content) where communication_type = %s""", (COMM_MESSAGE,))

    #estimated characters based on time (s)
    cur.execute("""UPDATE communication SET weight = GREATEST(2*EXTRACT(EPOCH FROM (time_ended - time_sent)),100::numeric) where communication_type = %s""", (COMM_CALL,))
    
    #remove incorrect outliers (assume i hour)
    cur.execute("""UPDATE communication set weight =  120*60, 
                                        time_ended = time_sent + INTERVAL '7200 seconds'
                    where communication_type = 1 and weight > 50000""")


    #fixed cost of reactions
    cur.execute("""UPDATE communication SET weight = 10 where communication_type = %s""", (COMM_STICKER_GIF,))
    cur.execute("""UPDATE communication SET weight = 10 where communication_type = %s""", (COMM_REACTION,))

    #fixed cost of media
    cur.execute("""UPDATE communication SET weight = 100 where communication_type = %s""", (COMM_MEDIA,))
    cur.execute("""UPDATE communication SET weight = 100 where communication_type = %s""", (COMM_NATIVE_MEDIA,))
    cur.execute("""UPDATE communication SET weight = 100 where communication_type = %s""", (COMM_DELETED_NATIVE,))
    cur.execute("""UPDATE communication SET weight = 100 where communication_type = %s""", (COMM_LINK,))
    cur.execute("""UPDATE communication SET weight = 100 where communication_type = %s""", (COMM_ALTER,))

    cur.execute("""UPDATE communication 
                    SET weight = (Select AVG(weight) from communication 
                                      where communication_type = %s) where communication_type = %s""", (COMM_MESSAGE, COMM_REMOVED))

    myConn.commit()


#When you have multiple rooms, all containing the same (super participants) that is part
#of only one larger string of communication, thus can make a super_room

def generate_super_rooms():
    
    #Add Participant List
    cur.execute("""
                UPDATE room r
                SET participant_list = subquery.participant_array
                FROM (
                    SELECT rp.room,
                    ARRAY_AGG(DISTINCT rp.participant ORDER BY rp.participant) AS participant_array
                    FROM room_participation rp
                    GROUP BY rp.room
                ) AS subquery
                WHERE r.id = subquery.room;
                """)

    #Add SuperParticipant List:
    cur.execute("""
        UPDATE room r
        SET 
            participant_list = subquery.participant_array,
            super_participant_list = subquery.super_participant_array
            FROM (
                SELECT 
                rp.room,
                ARRAY_AGG(DISTINCT rp.participant ORDER BY rp.participant) AS participant_array,
                ARRAY_REMOVE(ARRAY_AGG(DISTINCT p.super_participant ORDER BY p.super_participant), NULL) AS super_participant_array
            FROM room_participation rp
            JOIN participant p ON rp.participant = p.id
            GROUP BY rp.room
        ) AS subquery
        WHERE r.id = subquery.room;
    """)

    cur.execute("""
        
WITH valid_rooms AS (
    SELECT super_participant_list, 
           COUNT(*) AS room_count
    FROM room
    WHERE array_length(super_participant_list, 1) = array_length(participant_list, 1) and
				array_length(super_participant_list,1)>1
    GROUP BY super_participant_list
    HAVING COUNT(*) >= 2
),
inserted_super_rooms AS (
    INSERT INTO super_room (name, super_participant_group)
    SELECT 
        (SELECT string_agg(name, ' ' ORDER BY id)
         FROM super_participant 
         WHERE id = ANY(vr.super_participant_list)),
        vr.super_participant_list
    FROM valid_rooms vr
    RETURNING id, super_participant_group
)
UPDATE room
SET super_room = isr.id
FROM inserted_super_rooms isr
WHERE room.super_participant_list = isr.super_participant_group
  AND array_length(room.super_participant_list, 1) = array_length(room.participant_list, 1);
  
    """)

    myConn.commit()