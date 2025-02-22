/*
    RATIONALE: several bits of information remains unknown depending on the platform
               for example participation within a call, unknown start,  et
*/




-- Estimate call is mutual when larger then __ seconds
UPDATE communication
SET finish = start
WHERE
EXTRACT(EPOCH FROM (finish - start)) <= 10
or finish is NULL;

-- For Calls Over Length, Shrink (mistaken chat open)
UPDATE communication
SET finish = start + INTERVAL '5 hours'
WHERE finish - start > INTERVAL '5 hours';

-- Set Communications To Next start by participant when not known
UPDATE communication c1
SET start = (
    SELECT c2.start
    FROM communication c2
    WHERE c2.room = c1.room
    AND c2.participant = c1.participant
    AND c2.start IS NOT NULL
    AND c2.id > c1.id
    ORDER BY c2.start
    LIMIT 1
)
WHERE c1.start IS NULL;


UPDATE communication
SET day = DATE(start);







