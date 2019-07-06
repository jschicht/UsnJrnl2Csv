
CREATE TABLE bodyfile(
	`id`				INT(11) NOT NULL AUTO_INCREMENT
	,`MD5`				VARCHAR(32) NOT NULL
	,`name`				TEXT  NOT NULL
	,`inode`			BIGINT NOT NULL
	,`mode_as_string`	MEDIUMTEXT  NOT NULL
	,`UID`				VARCHAR(64) NOT NULL
	,`GID`				VARCHAR(64)  NULL
	,`size`				BIGINT  NULL
	,`atime`			DATETIME(6) NOT  NULL
	,`mtime`			DATETIME(6) NOT  NULL
	,`ctime`			DATETIME(6) NOT  NULL
	,`crtime`			DATETIME(6) NOT  NULL
	,PRIMARY KEY (Id)
);