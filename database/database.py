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
    cur.execute("SELECT id FROM participant where nid = %s and platform = %s", (native_name,platform,))
    result = cur.fetchone()

    if result is None:
        cur.execute("INSERT INTO participant(username, name,nid,platform) VALUES (%s, %s, %s, %s) RETURNING id", (username, name,native_name,platform))
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
            SELECT id from communication where platform = %s and room = %s and nid = %s
        """, (platform, room, native_id))

        attempt = cur.fetchone()

    #Using Content Field
    elif not content is None:
        #print(f"CONTENT: {content}")
        cur.execute("""
            SELECT id from communication where platform = %s and room = %s and
            content LIKE %s ORDER BY start DESC LIMIT 1
        """, (platform, room, '%' + content.strip() + '%'))
        attempt = cur.fetchone()

        #print(f"RESULT: {attempt}")

    else:
        ...

    #print(attempt)

    return attempt

def set_communication(data):

    cur.execute("""
        INSERT INTO communication(type, start, finish, content, reply, nid, participant,
            platform, room, link)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING id
    """, data)

    id = cur.fetchone()[0]

    myConn.commit()

    return id

#------------------------------------------------------------------

def build_manual_superparticipants(contacts):

    #INSERTING SUPER PARTICIPANT
    cur.execute("SELECT id, name from platform")
    dictionary = {row[1]:row[0] for row in cur.fetchall()}

    for contact in contacts:

        cur.execute("SELECT id from super_participant where name = %s", (contact["preferred"],))

        id = cur.fetchone()

        if id is None:
            cur.execute("INSERT INTO super_participant(name,family,contact) VALUES (%s, %s, %s) returning id", (contact["preferred"],bool(contact["family"]), True))
            id = cur.fetchone()

        for comm_type in ["discord","instagram","message","phone"]:
            if comm_type in contact:
                comm_id = dictionary[comm_type]
                query = f"UPDATE participant SET sparticipant = %s where nid = %s and platform = %s"
                for account in contact[comm_type]:
                    cur.execute(query, (id, account,comm_id))
                myConn.commit()
        myConn.commit()

#------------------------------------------------------

def apply_query(query_path):

    with open(query_path, 'r') as file:
        query = file.read()

    cur.execute(query)
    myConn.commit()
