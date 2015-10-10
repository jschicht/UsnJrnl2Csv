LOAD DATA INFILE "C:\\tmp\\NTFS\\UsnJrnl2Csv_v1.0.0.7\\UsnJrnl_2015-10-11_00-09-01.csv"
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