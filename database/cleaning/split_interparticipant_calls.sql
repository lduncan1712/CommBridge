WITH numbered_rows AS (
    SELECT
        c.start,
        c.finish,
        c.type,
        c.platform,
        sp_id AS participant,
        c.sroom,
        c.room,
        c.id,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY sp_id) AS rn
    FROM
        communication c
    JOIN
        super_room sr ON c.sroom = sr.id
    CROSS JOIN
        unnest(sr.sp_list) AS sp_id
    WHERE
        c.type = 1
        AND c.start != c.finish
        AND sp_id != c.sparticipant
)
INSERT INTO communication (
    start,
    finish,
    type,
    platform,
    sparticipant,
    sroom,
    room,
    reply
)
SELECT
    nr.start + INTERVAL '5 seconds' + INTERVAL '0.1 second' * nr.rn, 
    nr.finish,
    nr.type,
    nr.platform,
    nr.participant,
    nr.sroom,
    nr.room,
    nr.id
FROM
    numbered_rows nr;