/*
  RATIONALE: for high level, and conversational level analysis we need to alter
             data slightly
*/

ALTER TABLE communication ADD COLUMN IF NOT EXISTS m1_past INT;

--Measures The Time Between This Communications Ending To Next Communication
ALTER TABLE communication ADD COLUMN IF NOT EXISTS m2_next INT;

--Measures The Time Between This Communication, And Oldest Message Following Last 
-- Response By Participant (IE: oldest unresponsed to communication)
ALTER TABLE communication ADD COLUMN IF NOT EXISTS m3_response INT;

-- Measures The Communicative "weight" of a communication
ALTER TABLE communication ADD COLUMN IF NOT EXISTS m4_weight INT;


ALTER TABLE communication ADD COLUMN IF NOT EXISTS m5_turn INT;



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
        c1.sroom = c2.sroom
    WHERE 
        c2.type = 1
        AND c1.start >= c2.start
        AND c1.finish <= c2.finish
        AND c1.id != c2.id
        AND c2.finish != c2.start
)
UPDATE communication c1
SET 
    TEMP_WITHIN = TRUE,
    m1_past = 0,
    m2_next = 0,
    m3_response = 0,
    reply = srm.c2_id
FROM super_room_mark srm
WHERE c1.id = srm.id
and c1.type != 1;

-- Place In Temporary Table
CREATE TEMP TABLE temp_removed_rows AS
SELECT * FROM communication WHERE TEMP_WITHIN = TRUE;  

-- Delete
DELETE FROM communication WHERE TEMP_WITHIN = TRUE;  


-- Determine m1 (SUPER_ROOM)
WITH previous_times AS (
    SELECT 
        id, 
        start,
        LAG(finish) OVER (PARTITION BY sroom ORDER BY start, id) AS previous_finish
    FROM communication
)
UPDATE communication c1
SET m1_past = EXTRACT(EPOCH FROM c1.start - pt.previous_finish)
                  
FROM previous_times pt
WHERE c1.id = pt.id;



-- Mark m2_next (SUPER_ROOM)
WITH future_times AS (
    SELECT 
        id, 
        finish,
        LEAD(start) OVER (PARTITION BY sroom ORDER BY start, id) AS next_start
     FROM communication
)
UPDATE communication c1
SET m2_next =  EXTRACT(EPOCH FROM ft.next_start - c1.finish)

FROM future_times ft
WHERE c1.id = ft.id;


-- Mark m3_response (SUPER_ROOM, SUPER_PARTICIPANT)
WITH previous_times AS (
    SELECT 
        id,
        start,
        LAG(start) OVER (PARTITION BY sparticipant, sroom ORDER BY start, id) AS pt,
        LAG(m2_next) OVER (PARTITION BY sparticipant, sroom ORDER BY start, id) AS m2
    FROM communication
)
UPDATE communication c
SET m3_response = EXTRACT(EPOCH FROM (c.start - p.pt)) - COALESCE(p.m2, 0)
FROM previous_times p
WHERE c.id = p.id;


-- HANDLES previous logic for calls (how to represent SEQUENTIAL vs CONCURRENT)
WITH max_m2_next AS (
    SELECT 
        finish, 
        MAX(m2_next) AS max_m2
    FROM communication
    GROUP BY finish
)
UPDATE communication c
SET m2_next = COALESCE(mc.max_m2, 0)  
FROM max_m2_next mc
WHERE c.finish = mc.finish
AND c.m2_next < 0;

UPDATE communication c
SET m1_past = 5   -- Alternatively 0
WHERE c.m1_past < 0;



-- Readd Within
INSERT INTO communication
SELECT * FROM temp_removed_rows;

DROP TABLE IF EXISTS temp_removed_rows;


-- Mark m4_weight
UPDATE communication c
SET m4_weight = 
    CASE 
        WHEN c.type = 0 THEN LENGTH(c.content)  -- COMM_MESSAGE
        WHEN c.type = 1 THEN GREATEST(2 * EXTRACT(EPOCH FROM (c.finish - c.start)), 100)  -- COMM_CALL
        WHEN c.type = 3 THEN 10  -- COMM_STICKER_GIF
        WHEN c.type = 5 THEN 10  -- COMM_REACTION
        WHEN c.type = 2 THEN 100  -- COMM_MEDIA
        WHEN c.type = 4 THEN 100  -- COMM_NATIVE_MEDIA
        WHEN c.type = 8 THEN 100  -- COMM_DELETED_NATIVE
        WHEN c.type = 7 THEN 100  -- COMM_LINK
        WHEN c.type = 6 THEN 100  -- COMM_ALTER
        WHEN c.type = -1 THEN (   -- COMM_REMOVED
            SELECT GREATEST(50, COALESCE(AVG(m4_weight), 0))
            FROM communication 
            WHERE type = 0
        )  
        ELSE NULL
    END
FROM communication c2
WHERE c.id = c2.id;




WITH OrderedMessages AS (
    SELECT
        id,
        sroom,
        sparticipant,
        start,
        DATE(start) AS msg_date,
        LAG(sparticipant) OVER (
            PARTITION BY sroom, DATE(start) 
            ORDER BY start
        ) AS prev_participant
    FROM communication
),
Clumps AS (
    SELECT 
        id,
        sroom,
        sparticipant,
        start,
        msg_date,
        SUM(CASE 
                WHEN prev_participant IS NULL OR prev_participant != sparticipant 
                THEN 1 
                ELSE 0 
            END) OVER (
            PARTITION BY sroom, msg_date
            ORDER BY start
        ) AS m5_turn
    FROM OrderedMessages
)
UPDATE communication AS c
SET m5_turn = cl.m5_turn
FROM Clumps AS cl
WHERE c.id = cl.id;