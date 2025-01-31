

WITH valid_rooms AS (
    SELECT super_participant_list, 
           COUNT(*) AS room_count
    FROM room
    WHERE array_length(super_participant_list, 1) > 1
      AND array_position(super_participant_list, NULL) IS NULL  -- Ensures no NULL values in super_participant_list
    GROUP BY super_participant_list
    HAVING COUNT(*) >= 2
),
inserted_super_rooms AS (
    INSERT INTO super_room (name, super_participant_group)
    SELECT 
        (SELECT string_agg(name, ' ' ORDER BY id)
         FROM super_participant 
         WHERE id = ANY(vr.super_participant_list)),
        vr.super_participant_list
    FROM valid_rooms vr
    RETURNING id, super_participant_group
)
UPDATE room
SET super_room = isr.id
FROM inserted_super_rooms isr
WHERE room.super_participant_list = isr.super_participant_group
  AND array_position(room.super_participant_list, NULL) IS NULL;  -- Ensures no NULL values in super_participant_list

  