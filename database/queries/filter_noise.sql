/*
    RATIONALE: Assuming Some communication occurs from one directional spam (IE: spam calls),
                providing no communicative value, we remove as well as rooms
*/

-- Determine participant participation
WITH super_participant_communications AS (
    SELECT 
        sp.id AS super_participant_id,
        sp.name AS super_participant_name,
        sr.id AS super_room_id,
        COUNT(c.id) AS participant_communications
    FROM super_participant sp
    JOIN participant p ON p.super_participant = sp.id
    JOIN communication c ON c.participant = p.id
    JOIN room r ON c.room = r.id
    JOIN super_room sr ON r.super_room = sr.id
    GROUP BY sp.id, sp.name, sr.id
),

-- Determine participant within rooms
super_room_communications AS (
    SELECT 
        sr.id AS super_room_id,
        COUNT(c.id) AS total_communications
    FROM super_room sr
    JOIN room r ON r.super_room = sr.id
    LEFT JOIN communication c ON c.room = r.id
    GROUP BY sr.id
),

--Generate Fully One Sided Rooms
fully_contributing_super_rooms AS (
    SELECT 
        spc.super_room_id
    FROM super_participant_communications spc
    JOIN super_room_communications src ON spc.super_room_id = src.super_room_id
    GROUP BY spc.super_room_id, src.total_communications
    HAVING MAX(spc.participant_communications) = src.total_communications 
       AND COUNT(spc.participant_communications) = 1 
)

--Remove one directional rooms
DELETE FROM super_room sr
WHERE sr.id IN (
    SELECT fcsr.super_room_id
    FROM fully_contributing_super_rooms fcsr
);


--Remove super partiicpant where all whoms rooms are removed
DELETE FROM super_participant sp
WHERE NOT EXISTS (
    SELECT 1
    FROM participant p
    JOIN room_participation rp ON rp.participant = p.id 
    WHERE p.super_participant = sp.id
);





