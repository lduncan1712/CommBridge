WITH updated_communication AS (
    SELECT 
        id,
        communication_type,
        content,
        time_sent,
        time_ended,
        -- Calculate weights for different conditions
        CASE
            WHEN communication_type = 0 THEN LENGTH(content)  -- COMM_MESSAGE
            WHEN communication_type = 1 THEN GREATEST(2 * EXTRACT(EPOCH FROM (time_ended - time_sent)), 100)  -- COMM_CALL
            WHEN communication_type = 1 AND weight > 50000 THEN 120 * 60  -- COMM_CALL, outlier handling
            WHEN communication_type = 3 THEN 10  -- COMM_STICKER_GIF
            WHEN communication_type = 5 THEN 10  -- COMM_REACTION
            WHEN communication_type = 2 THEN 100  -- COMM_MEDIA
            WHEN communication_type = 4 THEN 100  -- COMM_NATIVE_MEDIA
            WHEN communication_type = 8 THEN 100  -- COMM_DELETED_NATIVE
            WHEN communication_type = 7 THEN 100  -- COMM_LINK
            WHEN communication_type = 6 THEN 100  -- COMM_ALTER
            WHEN communication_type = -1 THEN (SELECT AVG(weight) FROM communication WHERE communication_type = 0)  -- COMM_REMOVED
            ELSE NULL
        END AS calculated_weight,
        -- Adjust time_ended for outliers
        CASE 
            WHEN communication_type = 1 AND weight > 50000 THEN time_sent + INTERVAL '7200 seconds'
            ELSE time_ended
        END AS adjusted_time_ended
    FROM communication
)
UPDATE communication
SET 
    weight = updated_communication.calculated_weight,
    time_ended = updated_communication.adjusted_time_ended
FROM updated_communication
WHERE communication.id = updated_communication.id;