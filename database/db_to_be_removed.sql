SELECT 
    p.id AS participant_id,
    p.name AS participant_name,
    p.username,
    COUNT(DISTINCT c.id) AS total_communications,
    COUNT(DISTINCT rp_others.participant) AS distinct_participants_in_rooms,
    COUNT(DISTINCT c.participant) AS distinct_participants_with_communications,
    COUNT(DISTINCT sp.id) AS unique_super_participants_with_communications
FROM 
    participant p
JOIN 
    room_participation rp ON p.id = rp.participant
LEFT JOIN 
    communication c ON rp.room = c.room
LEFT JOIN 
    room_participation rp_others ON rp.room = rp_others.room
LEFT JOIN 
    participant p_comm ON c.participant = p_comm.id
LEFT JOIN 
    super_participant sp ON p_comm.super_participant = sp.id
GROUP BY 
    p.id, p.name, p.username
ORDER BY 
    total_communications DESC;