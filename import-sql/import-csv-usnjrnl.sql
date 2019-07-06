LOAD DATA INFILE "__PathToCsv__" IGNORE
INTO TABLE usnjrnl
CHARACTER SET 'latin1'
COLUMNS TERMINATED BY '__Separator__'
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(`Offset`, `FileName`, @USN, @Timestamp, `Reason`, @MFTReference, @MFTReferenceSeqNo, @MFTParentReference, @MFTParentReferenceSeqNo, `FileAttributes`, @MajorVersion, @MinorVersion, @SourceInfo, @SecurityId)
SET
`Timestamp` = STR_TO_DATE(@Timestamp, '__TimestampTransformationSyntax__'),
USN = nullif(@USN,''),
MFTReference = nullif(@MFTReference,''),
MFTReferenceSeqNo = nullif(@MFTReferenceSeqNo,''),
MFTParentReference = nullif(@MFTParentReference,''),
MFTParentReferenceSeqNo = nullif(@MFTParentReferenceSeqNo,''),
MajorVersion = nullif(@MajorVersion,''),
MinorVersion = nullif(@MinorVersion,''),
SourceInfo = nullif(@SourceInfo,''),
SecurityId = nullif(@SecurityId,'')
;