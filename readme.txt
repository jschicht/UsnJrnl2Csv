Introduction
The journal is a log of changes to files on an NTFS volume. Such changes can for instance be the creation, deletion or modification of files or directories. It is optional to have it on, and can be configured with fsutil.exe on Windows. However, it was not turned on by default until Vista and later.

Details
The journal, if turned on, can be found in the directory \$Extend and is named $UsnJrnl (this is not visible in explorer as it is part of the system files on NTFS). Actually it is an alternate data stream $J that contains the relevant data. This stream is usually rather large and can be several GB in size. Thus it may take quite some time to process, if filled up. The file is sparse, so preferrably use the ExtractUsnJrnl tool to extract it.

The structure is well known and very simpel; http://www.microsoft.com/msj/0999/journal/journal.aspx 

The tool supports USN_RECORD_V2 and USN_RECORD_V3, but not USN_RECORD_V4 (introduced in Windows 8.1 and not activated by default.).

The nice thing about it, is that it contains large amount of historical data.

From version 1.0.0.5, all structure members were included in the output.

The USN_PAGE_SIZE is configurable. The default value is 4096, and should be sufficient for most cases.

Timestamps are written UTC 0.00 by default, but can be configured to anything. The format and precision of the timestamps can also be configured, as well as the millisec/precision separator. See displayed examples in the gui.

Scan modes
There are 2 scan mode options for handling damaged input data, like for instance carved usn records. The default mode is normal mode, which expects a well structured $UsnJrnl file, containing 1 or more usn pages.
Scan mode 1: Is suited when input has valid usn pages, but has has some damaged data at page start. Is slower parsing than normal mode, but faster than mode 2. 
Scan mode 2: Is best suited with severely damaged data. The concept of usn pages is thrown, and every sector of data is treated separately. This option will identify any chunk of data as a usn record if it resembles a valid usn record structure. Usn records can be randomly put within any kind of input data, and still be found. Usn records that span sector boundaries within a usn page, may not be identified using this mode. This mode is the slowest.

For both scan modes there may be false positives, but if so they will most likely stand out from the rest.

Requirements
The journal must have been extracted beforehand by another tool.
1. Your best and easiest option would be the ExtractUsnJrnl tool: https://github.com/jschicht/ExtractUsnJrnl

If you know the MFT reference number of the file, you can retrieve the file with these slightly more complicated tools:
2. NTFS File Extractor; https://github.com/jschicht/NtfsFileExtractor
3. RawCopy: https://github.com/jschicht/RawCopy

ToDo
Add support for output format in log2timeline and bodyformat.
Add support for USN_RECORD_V4.
