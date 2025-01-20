import psycopg2, json

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
    
def get_or_set_participant(name,native_name,platform):

    #Find Matching ID
    cur.execute("SELECT id FROM participant where native_id = %s and platform = %s", (native_name,platform,))
    result = cur.fetchone()

    #If No ID
    if result is None:
        cur.execute("INSERT INTO participant(name,native_id,platform) VALUES (%s, %s, %s) RETURNING id", (name,native_name,platform))
        result = cur.fetchone()
        myConn.commit()
      

    return result[0]




def set_participant_legend(participants,platform):

    legend = {}
    for name, native in participants:
        legend[native] = get_or_set_participant(name,native, platform)

    return legend

def set_room_participation(participant_legend, platform):

    cur.execute("""INSERT INTO room(platform) VALUES (%s) RETURNING id""", (platform,))
    result = cur.fetchone()[0]
    myConn.commit()

    for key, index in participant_legend.items():

        cur.execute("""INSERT INTO room_participation(room,participant) VALUES (%s, %s)""", (result, index))
    myConn.commit()

    return result



def get_row_matching(platform, room, native_id=None, content=None):

    print("ROW MATCHING")
    
    #Using ID
    if not native_id is None:
        cur.execute("""
            SELECT id from communication where platform = %s and room = %s and native_id = %s
        """, (platform, room, native_id))

        attempt = cur.fetchone()

    #Using Content Field
    elif not content is None:
        print(f"CONTENT: {content}")
        cur.execute("""
            SELECT id from communication where platform = %s and room = %s and
            content LIKE %s ORDER BY time_sent DESC LIMIT 1
        """, (platform, room, '%' + content.strip() + '%'))
        attempt = cur.fetchone()

        print(f"RESULT: {attempt}")

    else:
        ...

    print(attempt)

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













