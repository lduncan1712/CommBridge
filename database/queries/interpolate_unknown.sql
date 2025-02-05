




-- Estimate a shared call is more then 10 seconds
UPDATE communication
SET shared = EXTRACT(EPOCH FROM (time_ended - time_sent)) > 10
WHERE communication_type = 1;

-- Fill Endtime to be start time when not shared (as no communication value)
UPDATE communication
SET time_ended = time_sent
WHERE communication_type = 1 and shared = FALSE;


-- modify communications to reflect next known date, if not known
UPDATE communication c1
SET time_sent = (
    SELECT c2.time_sent
    FROM communication c2
    WHERE c2.room = c1.room
    AND c2.participant = c1.participant
    AND c2.time_sent IS NOT NULL
    AND c2.id > c1.id
    ORDER BY c2.time_sent
    LIMIT 1
)
WHERE c1.time_sent IS NULL;



