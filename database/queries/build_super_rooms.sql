/*
    RATIONALE: Assuming Super_Participants have been established, now needs
                to generate super_rooms, representing unique sets of super_participants
*/


-- Create A Temporary Column
ALTER TABLE room ADD COLUMN IF NOT EXISTS TEMP_PARTICIPANT_LIST int[];
ALTER TABLE room ADD COLUMN IF NOT EXISTS TEMP_SUPER_PARTICIPANT_LIST int[];
ALTER TABLE super_room ADD COLUMN IF NOT EXISTS TEMP_SUPER_PARTICIPANT_LIST int[];



-- Fill The Temporary Column With A List Of Participants In Each Room
UPDATE room r
SET TEMP_PARTICIPANT_LIST = subquery.participant_array
FROM (
    SELECT rp.room,
            ARRAY_AGG(DISTINCT rp.participant ORDER BY rp.participant) AS participant_array
    FROM room_participation rp
    GROUP BY rp.room
) AS subquery
WHERE r.id = subquery.room;

-- Fill The Temporary Column With A List Of SuperParticipants (If Any) Linked To Participants
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



WITH valid_rooms AS (
    SELECT TEMP_SUPER_PARTICIPANT_LIST, 
           COUNT(*) AS room_count,
           ARRAY_AGG(platform) AS platforms 
    FROM room
    WHERE array_length(TEMP_SUPER_PARTICIPANT_LIST, 1) > 1 -- More than 1 SuperParticipant
    GROUP BY TEMP_SUPER_PARTICIPANT_LIST
),


inserted_super_rooms AS (
    INSERT INTO super_room (name, TEMP_SUPER_PARTICIPANT_LIST)
    SELECT 
        CASE 
            -- If the combination occurs in only one platform, append platform name
            WHEN array_length(vr.platforms, 1) = 1 THEN 
                (SELECT string_agg(sp.name, ' ' ORDER BY sp.id) 
                 FROM super_participant sp 
                 WHERE sp.id = ANY(vr.TEMP_SUPER_PARTICIPANT_LIST)) || ' (' || 
                (SELECT name FROM platform WHERE id = vr.platforms[1]) || ')'
            -- Otherwise, just use the names of the super participants
            ELSE 
                (SELECT string_agg(sp.name, ' ' ORDER BY sp.id) 
                 FROM super_participant sp 
                 WHERE sp.id = ANY(vr.TEMP_SUPER_PARTICIPANT_LIST))
        END AS name,
        vr.TEMP_SUPER_PARTICIPANT_LIST
    FROM valid_rooms vr
    RETURNING id, TEMP_SUPER_PARTICIPANT_LIST
)

UPDATE room r
SET super_room = isr.id
FROM inserted_super_rooms isr
WHERE r.TEMP_SUPER_PARTICIPANT_LIST = isr.TEMP_SUPER_PARTICIPANT_LIST;










-- -- Determine A List Of Repeated SuperParticipant Combinations
-- WITH valid_rooms AS (
--     SELECT TEMP_SUPER_PARTICIPANT_LIST, 
--            COUNT(*) AS room_count
--     FROM room
--     WHERE array_length(TEMP_SUPER_PARTICIPANT_LIST, 1) > 1      
--     GROUP BY TEMP_SUPER_PARTICIPANT_LIST
--     HAVING COUNT(*) >= 2 
-- ),

-- -- Generate These Needed Super_rooms
-- inserted_super_rooms AS (
--     INSERT INTO super_room (name, TEMP_SUPER_PARTICIPANT_LIST)
--     SELECT 
--         (SELECT string_agg(name, ' ' ORDER BY id) 
--          FROM super_participant 
--          WHERE id = ANY(vr.TEMP_SUPER_PARTICIPANT_LIST)), 
--         vr.TEMP_SUPER_PARTICIPANT_LIST
--     FROM valid_rooms vr
--     RETURNING id, TEMP_SUPER_PARTICIPANT_LIST
-- )


-- --Updating Rooms To Connect 
-- UPDATE room
-- SET super_room = isr.id
-- FROM inserted_super_rooms isr
-- WHERE room.TEMP_SUPER_PARTICIPANT_LIST = isr.TEMP_SUPER_PARTICIPANT_LIST;