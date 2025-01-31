DELETE FROM participant
            WHERE id IN (
                SELECT participant_id
            FROM (
                SELECT 
            p.id AS participant_id,
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
            p.id
        HAVING 
            COUNT(DISTINCT sp.id) = 0
        ) AS subquery
        );


DELETE FROM room
WHERE id IN (
    SELECT r.id
    FROM room r
    LEFT JOIN communication c ON r.id = c.room
    GROUP BY r.id
    HAVING COUNT(c.id) = 0
);


