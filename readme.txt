Introduction
The journal is a log of changes to files on an NTFS volume. Such changes can for instance be the creation, deletion or modification of files or directories. It is optional to have it on, and can be configured with fsutil.exe on Windows. However, it was not turned on by default until Vista and later. 

Details
The journal, if turned on, can be found in the directory \$Extend and is named $UsnJrnl (this is not visible in explorer as it is part of the system files on NTFS). Actually it is an alternate data stream $J that contains the relevant data. This stream is usually rather large and can be several GB in size. Thus it may take quite some time to process, if filled up. 

The structure is well known and very simpel; http://www.microsoft.com/msj/0999/journal/journal.aspx 

The nice thing about it, is that it contains large amount of historical data. It is a sparse file. 

The tool in the current form, writes all the variables in the structure with the exception of; 
 -MajorVersion
 -MinorVersion
 -SourceInfo
 -SecurityId

I have found these to be of insignificant value, however if there is a special need for it to be included, let me know and I may consider activating it. 

Timestamps are written UTC 0.00 by default, but can be configured to anything. The format and precision of the timestamps can also cofigured. See displayed examples in the gui. 

Requirements
The journal must have been extracted beforehand by another tool. If you know the MFT reference number of the file, you can retrieve the file with:
1. NTFS File Extractor; https://github.com/jschicht/NtfsFileExtractor
2. RawCopy: https://github.com/jschicht/RawCopy

ToDo
Add support for output format in log2timeline and bodyformat. 
