WITH numbered_rows AS (
    SELECT
        c.time_sent,
        c.time_ended,
        c.communication_type,
        c.platform,
        sp_id AS participant,
        c.TEMP_SUPER_ROOM,
        c.room,
        c.id,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY sp_id) AS rn
    FROM
        communication c
    JOIN
        super_room sr ON c.temp_super_room = sr.id
    CROSS JOIN
        unnest(sr.temp_super_participant_list) AS sp_id
    WHERE
        c.communication_type = 1
        AND c.shared = TRUE
        AND sp_id != c.TEMP_SUPER_PARTICIPANT
)
INSERT INTO communication (
    time_sent,
    time_ended,
    communication_type,
    platform,
    TEMP_SUPER_PARTICIPANT,
    TEMP_SUPER_ROOM,
    room,
    reply
)
SELECT
    nr.time_sent + INTERVAL '5 seconds' + INTERVAL '0.1 second' * nr.rn, 
    nr.time_ended,
    nr.communication_type,
    nr.platform,
    nr.participant,
    nr.TEMP_SUPER_ROOM,
    nr.room,
    nr.id
FROM
    numbered_rows nr;