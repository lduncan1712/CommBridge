import psycopg2, json, sys, argparse

# Opens database connection using credentials
with open("database/db_creds.json", 'r') as creds:
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

def upload_contact(contacts):

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

def clear_directional():
    cur.execute("""
        
        DELETE FROM participant
            WHERE id IN (
                SELECT participant_id
            FROM (
                SELECT 
            p.id AS participant_id,
            COUNT(DISTINCT sp.id) AS unique_super_participants_with_communications
        FROM 
            participant p
        JOIN 
            room_participation rp ON p.id = rp.participant
        LEFT JOIN 
            communication c ON rp.room = c.room
        LEFT JOIN 
            room_participation rp_others ON rp.room = rp_others.room
        LEFT JOIN 
            participant p_comm ON c.participant = p_comm.id
        LEFT JOIN 
            super_participant sp ON p_comm.super_participant = sp.id
        GROUP BY 
            p.id
        HAVING 
            COUNT(DISTINCT sp.id) = 0
        ) AS subquery
        );
    """)
    myConn.commit()














