CREATE DATABASE socialdb


/*
	Represents A Unique Location/Source For Data

	IE: 'Instagram', 'Discord', 'imessage'
*/
CREATE TABLE IF NOT EXISTS platform(
	id SERIAL PRIMARY KEY,
	name VARCHAR(50)
);

/*
	Represents A Person Who Can Participate In Communication Within Multiple Platforms, Rooms
*/
CREATE TABLE IF NOT EXISTS super_participant(
	id SERIAL PRIMARY KEY,
	name VARCHAR(100),
	gender VARCHAR(1),
	family BOOLEAN
);

/*
	Represents A Communication Space With The Same Individuals Over Multiple Platforms
*/
CREATE TABLE IF NOT EXISTS super_room(
	id SERIAL PRIMARY KEY,
	name VARCHAR(1000),
	super_participant_group INT[]
);




/*
	Represents An Individual Account Involved Within Communication In A Platform

	IE: instagram_account_123
*/
CREATE TABLE IF NOT EXISTS participant(
	id SERIAL PRIMARY KEY,
	name VARCHAR(100),
	username VARCHAR(100),
	native_id VARCHAR(100),
	super_participant INT REFERENCES super_participant(id) ON DELETE CASCADE,
	platform INT REFERENCES platform(id) ON DELETE CASCADE
);

/*
	A Single Location For Communication Within A Platform

	IE: 'Chat With Joe Smith', 'CP123 Group Chat'
*/
CREATE TABLE IF NOT EXISTS room(
	id SERIAL PRIMARY KEY,
	name VARCHAR(1000),
	platform INT REFERENCES platform(id) ON DELETE CASCADE,
	super_room INT REFERENCES super_room(id) ON DELETE CASCADE,
	room_creation_date TIMESTAMP,
	participant_list INT[],
	super_participant_list INT[]
);

/*
	A Marker Of Participants Within A Room
*/
CREATE TABLE room_participation(
	room INT REFERENCES room(id) ON DELETE CASCADE,
	participant INT REFERENCES participant(id) ON DELETE CASCADE,
	date_of_entry TIMESTAMP,
	PRIMARY KEY (room, participant)
);

/*
	A Type Of Communication

	IE: 'call', 'message', 'IG reel', 'photo'
*/
CREATE TABLE IF NOT EXISTS communication_type(
	id INT PRIMARY KEY,
	name VARCHAR(100)
);

/*
	A Piece Of Individual Communication
*/
CREATE TABLE IF NOT EXISTS communication(
	id SERIAL PRIMARY KEY,
	native_id VARCHAR(100),  -- how its internally referenced
	time_sent TIMESTAMP,     -- when sent
	time_ended TIMESTAMP,    -- if call, when ended
	content VARCHAR(1000000),  --actual content
	location VARCHAR(10000),   -- link to media or website mentioned

	communication_type INT REFERENCES communication_type(id) ON DELETE CASCADE,  -- the type of media this is
	reply INT REFERENCES communication(id) ON DELETE CASCADE,    -- any communication this is responding to
	platform INT REFERENCES platform(id) ON DELETE CASCADE,      
	participant INT REFERENCES participant(id) ON DELETE CASCADE,
	room INT REFERENCES room(id) ON DELETE CASCADE,




	weight INT

);



-- CREATE TABLE IF NOT EXISTS super_room_daily_aggregate(
-- 	day DATE,

-- )















INSERT INTO communication(id, content) VALUES (-2, 'UNKNOWN (-2)'),  --case when comm unknown (for reply)
											  (-1, 'REMOVED (-1)');  --case when comm removed (for reply)

INSERT INTO communication_type(id, name) VALUES (-1, 'UNAVAILABLE_MEDIA'), --case when item is removed
												(0, 'MESSAGE'),            -- text/emoji based message
												(1, 'CALL'),               -- call communication
												(2, 'MEDIA'),              -- photos or videos
												(3, 'STICKER_GIF'),        -- stickers or gifs
												(4, 'NATIVE_MEDIA'),       -- local (IE: IG reels)
												(5, 'REACTION'),           -- emoji reaction to communication
												(6, 'ALTER'),              -- channel based change
												(7, 'LINK'),               -- a link to a website
												(8, 'DELETED_NATIVE');
												   
