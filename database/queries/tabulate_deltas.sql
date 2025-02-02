
UPDATE communication
SET time_ended = time_sent
WHERE communication_type != 1;




-- for given comm
-- look at previous ends, use the previous one


-- AA------B------AA-----B
--  ........
--  ...............   


--  .......
--  
 
ALTER TABLE ADD COLUMN IF NOT EXISTS delta_continuation INT;
ALTER TABLE ADD COLUMN IF NOT EXISTS TEMP_DELTA_FUTURE INT;
ALTER TABLE ADD COLUMN IF NOT EXISTS delta_response INT
ALTER TABLE ADD COLUMN IF NOT EXISTS delta_weight INT;


UPDATE communication c1
SET delta_continuation = EXTRACT(EPOCH FROM c1.time_sent - 
        (Select c2.time_ended for communication c2
        WHERE c2.room = c1.room AND c2.time_ended < c1.time_sent
        ORDER BY c2.time_ended DESC
        LIMIT 1
        ));





-- MARKS TIME SINCE PREVIOUS
WITH ordered_communications AS (
    SELECT
        id,
        room,
        time_sent,
        LAG(time_sent) OVER (PARTITION BY room ORDER BY time_sent) AS previous_time_sent
    FROM communication
)
UPDATE communication c
SET delta_continuation = EXTRACT(EPOCH FROM (oc.time_sent - oc.previous_time_sent))
FROM ordered_communications oc
WHERE c.id = oc.id
  AND oc.previous_time_sent IS NOT NULL;




-- --MARKS TIMES BETWEEN NEXT MESSAGE
WITH ordered_communications AS (
    SELECT
        id,
        room,
        time_sent,
        LEAD(time_sent) OVER (PARTITION BY room ORDER BY time_sent) AS next_time_sent
    FROM communication
)
UPDATE communication c
SET TEMP_DELTA_FUTURE = EXTRACT(EPOCH FROM (oc.next_time_sent - c.time_sent))
FROM ordered_communications oc
WHERE c.id = oc.id
  AND oc.next_time_sent IS NOT NULL;
  




  
--  --MARKS TIME SINCE EARLIEST MESSAGE REPLIABLE
WITH previous_times AS (
    SELECT
        id,
        participant,
        room,
        time_sent,
        time_ended,
        LAG(time_sent) OVER (PARTITION BY participant, room ORDER BY time_sent) AS previous_time,
        LAG(delta_temp) OVER (PARTITION BY participant, room ORDER BY time_sent) AS previous_delta_temp
    FROM communication
)
UPDATE communication c
SET delta_response = EXTRACT(EPOCH FROM (COALESCE(p.time_ended, p.time_sent) - p.previous_time)) - COALESCE(p.previous_delta_temp, 0)
FROM previous_times p
WHERE c.id = p.id;
