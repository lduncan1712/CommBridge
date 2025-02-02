/*
    RATIONALE: Certain Information depending on the file_type is unknown, 
               We seek to interpolate these values

    QUERY: (*time not stored in reaction):
           (*time not stored in deleted)
           (mutual participant in call not known):

*/



-- Marks Calls
UPDATE communication
SET shared = TRUE
WHERE time_sent = 1 and
EXTRACT(EPOCH FROM (time_ended - time_sent)) > 10;






UPDATE communication c1
SET time_sent = (
    SELECT c2.time_sent
    FROM communication c2
    WHERE c2.room = c1.room
    AND c2.participant = c1.participant
    AND c2.time_sent IS NOT NULL
    AND c2.time_sent > c1.time_sent
    ORDER BY c2.time_sent
    LIMIT 1
)
WHERE c1.time_sent IS NULL;



