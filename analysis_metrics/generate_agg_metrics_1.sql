WITH participant_weights AS (
    SELECT
        DATE(time_sent) AS day,
        room,
        participant,
        SUM(weight) AS total_weight
    FROM
        communication
    WHERE
        weight IS NOT NULL
    GROUP BY
        DATE(time_sent), room, participant
),
room_day_totals AS (
    SELECT
        day,
        room,
        SUM(total_weight) AS total_weight_for_room_day
    FROM
        participant_weights
    GROUP BY
        day, room
),
entropy_calculation AS (
    SELECT
        pw.day,
        pw.room,
        -SUM(
            (pw.total_weight::NUMERIC / NULLIF(rdt.total_weight_for_room_day::NUMERIC, 0)) *
            LOG(2::NUMERIC, pw.total_weight::NUMERIC / NULLIF(rdt.total_weight_for_room_day::NUMERIC, 0))
        ) AS entropy
    FROM
        participant_weights pw
    JOIN
        room_day_totals rdt
    ON
        pw.day = rdt.day AND pw.room = rdt.room
    WHERE rdt.total_weight_for_room_day > 0 -- Exclude rooms with zero totals.
    GROUP BY
        pw.day, pw.room
)
INSERT INTO communication_aggregate (day, room, am1)
SELECT 
    ec.day, 
    ec.room, 
    ec.entropy  -- Keep entropy as FLOAT or NUMERIC.
FROM 
    entropy_calculation ec;
