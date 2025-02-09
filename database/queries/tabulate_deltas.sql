/*
  RATIONALE: for high level, and conversational level analysis we need to generate
             certain attributes
*/


ALTER TABLE communication ADD COLUMN IF NOT EXISTS m1_previous INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS m2_continue INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS m3_response INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS m4_weight INT;


ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_WITHIN BOOLEAN DEFAULT FALSE;


-- Mark Communications Inside Others (SUPER_ROOM)
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
WHERE c1.id = srm.id;


-- Mark m1_previous (SUPER_ROOM)
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
WHERE c1.id = pt.id
  AND (c1.communication_type != 1 OR c1.reply IS NULL); -- Not Split Calls


-- Mark m2_continue (SUPER_ROOM)
WITH future_times AS (
    SELECT 
        id, 
        time_ended,
        LEAD(time_sent) OVER (PARTITION BY TEMP_SUPER_ROOM ORDER BY time_sent, id) AS next_time_sent
    FROM communication
)
UPDATE communication c1
SET m2_continue = EXTRACT(EPOCH FROM ft.next_time_sent - c1.time_ended)
FROM future_times ft
WHERE c1.id = ft.id
  AND (c1.communication_type != 1 OR c1.reply IS NULL); -- Not Split Calls

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
SET m3_response = GREATEST(EXTRACT(EPOCH FROM (c.time_sent - p.pt)) - COALESCE(p.m2, 0), 0)
FROM previous_times p
WHERE c.id = p.id;




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

