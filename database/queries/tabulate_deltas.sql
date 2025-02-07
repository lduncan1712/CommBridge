
-- Mark all fixed communication end time is start time
UPDATE communication
SET time_ended = time_sent
WHERE communication_type != 1;

--Define analysis columns and temp columns
ALTER TABLE communication ADD COLUMN IF NOT EXISTS delta_continuation INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_DELTA_FUTURE INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS delta_response INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS delta_weight INT;

ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_WITHIN BOOLEAN DEFAULT FALSE;

ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_SUPER_ROOM INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_SUPER_PARTICIPANT INT;



-- -- Reference SuperRooms within communication
UPDATE communication c
SET TEMP_SUPER_ROOM = r.super_room
FROM room r
WHERE c.room = r.id;

-- Reference Super participant within communication
UPDATE communication c
SET TEMP_SUPER_PARTICIPANT = r.super_participant
FROM participant r
WHERE c.participant = r.id;


-- Determine communication within other (IE: during a call)
UPDATE communication c1
SET TEMP_WITHIN = TRUE
FROM communication c2
WHERE c2.communication_type = 1 and   --call
      c1.TEMP_SUPER_ROOM = c2.TEMP_SUPER_ROOM and --same room
      c1.time_sent >= c2.time_sent and 
      c1.time_ended <= c2.time_ended and 
      c1.id != c2.id and 
      c2.time_ended != c2.time_sent;










INSERT INTO communication (
    
    time_sent,
    time_ended,
    communication_type,
    platform,
    TEMP_SUPER_PARTICIPANT,
    TEMP_SUPER_ROOM,
    room,
    weight
)
SELECT
    c.time_sent,
    c.time_ended,
    c.communication_type,
    c.platform,
    sp_id AS participant,
    c.TEMP_SUPER_ROOM,
    c.room,
    -1
FROM
    communication c
JOIN
    super_room sr ON c.temp_super_room = sr.id
CROSS JOIN
    unnest(sr.temp_super_participant_list) AS sp_id
WHERE
    c.communication_type = 1
    AND c.shared = TRUE;














  
  
  
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
  AND c1.room = pt.room;
  
  
  
  
  
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


