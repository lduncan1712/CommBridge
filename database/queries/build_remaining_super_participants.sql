/*
    RATIONALE: Participants Not Referenced In Contact List, Are Confirmed
               To Represent Unique Individuals, And As Such Need To Be Represented
               As SUPER_PARTICIPANTs

    QUERY: Generate a new SUPER_PARTICIPANT row for every participant row lacking one,
           and Link to unique participant row

*/



ALTER TABLE super_participant ADD COLUMN IF NOT EXISTS TEMP_PARTICIPANT_ID INT;


WITH new_super_participants AS (
    INSERT INTO super_participant (TEMP_PARTICIPANT_ID, name, gender, family, manually_added)
    SELECT p.id, p.name, NULL AS gender, FALSE AS family, TRUE AS manually_added
    FROM participant p
    WHERE p.super_participant IS NULL
    RETURNING id, TEMP_PARTICIPANT_ID
)


UPDATE participant p
SET super_participant = nsp.id
FROM new_super_participants nsp
WHERE p.id = nsp.TEMP_PARTICIPANT_ID AND p.super_participant IS NULL;


