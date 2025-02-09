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



-- Break Shared Communication (IE: Call) Into Portions (SUPER_ROOM, SUPER_PARTICIPANT)
INSERT INTO communication (
    time_sent,
    time_ended,
    communication_type,
    platform,
    TEMP_SUPER_PARTICIPANT,
    TEMP_SUPER_ROOM,
    room,
    reply
)
SELECT
    c.time_sent + INTERVAL '1 seconds',
    c.time_ended,
    c.communication_type,
    c.platform,
    sp_id AS participant,
    c.TEMP_SUPER_ROOM,
    c.room,
    c.id
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







