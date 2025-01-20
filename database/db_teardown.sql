
TRUNCATE room_participation,
         communication,
         participant,
         room,
         platform,
         super_participant,
         communication_type
         CASCADE;

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
												(7, 'LINK');