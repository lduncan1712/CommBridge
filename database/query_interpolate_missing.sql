UPDATE communication
SET shared = TRUE
WHERE EXTRACT(EPOCH FROM (time_ended - time_sent)) > 10;


