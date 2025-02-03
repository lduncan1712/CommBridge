

UPDATE communication
SET time_ended = time_sent
WHERE communication_type != 1;


ALTER TABLE communication ADD COLUMN IF NOT EXISTS delta_continuation INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_DELTA_FUTURE INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS delta_response INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS delta_weight INT;

ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_WITHIN BOOLEAN DEFAULT FALSE;

ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_SUPER_ROOM INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_SUPER_PARTICIPANT INT;


-- Mark If Communication Within




-- -- Join Super Room
UPDATE communication c
SET TEMP_SUPER_ROOM = r.super_room
FROM room r
WHERE c.room = r.id;

UPDATE communication c
SET TEMP_SUPER_PARTICIPANT = r.super_participant
FROM participant r
WHERE c.participant = r.id;


UPDATE communication c1
SET TEMP_WITHIN = TRUE
FROM communication c2
WHERE c1.room = c2.room
  AND c1.time_sent >= c2.time_sent
  AND c1.time_ended <= c2.time_ended
  AND c1.id != c2.id
  AND c1.time_ended != c1.time_sent;
  
  
  
  
 WITH previous_times AS (
    SELECT 
        id,
        room,
        time_sent,
        time_ended,
        LAG(time_ended) OVER (PARTITION BY TEMP_SUPER_ROOM ORDER BY time_sent, id) AS previous_time_ended
    FROM communication
)
UPDATE communication c1
SET delta_continuation = EXTRACT(EPOCH FROM c1.time_sent - pt.previous_time_ended)
FROM previous_times pt
WHERE c1.id = pt.id
  AND c1.room = pt.room;
  
  
  
  
  
  
WITH future_times AS (
    SELECT 
        id,
        room,
        time_sent,
        time_ended,
        LEAD(time_sent) OVER (PARTITION BY TEMP_SUPER_ROOM ORDER BY time_sent, id) AS next_time_sent
    FROM communication
)
UPDATE communication c1
SET TEMP_DELTA_FUTURE = EXTRACT(EPOCH FROM ft.next_time_sent - c1.time_ended)
FROM future_times ft
WHERE c1.id = ft.id
  AND c1.room = ft.room;
  


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
UPDATE communication c
SET delta_response = 
    CASE 
        WHEN EXTRACT(EPOCH FROM (c.time_sent - p.previous_time)) - COALESCE(p.previous_delta_temp, 0) < 0 THEN 0
        ELSE EXTRACT(EPOCH FROM (c.time_sent - p.previous_time)) - COALESCE(p.previous_delta_temp, 0)
    END
FROM previous_times p
WHERE c.id = p.id;














