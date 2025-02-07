/*
  RATIONALE: for high level, and conversational level analysis we need to generate
             certain attributes
*/


ALTER TABLE communication ADD COLUMN IF NOT EXISTS delta_continuation INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_DELTA_FUTURE INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS delta_response INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS delta_weight INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_WITHIN BOOLEAN DEFAULT FALSE;

ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_ADDED BOOLEAN DEFAULT FALSE;


-- Determine communication within other (IE: during a call)
UPDATE communication c1
SET TEMP_WITHIN = TRUE,
    delta_continuation = 0
FROM communication c2
WHERE c2.communication_type = 1 and   
      c1.TEMP_SUPER_ROOM = c2.TEMP_SUPER_ROOM and 
      c1.time_sent >= c2.time_sent and 
      c1.time_ended <= c2.time_ended and 
      c1.id != c2.id and 
      c2.time_ended != c2.time_sent;


-- For Every Shared Call, Break Split Into Communication For Each 
INSERT INTO communication (
    time_sent,
    time_ended,
    communication_type,
    platform,
    TEMP_SUPER_PARTICIPANT,
    TEMP_SUPER_ROOM,
    room,
    weight,
    delta_continuation,
    TEMP_ADDED
)
SELECT
    c.time_sent,
    c.time_ended,
    c.communication_type,
    c.platform,
    sp_id AS participant,
    c.TEMP_SUPER_ROOM,
    c.room,
    c.weight,
    0,
    TRUE
FROM
    communication c
JOIN
    super_room sr ON c.temp_super_room = sr.id
CROSS JOIN
    unnest(sr.temp_super_participant_list) AS sp_id
WHERE
    c.communication_type = 1
    AND c.shared = TRUE
    AND sp_id != c.TEMP_SUPER_PARTICIPANT;














  
  
  
 -- Find the time differnece between a messages sending and the previous message
 WITH previous_times AS (
    SELECT 
        id,
        room,
        time_sent,
        time_ended,
        LAG(time_ended) OVER (PARTITION BY TEMP_SUPER_ROOM ORDER BY time_sent, id) AS previous_time_ended
    FROM communication
)

-- Update communication
UPDATE communication c1
SET delta_continuation = EXTRACT(EPOCH FROM c1.time_sent - pt.previous_time_ended)
FROM previous_times pt
WHERE c1.id = pt.id
  AND c1.room = pt.room
  AND TEMP_ADDED = FALSE;
  
  
  
  
  
-- Find the time difference between this ending and next sending
WITH future_times AS (
    SELECT 
        id,
        room,
        time_sent,
        time_ended,
        LEAD(time_sent) OVER (PARTITION BY TEMP_SUPER_ROOM ORDER BY time_sent, id) AS next_time_sent
    FROM communication
)
-- update accordingly
UPDATE communication c1
SET TEMP_DELTA_FUTURE = EXTRACT(EPOCH FROM ft.next_time_sent - c1.time_ended)
FROM future_times ft
WHERE c1.id = ft.id
  AND c1.room = ft.room;
  

-- Create a list of the time since previous communication made by given participant
WITH previous_times AS (
    SELECT
        id,
        TEMP_SUPER_PARTICIPANT AS participant,
        TEMP_SUPER_ROOM AS room,
        time_sent,
        LAG(time_sent) OVER (PARTITION BY TEMP_SUPER_PARTICIPANT, TEMP_SUPER_ROOM ORDER BY time_sent, id) AS previous_time,
        LAG(TEMP_DELTA_FUTURE) OVER (PARTITION BY TEMP_SUPER_PARTICIPANT, TEMP_SUPER_ROOM ORDER BY time_sent, id) AS previous_delta_temp
    FROM communication
)
-- update rows, so it reflects communication after (IE first message possibly responded to)
UPDATE communication c
SET delta_response = 
    CASE 
        WHEN EXTRACT(EPOCH FROM (c.time_sent - p.previous_time)) - COALESCE(p.previous_delta_temp, 0) < 0 THEN 0
        ELSE EXTRACT(EPOCH FROM (c.time_sent - p.previous_time)) - COALESCE(p.previous_delta_temp, 0)
    END
FROM previous_times p
WHERE c.id = p.id;























WITH updated_communication AS (
    SELECT 
        id,
        communication_type,
        content,
        time_sent,
        time_ended,
        -- Calculate weights for different conditions
        CASE
            WHEN communication_type = 0 THEN LENGTH(content)  -- COMM_MESSAGE
            WHEN communication_type = 1 THEN GREATEST(2 * EXTRACT(EPOCH FROM (time_ended - time_sent)), 100)  -- COMM_CALL
            WHEN communication_type = 3 THEN 10  -- COMM_STICKER_GIF
            WHEN communication_type = 5 THEN 10  -- COMM_REACTION
            WHEN communication_type = 2 THEN 100  -- COMM_MEDIA
            WHEN communication_type = 4 THEN 100  -- COMM_NATIVE_MEDIA
            WHEN communication_type = 8 THEN 100  -- COMM_DELETED_NATIVE
            WHEN communication_type = 7 THEN 100  -- COMM_LINK
            WHEN communication_type = 6 THEN 100  -- COMM_ALTER
            WHEN communication_type = -1 THEN (SELECT AVG(weight) FROM communication WHERE communication_type = 0)  -- COMM_REMOVED
            ELSE NULL
        END AS calculated_weight
    FROM communication
)
UPDATE communication
SET 
    weight = updated_communication.calculated_weight
FROM updated_communication
WHERE communication.id = updated_communication.id;


