



-- First, drop tables with foreign key references
DROP TABLE IF EXISTS communication;
DROP TABLE IF EXISTS room_participation;
DROP TABLE IF EXISTS room;
DROP TABLE IF EXISTS participant;

-- Then drop tables without dependencies
DROP TABLE IF EXISTS communication_type;
DROP TABLE IF EXISTS super_room;
DROP TABLE IF EXISTS super_participant;
DROP TABLE IF EXISTS platform;




-- Speeds Up Deletion
TRUNCATE room_participation,
         communication,
         participant,
         room,
         platform,
         super_participant,
         communication_type
         CASCADE;


-- Readds Key Rows and Types
INSERT INTO communication(id, content) VALUES (-2, 'UNKNOWN (-2)'),
											  (-1, 'REMOVED (-1)');


INSERT INTO communication_type(id, name) VALUES (-1, 'UNAVAILABLE_MEDIA'),
												(0, 'MESSAGE'),
												(1, 'CALL'),
												(2, 'MEDIA'),
												(3, 'STICKER_GIF'),
												(4, 'NATIVE_MEDIA'),
												(5, 'REACTION'),
												(6, 'ALTER'), 
												(7, 'LINK'),
												(8, 'DELETED_NATIVE');