/*
    RATIONALE: After generating all super_participants, we now have the possibility
               of super rooms, that is multiple rooms shared by the same super_participants
               most often between platforms
*/


-- Aggregate List Of Rooms Participants
UPDATE room r
SET p_list = subquery.participant_array
FROM (
    SELECT rp.room,
            ARRAY_AGG(DISTINCT rp.participant ORDER BY rp.participant) AS participant_array
    FROM room_participation rp
    GROUP BY rp.room
) AS subquery
WHERE r.id = subquery.room;

-- Add List Of Super Participants
UPDATE room r
SET p_list = subquery.participant_array,
    sp_list = subquery.super_participant_array
FROM (
    SELECT 
        rp.room,
        ARRAY_AGG(DISTINCT rp.participant ORDER BY rp.participant) AS participant_array,
        ARRAY_AGG(DISTINCT p.sparticipant ORDER BY p.sparticipant) AS super_participant_array
    FROM room_participation rp
    JOIN participant p ON rp.participant = p.id
    GROUP BY rp.room
) AS subquery
WHERE r.id = subquery.room;


-- Determine Which Room Sets To Amalgamate Into Super Rooms
WITH valid_rooms AS (
    SELECT sp_list, 
           COUNT(*) AS room_count,
           ARRAY_AGG(platform) AS platforms 
    FROM room
    WHERE array_length(sp_list, 1) > 1 -- More than 1 SuperParticipant
    GROUP BY sp_list
),


-- Generate The Super Rooms
inserted_super_rooms AS (
    INSERT INTO super_room (name, sp_list)
    SELECT 
        CASE 
            -- Name Super_Room From Single Platform
            WHEN array_length(vr.platforms, 1) = 1 THEN 
                (SELECT string_agg(sp.name, ' ' ORDER BY sp.id) 
                 FROM super_participant sp 
                 WHERE sp.id = ANY(vr.sp_list)) || ' (' || 
                (SELECT name FROM platform WHERE id = vr.platforms[1]) || ')'

            -- Shared Platform, Use Super_Participant Names
            ELSE 
                (SELECT string_agg(sp.name, ' ' ORDER BY sp.id) 
                 FROM super_participant sp 
                 WHERE sp.id = ANY(vr.sp_list))
        END AS name,
        vr.sp_list
    FROM valid_rooms vr
    RETURNING id, sp_list
)

-- Update References
UPDATE room r
SET sroom = isr.id
FROM inserted_super_rooms isr
WHERE r.sp_list = isr.sp_list;




-- -- Reference SuperRooms within communication
UPDATE communication c
SET sroom = r.sroom
FROM room r
WHERE c.room = r.id;

-- Reference Super participant within communication
UPDATE communication c
SET sparticipant = r.sparticipant
FROM participant r
WHERE c.participant = r.id;