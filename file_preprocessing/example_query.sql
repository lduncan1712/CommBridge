-- PRINTOUT OF PARTICIPANTS (USED TO CONTRUCT CONTACTS)
SELECT 
	pp.id,
	p.name,
    pp.name AS participant_name,
	pp.super_participant,
	pp.username As user_name,
    pp.native_id,
    RIGHT(r.name,50) AS room_name_with_fewest_participants

FROM 
    participant pp
INNER JOIN 
    platform p ON p.id = pp.platform
INNER JOIN 
    room_participation rp ON rp.participant = pp.id
INNER JOIN 
    room r ON r.id = rp.room
WHERE 
    rp.room = (
        SELECT room
        FROM room_participation
        WHERE participant = pp.id
        GROUP BY room
        ORDER BY COUNT(participant) ASC
        LIMIT 1
    )
ORDER BY 
    pp.name;


-- ---------------------------------------------------

-- Identifies Individuals To Be Removed


SELECT p.id, p.name, p.username, p.native_id, p.platform, p.super_participant,
	   CASE 
           WHEN COUNT(DISTINCT CASE WHEN c.participant IS NOT NULL THEN rp.participant END) != 1 
           THEN 'Only One Participant Makes Communication'
           ELSE 'Multiple Participants Make Communication'
       END AS communication_participation_status,
       COUNT(DISTINCT rp.room) AS room_count,
       COUNT(c.id) AS communication_count,
       r.name AS room_path  -- Room path
       
FROM participant p
LEFT JOIN room_participation rp ON p.id = rp.participant
LEFT JOIN communication c ON p.id = c.participant
LEFT JOIN room_participation rp2 ON rp.room = rp2.room  -- Join again to count participants in the room
LEFT JOIN room r ON rp.room = r.id  -- Join the room table to get the path
WHERE p.super_participant IS NULL
GROUP BY p.id, p.name, p.username, p.native_id, p.platform, r.name
HAVING COUNT(DISTINCT rp.room) = 1                  -- Participant must be in exactly 1 room
   AND COUNT(c.id) < 10                            -- Less than 10 communications
   AND COUNT(DISTINCT rp2.participant) = 2   




DELETE FROM participant
WHERE id IN (
    SELECT p.id  -- The subquery to get the participant IDs
    FROM participant p
    LEFT JOIN room_participation rp ON p.id = rp.participant
    LEFT JOIN communication c ON p.id = c.participant
    LEFT JOIN room_participation rp2 ON rp.room = rp2.room  -- Join again to count participants in the room
    LEFT JOIN room r ON rp.room = r.id  -- Join the room table to get the path
    WHERE p.super_participant IS NULL
    GROUP BY p.id
    HAVING COUNT(DISTINCT rp.room) = 1                  -- Participant must be in exactly 1 room
       AND COUNT(c.id) < 10                            -- Less than 10 communications
       AND COUNT(DISTINCT rp2.participant) = 2         -- The room must have exactly 2 participants
       AND COUNT(DISTINCT CASE WHEN c.id IS NOT NULL THEN rp.participant END) = 1  -- Only one participant made communication
);