
CREATE TABLE log2timeline(
	`id`			INT(11) NOT NULL AUTO_INCREMENT
	,`date`			DATE NOT NULL
	,`time`			TIME  NOT NULL
	,`timezone`		VARCHAR(32) NOT NULL
	,`MACB`			VARCHAR(8)  NOT NULL
	,`source`		VARCHAR(128) NOT NULL
	,`sourcetype`	VARCHAR(128)  NULL
	,`type`			VARCHAR(128)   NULL
	,`user`			VARCHAR(64)   NULL
	,`host`			VARCHAR(128)   NULL
	,`short`		VARCHAR(256)   NULL
	,`desc`			MEDIUMTEXT   NULL
	,`version`		INT(4)  NULL
	,`filename`     VARCHAR(256)  NULL
	,`inode`		BIGINT  NOT NULL
	,`notes`		VARCHAR(128)  NULL
	,`format`		VARCHAR(128)  NULL
	,`extra`		TEXT  NULL
	,PRIMARY KEY (Id)
);