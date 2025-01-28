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