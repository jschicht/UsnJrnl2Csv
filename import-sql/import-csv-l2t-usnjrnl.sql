LOAD DATA INFILE '__PathToCsv__' IGNORE
INTO TABLE log2timeline
CHARACTER SET 'latin1' 
COLUMNS TERMINATED BY '__Separator__'
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@date, @time, `timezone`, `MACB`, @source, @sourcetype, @type, @user, @host, @short, @desc, @version, @filename, @inode, @notes, @format, @extra)
SET
`date` = STR_TO_DATE(@date, '__DateTransformationSyntax__'),
`time` = STR_TO_DATE(@time, '__TimeTransformationSyntax__'),
source = nullif(@source,''),
sourcetype = nullif(@sourcetype,''),
type = nullif(@type,''),
user = nullif(@user,''),
host = nullif(@host,''),
short = nullif(@short,''),
`desc` = nullif(@desc,''),
version = nullif(@version,''),
filename = nullif(@filename,''),
inode = nullif(@inode,''),
notes = nullif(@notes,''),
format = nullif(@format,''),
extra = nullif(@extra,'')
;

