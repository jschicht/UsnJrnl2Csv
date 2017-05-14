LOAD DATA INFILE "__PathToCsv__"
INTO TABLE usnjrnl
CHARACTER SET 'latin1'
COLUMNS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(`Offset`, `FileName`, @USN, `Timestamp`, `Reason`, @MFTReference, @MFTReferenceSeqNo, @MFTParentReference, @MFTParentReferenceSeqNo, `FileAttributes`, @MajorVersion, @MinorVersion, @SourceInfo, @SecurityId)
SET 
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