/*
  RATIONALE: for high level, and conversational level analysis we need to alter
             data slightly
*/


-- Add Analysis Columns

-- Measures Time Between Messages, Measures time between messages sent by other users
-- Measures the weight of communication


-- Measures The Time Between This Communications Sending And Previous Communication
ALTER TABLE communication ADD COLUMN IF NOT EXISTS m1_previous INT;

--Measures The Time Between This Communications Ending To Next Communication
ALTER TABLE communication ADD COLUMN IF NOT EXISTS m2_continue INT;

--Measures The Time Between This Communication, And Oldest Message Following Last 
-- Response By Participant (IE: oldest unresponsed to communication)
ALTER TABLE communication ADD COLUMN IF NOT EXISTS m3_response INT;

-- Measures The Communicative "weight" of a communication
ALTER TABLE communication ADD COLUMN IF NOT EXISTS m4_weight INT;


-- ---------------------------------

-- GROUP:

-- unique group number
-- weight??

-- ---------------------------------

-- Daily (time based):

-- entropy (participant split)

-- density of conversation ()




-- Mark Communications Inside Others (SUPER_ROOM)
ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_WITHIN BOOLEAN DEFAULT FALSE;
WITH super_room_mark AS (
    SELECT 
        c1.id,
        c2.id AS c2_id
    FROM 
        communication c1
    JOIN 
        communication c2
    ON 
        c1.TEMP_SUPER_ROOM = c2.TEMP_SUPER_ROOM
    WHERE 
        c2.communication_type = 1
        AND c1.time_sent >= c2.time_sent
        AND c1.time_ended <= c2.time_ended
        AND c1.id != c2.id
        AND c2.time_ended != c2.time_sent
)
UPDATE communication c1
SET 
    TEMP_WITHIN = TRUE,
    m1_previous = 0,
    m2_continue = 0,
    m3_response = 0
FROM super_room_mark srm
WHERE c1.id = srm.id
and c1.communication_type != 1;

-- Place In Temporary Table
CREATE TEMP TABLE temp_removed_rows AS
SELECT * FROM communication WHERE TEMP_WITHIN = TRUE;  

-- Delete
DELETE FROM communication WHERE TEMP_WITHIN = TRUE;  




-- Break Shared Communication (IE: Call) Into One Communication Per Participant (SUPER_ROOM, SUPER_PARTICIPANT)
WITH numbered_rows AS (
    SELECT
        c.time_sent,
        c.time_ended,
        c.communication_type,
        c.platform,
        sp_id AS participant,
        c.TEMP_SUPER_ROOM,
        c.room,
        c.id,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY sp_id) AS rn
    FROM
        communication c
    JOIN
        super_room sr ON c.temp_super_room = sr.id
    CROSS JOIN
        unnest(sr.temp_super_participant_list) AS sp_id
    WHERE
        c.communication_type = 1
        AND c.shared = TRUE
        AND sp_id != c.TEMP_SUPER_PARTICIPANT
)
INSERT INTO communication (
    time_sent,
    time_ended,
    communication_type,
    platform,
    TEMP_SUPER_PARTICIPANT,
    TEMP_SUPER_ROOM,
    room,
    reply
)
SELECT
    nr.time_sent + INTERVAL '5 seconds' + INTERVAL '0.1 second' * nr.rn, 
    nr.time_ended,
    nr.communication_type,
    nr.platform,
    nr.participant,
    nr.TEMP_SUPER_ROOM,
    nr.room,
    nr.id
FROM
    numbered_rows nr;



-- Determine m1 (SUPER_ROOM)
WITH previous_times AS (
    SELECT 
        id, 
        time_sent,
        LAG(time_ended) OVER (PARTITION BY TEMP_SUPER_ROOM ORDER BY time_sent, id) AS previous_time_ended
    FROM communication
)
UPDATE communication c1
SET m1_previous = EXTRACT(EPOCH FROM c1.time_sent - pt.previous_time_ended)
                  
FROM previous_times pt
WHERE c1.id = pt.id;



-- Mark m2_continue (SUPER_ROOM)
WITH future_times AS (
    SELECT 
        id, 
        time_ended,
        LEAD(time_sent) OVER (PARTITION BY TEMP_SUPER_ROOM ORDER BY time_sent, id) AS next_time_sent
     FROM communication
)
UPDATE communication c1
SET m2_continue =  EXTRACT(EPOCH FROM ft.next_time_sent - c1.time_ended)

FROM future_times ft
WHERE c1.id = ft.id;


-- Mark m3_response (SUPER_ROOM, SUPER_PARTICIPANT)
WITH previous_times AS (
    SELECT 
        id,
        time_sent,
        LAG(time_sent) OVER (PARTITION BY TEMP_SUPER_PARTICIPANT, TEMP_SUPER_ROOM ORDER BY time_sent, id) AS pt,
        LAG(m2_continue) OVER (PARTITION BY TEMP_SUPER_PARTICIPANT, TEMP_SUPER_ROOM ORDER BY time_sent, id) AS m2
    FROM communication
)
UPDATE communication c
SET m3_response = EXTRACT(EPOCH FROM (c.time_sent - p.pt)) - COALESCE(p.m2, 0)
FROM previous_times p
WHERE c.id = p.id;


-- HANDLES previous logic for calls (how to represent SEQUENTIAL vs CONCURRENT)
WITH max_m2_continue AS (
    SELECT 
        time_ended, 
        MAX(m2_continue) AS max_m2
    FROM communication
    GROUP BY time_ended
)
UPDATE communication c
SET m2_continue = COALESCE(mc.max_m2, 0)  
FROM max_m2_continue mc
WHERE c.time_ended = mc.time_ended
AND c.m2_continue < 0;

UPDATE communication c
SET m1_previous = 5   -- Alternatively 0
WHERE c.m1_previous < 0;



-- Readd Within
INSERT INTO communication
SELECT * FROM temp_removed_rows;

DROP TABLE IF EXISTS temp_removed_rows;



-- Mark m4_weight
UPDATE communication c
SET weight = 
    CASE 
        WHEN c.communication_type = 0 THEN LENGTH(c.content)  -- COMM_MESSAGE
        WHEN c.communication_type = 1 THEN GREATEST(2 * EXTRACT(EPOCH FROM (c.time_ended - c.time_sent)), 100)  -- COMM_CALL
        WHEN c.communication_type = 3 THEN 10  -- COMM_STICKER_GIF
        WHEN c.communication_type = 5 THEN 10  -- COMM_REACTION
        WHEN c.communication_type = 2 THEN 100  -- COMM_MEDIA
        WHEN c.communication_type = 4 THEN 100  -- COMM_NATIVE_MEDIA
        WHEN c.communication_type = 8 THEN 100  -- COMM_DELETED_NATIVE
        WHEN c.communication_type = 7 THEN 100  -- COMM_LINK
        WHEN c.communication_type = 6 THEN 100  -- COMM_ALTER
        WHEN c.communication_type = -1 THEN (   -- COMM_REMOVED
            SELECT COALESCE(AVG(weight), 0) 
            FROM communication 
            WHERE communication_type = 0
        )  
        ELSE NULL
    END
FROM communication c2
WHERE c.id = c2.id;

