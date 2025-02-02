/*
    RATIONALE: When contacts are uploaded, linking super_participants between rooms
               it generates the possiblity of super_room; that is the union of all rooms
               whose participants are the same individuals

    QUERY: Creates sets of rooms, that either contain the same participants (intra platform), 
           or same super_participants (inter platform)
*/


-- Create A Temporary Column
ALTER TABLE room ADD COLUMN IF NOT EXISTS TEMP_PARTICIPANT_LIST int[];

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


--Create A Temporary Column
ALTER TABLE room ADD COLUMN IF NOT EXISTS TEMP_SUPER_PARTICIPANT_LIST int[];

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













-- Create A Temporary Columns
ALTER TABLE super_room ADD COLUMN IF NOT EXISTS TEMP_SUPER_PARTICIPANT_LIST int[];


-- Determine A List Of Repeated SuperParticipant Combinations
WITH valid_rooms AS (
    SELECT TEMP_SUPER_PARTICIPANT_LIST, 
           COUNT(*) AS room_count
    FROM room
    WHERE array_length(TEMP_SUPER_PARTICIPANT_LIST, 1) > 1          --More then 1 SuperParticipant
      AND array_position(TEMP_SUPER_PARTICIPANT_LIST, NULL) IS NULL --No Non SuperParticipants
    GROUP BY TEMP_SUPER_PARTICIPANT_LIST
    HAVING COUNT(*) >= 2 
),

-- Generate These Needed Super_rooms
inserted_super_rooms AS (
    INSERT INTO super_room (name, TEMP_SUPER_PARTICIPANT_LIST)
    SELECT 
        (SELECT string_agg(name, ' ' ORDER BY id) 
         FROM super_participant 
         WHERE id = ANY(vr.TEMP_SUPER_PARTICIPANT_LIST)), --labelling as list of names
        vr.TEMP_SUPER_PARTICIPANT_LIST
    FROM valid_rooms vr
    RETURNING id, TEMP_SUPER_PARTICIPANT_LIST
)


--Updating Rooms To Connect 
UPDATE room
SET super_room = isr.id
FROM inserted_super_rooms isr
WHERE room.TEMP_SUPER_PARTICIPANT_LIST = isr.TEMP_SUPER_PARTICIPANT_LIST;