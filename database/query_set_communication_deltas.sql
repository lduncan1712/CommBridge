
-- -- -- MARKS TIME SINCE PREVIOUS MESSAGE
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
SET delta_temp = EXTRACT(EPOCH FROM (oc.next_time_sent - c.time_sent))
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
        LAG(time_sent) OVER (PARTITION BY participant, room ORDER BY time_sent) AS previous_time,
        LAG(delta_temp) OVER (PARTITION BY participant, room ORDER BY time_sent) AS previous_delta_temp
    FROM communication
)
UPDATE communication c
SET delta_response = EXTRACT(EPOCH FROM (p.time_sent - p.previous_time)) - COALESCE(p.previous_delta_temp, 0)
FROM previous_times p
WHERE c.id = p.id;