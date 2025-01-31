
UPDATE room r
                SET participant_list = subquery.participant_array
                FROM (
                    SELECT rp.room,
                    ARRAY_AGG(DISTINCT rp.participant ORDER BY rp.participant) AS participant_array
                    FROM room_participation rp
                    GROUP BY rp.room
                ) AS subquery
                WHERE r.id = subquery.room;