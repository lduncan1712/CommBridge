/*
    RATIONALE: several bits of information remains unknown depending on the platform
               for example participation within a call, unknown time_sent,  et
*/




-- Estimate call is mutual when larger then __ seconds
UPDATE communication
SET shared = EXTRACT(EPOCH FROM (time_ended - time_sent)) > 10
WHERE communication_type = 1;

-- For Calls Over Length, Shrink (mistaken chat open)
UPDATE communication
SET time_ended = time_sent + INTERVAL '5 hours'
WHERE time_ended - time_sent > INTERVAL '5 hours';


-- Set Endtime To Startime for other
UPDATE communication
SET time_ended = time_sent
WHERE (communication_type = 1 and shared = FALSE) or communication_type != 1;


-- Set Communications To Next Time_sent by participant when not known
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







