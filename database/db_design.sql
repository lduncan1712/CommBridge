
/*
	Represents A Unique Location/Source For Data
*/
CREATE TABLE IF NOT EXISTS platform(
	id       SERIAL PRIMARY KEY,
	name     VARCHAR(50)
);

/*
	Stores A Person, Whose Ownership Links Multiple participants
*/
CREATE TABLE IF NOT EXISTS super_participant(
	id       SERIAL PRIMARY KEY,
	name     VARCHAR(100),
	gender   VARCHAR(1),
	family   BOOLEAN,
	contact  BOOLEAN DEFAULT FALSE
);

/*
	Represents A Communication Space With The Same Individuals Over Multiple Platforms
*/
CREATE TABLE IF NOT EXISTS super_room(
	id       SERIAL PRIMARY KEY,
	name     VARCHAR(1000),
	sp_list INT[]
);

/*
	Represents An Individual Account Involved Within Communication In A Platform

	IE: instagram_account_123
*/
CREATE TABLE IF NOT EXISTS participant(
	id           SERIAL PRIMARY KEY,
	name         VARCHAR(100),
	username     VARCHAR(100),
	nid          VARCHAR(100),
	sparticipant INT REFERENCES super_participant(id) ON DELETE CASCADE,
	platform     INT REFERENCES platform(id) ON DELETE CASCADE
);

/*
	A Single Location For Communication Within A Platform

	IE: 'Chat With Joe Smith', 'CP123 Group Chat'
*/
CREATE TABLE IF NOT EXISTS room(
	id           SERIAL PRIMARY KEY,
	name         VARCHAR(1000),
	platform     INT REFERENCES platform(id) ON DELETE CASCADE,
	sroom        INT REFERENCES super_room(id) ON DELETE CASCADE,
	p_list       INT[],
	sp_list      INT[]
);

/*
	A Marker Of Participants Within A Room
*/
CREATE TABLE IF NOT EXISTS room_participation(
	room         INT REFERENCES room(id) ON DELETE CASCADE,
	participant  INT REFERENCES participant(id) ON DELETE CASCADE,

	PRIMARY KEY (room, participant)
);

/*
	A Type Of Communication

	IE: 'call', 'message', 'IG reel', 'photo'
*/
CREATE TABLE IF NOT EXISTS communication_type(
	id       INT PRIMARY KEY,
	name     VARCHAR(100)
);

/*
	A Piece Of Individual Communication
*/
CREATE TABLE IF NOT EXISTS communication(
	id           SERIAL PRIMARY KEY, 
	nid          VARCHAR(100),  
	start        TIMESTAMP,   
	finish       TIMESTAMP,  
	content      VARCHAR(1000000),  
	link         VARCHAR(10000),   
	type         INT REFERENCES communication_type(id) ON DELETE CASCADE,  
	reply        INT REFERENCES communication(id) ON DELETE CASCADE,    
	platform     INT REFERENCES platform(id) ON DELETE CASCADE,    
	participant  INT REFERENCES participant(id) ON DELETE CASCADE,
	sparticipant INT,
	room         INT REFERENCES room(id) ON DELETE CASCADE,
	sroom        INT,
	m1_past      INT, 
	m2_next      INT, 
	m3_response  INT, 
	m4_weight    INT, 
	m5_turn      INT

);

CREATE TABLE IF NOT EXISTS communication_aggregate(
	day          DATE,
	room         INT,
	m1_weight    INT,
	m2_entropy   INT,
	m3_varience  INT

);





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