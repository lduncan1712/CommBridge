
UPDATE room r
SET 
    participant_list = subquery.participant_array,
    super_participant_list = subquery.super_participant_array
FROM (
    SELECT 
        rp.room,
        ARRAY_AGG(DISTINCT rp.participant ORDER BY rp.participant) AS participant_array,
        ARRAY_AGG(DISTINCT p.super_participant ORDER BY p.super_participant) AS super_participant_array
    FROM room_participation rp
    JOIN participant p ON rp.participant = p.id
    GROUP BY rp.room
) AS subquery
WHERE r.id = subquery.room;