

-- Speeds Up Deletion
TRUNCATE room_participation,
         communication,
         participant,
         room,
         platform,
         super_participant,
         communication_type
         CASCADE;

DROP TABLE IF EXISTS communication;
DROP TABLE IF EXISTS room_participation;
DROP TABLE IF EXISTS room;
DROP TABLE IF EXISTS participant;

-- Then drop tables without dependencies
DROP TABLE IF EXISTS communication_type;
DROP TABLE IF EXISTS super_room;
DROP TABLE IF EXISTS super_participant;
DROP TABLE IF EXISTS platform;

DROP TABLE IF EXISTS communication_aggregate;
