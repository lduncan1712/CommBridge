


--Assume Shared Status In Call Communication Types If Not Known
-- UPDATE communication
-- SET shared = TRUE
-- WHERE communication_type = 1
--   AND shared IS NULL
--   AND EXTRACT(EPOCH FROM (time_ended - time_sent)) > 10; -- over time


--Assume Communication without date, was sent at time of next message by that individual






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



