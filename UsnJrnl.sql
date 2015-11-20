CREATE DATABASE IF NOT EXISTS Ntfs
	CHARACTER SET 'utf8'
	COLLATE 'utf8_general_ci';

USE Ntfs;

CREATE TABLE usnjrnl(
   `Offset`                  VARCHAR(18) NOT NULL
  ,`FileName`                VARCHAR(255) NOT NULL
  ,`USN`                     BIGINT  NOT NULL
  ,`Timestamp`               DATETIME(6)  NOT NULL
  ,`Reason`                  VARCHAR(255) NOT NULL
  ,`MFTReference`            BIGINT  NOT NULL
  ,`MFTReferenceSeqNo`       INTEGER  NOT NULL
  ,`MFTParentReference`      BIGINT  NOT NULL
  ,`MFTParentReferenceSeqNo` INTEGER  NOT NULL
  ,`FileAttributes`          VARCHAR(64) NOT NULL
  ,`MajorVersion`            INTEGER  NOT NULL
  ,`MinorVersion`            INTEGER  NOT NULL
  ,`SourceInfo`              VARCHAR(10)  NOT NULL
  ,`SecurityId`              INTEGER  NOT NULL
);