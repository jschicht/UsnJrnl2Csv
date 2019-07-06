
CREATE TABLE usnjrnl(
	`Id`						INT(11) NOT NULL AUTO_INCREMENT
	,`Offset`                  	VARCHAR(18) NOT NULL
	,`FileName`                	VARCHAR(255) NOT NULL
	,`USN`                     	BIGINT  NOT NULL
	,`Timestamp`               	DATETIME(6)  NOT NULL
	,`Reason`                  	VARCHAR(255) NOT NULL
	,`MFTReference`            	BIGINT  NOT NULL
	,`MFTReferenceSeqNo`       	INT(5)  NOT NULL
	,`MFTParentReference`      	BIGINT  NOT NULL
	,`MFTParentReferenceSeqNo` 	INT(5)  NOT NULL
	,`FileAttributes`          	VARCHAR(64) NOT NULL
	,`MajorVersion`            	INT(5)  NOT NULL
	,`MinorVersion`            	INT(5)  NOT NULL
	,`SourceInfo`              	VARCHAR(10)  NOT NULL
	,`SecurityId`              	INT(11)  NOT NULL
	,PRIMARY KEY (Id)
);