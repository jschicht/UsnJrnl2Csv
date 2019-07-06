LOAD DATA INFILE '__PathToCsv__' IGNORE
INTO TABLE bodyfile 
CHARACTER SET 'latin1' 
COLUMNS TERMINATED BY '__Separator__'
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@MD5, @name, @inode, @mode_as_string, @UID, @GID, @size, @atime, @mtime, @ctime, @crtime)
SET
MD5 = nullif(@MD5,''),
`name` = nullif(@name,''),
inode = nullif(@inode,''),
mode_as_string = nullif(@mode_as_string,''),
UID = nullif(@UID,''),
GID = nullif(@GID,''),
`size` = nullif(@size,''),
atime = STR_TO_DATE(@atime, '__TimestampTransformationSyntax__'),
mtime = STR_TO_DATE(@mtime, '__TimestampTransformationSyntax__'),
ctime = STR_TO_DATE(@ctime, '__TimestampTransformationSyntax__'),
crtime = STR_TO_DATE(@crtime, '__TimestampTransformationSyntax__')
;

