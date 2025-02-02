

WITH super_participant_communications AS (
    -- Calculate communications made by each super_participant
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
super_room_communications AS (
    -- Calculate total communications within each super_room
    SELECT 
        sr.id AS super_room_id,
        COUNT(c.id) AS total_communications
    FROM super_room sr
    JOIN room r ON r.super_room = sr.id
    LEFT JOIN communication c ON c.room = r.id
    GROUP BY sr.id
),
fully_contributing_super_rooms AS (
    -- Identify super_rooms where one participant contributes all communications
    SELECT 
        spc.super_room_id
    FROM super_participant_communications spc
    JOIN super_room_communications src ON spc.super_room_id = src.super_room_id
    GROUP BY spc.super_room_id, src.total_communications
    HAVING MAX(spc.participant_communications) = src.total_communications -- One participant contributes all communications
       AND COUNT(spc.participant_communications) = 1 -- Ensure only one participant contributes (no ties)
)
-- Delete fully contributing super_rooms and cascade to related data
DELETE FROM super_room sr
WHERE sr.id IN (
    SELECT fcsr.super_room_id
    FROM fully_contributing_super_rooms fcsr
);


DELETE FROM super_participant sp
WHERE NOT EXISTS (
    SELECT 1
    FROM participant p
    JOIN room_participation rp ON rp.participant = p.id -- Check if participant is part of any room
    WHERE p.super_participant = sp.id
);





