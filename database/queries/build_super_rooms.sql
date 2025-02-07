/*
    RATIONALE: After generating all super_participants, we now have the possibility
               of super rooms, that is multiple rooms shared by the same super_participants
               most often between platforms
*/


ALTER TABLE room ADD COLUMN IF NOT EXISTS TEMP_PARTICIPANT_LIST int[];
ALTER TABLE room ADD COLUMN IF NOT EXISTS TEMP_SUPER_PARTICIPANT_LIST int[];
ALTER TABLE super_room ADD COLUMN IF NOT EXISTS TEMP_SUPER_PARTICIPANT_LIST int[];

ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_SUPER_ROOM INT;
ALTER TABLE communication ADD COLUMN IF NOT EXISTS TEMP_SUPER_PARTICIPANT INT;

-- Aggregate List Of Rooms Participants
UPDATE room r
SET TEMP_PARTICIPANT_LIST = subquery.participant_array
FROM (
    SELECT rp.room,
            ARRAY_AGG(DISTINCT rp.participant ORDER BY rp.participant) AS participant_array
    FROM room_participation rp
    GROUP BY rp.room
) AS subquery
WHERE r.id = subquery.room;

-- Add List Of Super Participants
UPDATE room r
SET participant_list = subquery.participant_array,
    TEMP_SUPER_PARTICIPANT_LIST = subquery.super_participant_array
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


-- Determine Which Room Sets To Amalgamate Into Super Rooms
WITH valid_rooms AS (
    SELECT TEMP_SUPER_PARTICIPANT_LIST, 
           COUNT(*) AS room_count,
           ARRAY_AGG(platform) AS platforms 
    FROM room
    WHERE array_length(TEMP_SUPER_PARTICIPANT_LIST, 1) > 1 -- More than 1 SuperParticipant
    GROUP BY TEMP_SUPER_PARTICIPANT_LIST
),


-- Generate The Super Rooms
inserted_super_rooms AS (
    INSERT INTO super_room (name, TEMP_SUPER_PARTICIPANT_LIST)
    SELECT 
        CASE 
            -- Name Super_Room From Single Platform
            WHEN array_length(vr.platforms, 1) = 1 THEN 
                (SELECT string_agg(sp.name, ' ' ORDER BY sp.id) 
                 FROM super_participant sp 
                 WHERE sp.id = ANY(vr.TEMP_SUPER_PARTICIPANT_LIST)) || ' (' || 
                (SELECT name FROM platform WHERE id = vr.platforms[1]) || ')'

            -- Shared Platform, Use Super_Participant Names
            ELSE 
                (SELECT string_agg(sp.name, ' ' ORDER BY sp.id) 
                 FROM super_participant sp 
                 WHERE sp.id = ANY(vr.TEMP_SUPER_PARTICIPANT_LIST))
        END AS name,
        vr.TEMP_SUPER_PARTICIPANT_LIST
    FROM valid_rooms vr
    RETURNING id, TEMP_SUPER_PARTICIPANT_LIST
)

-- Update References
UPDATE room r
SET super_room = isr.id
FROM inserted_super_rooms isr
WHERE r.TEMP_SUPER_PARTICIPANT_LIST = isr.TEMP_SUPER_PARTICIPANT_LIST;




-- -- Reference SuperRooms within communication
UPDATE communication c
SET TEMP_SUPER_ROOM = r.super_room
FROM room r
WHERE c.room = r.id;

-- Reference Super participant within communication
UPDATE communication c
SET TEMP_SUPER_PARTICIPANT = r.super_participant
FROM participant r
WHERE c.participant = r.id;