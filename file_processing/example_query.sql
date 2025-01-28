
SELECT 
    pp.name AS participant_name,
    pp.native_id,
    r.name AS room_name_with_fewest_participants,
	p.name
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