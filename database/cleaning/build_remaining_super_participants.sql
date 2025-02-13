/*
    RATIONALE: After running "build_super" we will have generated super_participants
               corrasponding to those in the contact list, this function completes the 
               process for all others
*/

ALTER TABLE super_participant ADD COLUMN IF NOT EXISTS TEMP_PARTICIPANT_ID INT;


-- Generates New Super_Participants
WITH new_super_participants AS (
    INSERT INTO super_participant (TEMP_PARTICIPANT_ID, name, gender, family, manually_added)
    SELECT p.id, 
           p.name, 
           NULL AS gender, 
           FALSE AS family, 
           FALSE AS manually_added
    FROM participant p
    WHERE p.super_participant IS NULL
    RETURNING id, TEMP_PARTICIPANT_ID
)
UPDATE participant p
SET super_participant = nsp.id
FROM new_super_participants nsp
WHERE p.id = nsp.TEMP_PARTICIPANT_ID AND p.super_participant IS NULL;