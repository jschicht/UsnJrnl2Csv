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

Scan mode
The scan mode option for handling damaged input data, like for instance carved usn records. The default mode is normal mode, which expects a well structured $UsnJrnl file, containing 1 or more usn pages.
It works fine with any damaged data. This option is brute-force-like and will identify any usn record in a chunk of data if it is valid. Usn records can be randomly put within any kind of input data, and still be found. This mode is very slow.

There still exist some possibility for false positives even though lots of validation checks are present. 3 optional validations tests can be deactivated to improve output or speed. The 2 extended filename checks are slow, but also greatly reduces false positive. The extended timestamp check can also be optionally disable as it will throw an error on validation for timestamps outside the defined range of 14 oktober 1957 - 31 mai 2043.

Requirements
The journal must have been extracted beforehand by another tool.
1. Your best and easiest option would be the ExtractUsnJrnl tool: https://github.com/jschicht/ExtractUsnJrnl

If you know the MFT reference number of the file, you can retrieve the file with these slightly more complicated tools:
2. NTFS File Extractor; https://github.com/jschicht/NtfsFileExtractor
3. RawCopy: https://github.com/jschicht/RawCopy

Command line use
If no parameters are supplied, the GUI will by default launch. Valid switches are:

Switches:
/UsnJrnlFile:
Input UsnJrnl file ($J stream) extracted.
/OutputPath:
The output path of where to put output. Defaults to program directory.
/TimeZone:
A string value for the timezone. See notes further down for valid values.
/OutputFormat:
The output format of csv. Valid values can be l2t, bodyfile, all. Default is all.
/Separator:
The separator to use in the csv. Default is |
/QuotationMark:
Boolean value for surrounding values in csv with quotes. Default is 0. Can be 0 or 1.
/Unicode:
Boolean value for decoding unicode strings. Default is 1. Can be 0 or 1.
/TSFormat:
An integer from 1 - 6 for specifying the timestamp format. Start the gui to see what they mean. Default is 6.
/TSPrecision:
What precision to use in the timestamp. Valid values are None, MilliSec and NanoSec. Default is NanoSec.
/TSPrecisionSeparator:
The separator to put in the separation of the precision. Default is ".". Start the gui to see what it means.
/TSPrecisionSeparator2:
The separator to put in between MilliSec and NanoSec in the precision of timestamp. Default is empty/nothing. Start the gui to see what it means.
/TSErrorVal:
A custom error value to put with errors in timestamp decode. Default value is '0000-00-00 00:00:00', which is compatible with MySql, and represents and invalid timestamp value for NTFS.
/UsnPageSize:
The size of USN_PAGE_SIZE. Default is 4096, which should work in most cases.
/ScanMode:
Boolean value to activate ScanMode. Default is 0, Normal mode. Can be 0 or 1. See explanation further up.
/TestFilenameChar:
Boolean value to activate extended filename validation for characters outside valid range. Only used with scan mode. Default value is 1.
/TestFilenameWindows:
Boolean value to activate extended filename validation for characters not conforming to Windows valid filenames. Only used with scan mode. Default value is 1.
/TestTimestamp:
Boolean value to activate extended timestamp validation. Default value is 1. Can be 0 or 1.
/VerifyFragment:
Boolean value for activating a simple validation on a fragment only, and not full parser. Can be 0 or 1. Will by default write fixed fragment to OutFragment.bin unless otherwise specified in /OutFragmentName:
/OutFragmentName:
The output filename to write the fixed fragment to, if /VerifyFragment: is set to 1. If omitted, the default filename is OutFragment.bin.
/CleanUp:
Boolean value for cleaning up all output if no entries could be decoded. Default value is 1. Can be 0 or 1. This setting makes the most sense if program is run in loop in batch or similar.


The available TimeZone's to use are:
-12.00
-11.00
-10.00
-9.30
-9.00
-8.00
-7.00
-6.00
-5.00
-4.30
-4.00
-3.30
-3.00
-2.00
-1.00
0.00
1.00
2.00
3.00
3.30
4.00
4.30
5.00
5.30
5.45
6.00
6.30
7.00
8.00
8.45
9.00
9.30
10.00
10.30
11.00
11.30
12.00
12.45
13.00
14.00

Error levels
The current exit (error) codes have been implemented in commandline mode, which makes it more suited for batch scripting.
1. No valid journal entries could be decoded. Empty output.
4. Failure in writing fixed fragment to output. Validation of fragment succeeded though.

Thus if you get %ERRORLEVEL% == 1 it means nothing was decoded, and if you get %ERRORLEVEL% == 4 then valid records where detected but could not be written to separate output (only used with /VerifyFragment: and /OutFragmentName:).


Examples:
UsnJrnl2Csv.exe /UsnJrnlFile:c:\temp\$UsnJrnl_$J.bin /TimeZone:2.00 /TSFormat:1 /TSPrecision:MilliSec /Unicode:1
UsnJrnl2Csv.exe /UsnJrnlFile:c:\temp\$UsnJrnl_$J.bin /TimeZone:-10.00 /TSFormat:4 /TSPrecision:NanoSec /Unicode:1
UsnJrnl2Csv.exe /UsnJrnlFile:c:\temp\$UsnJrnl_$J.bin /TimeZone:3.00 /TSFormat:1 /TSPrecision:MilliSec
UsnJrnl2Csv.exe /UsnJrnlFile:c:\temp\$UsnJrnl_$J.bin /TSFormat:2 /TSPrecision:None
UsnJrnl2Csv.exe /UsnJrnlFile:c:\temp\$UsnJrnl_$J.bin /OutputPath:c:\temp\UsnJrnlOutput /ScanMode:2
UsnJrnl2Csv.exe /UsnJrnlFile:C:\temp\$UsnJrnl_$J.bin /TSPrecision:NanoSec /ScanMode:1
UsnJrnl2Csv.exe /UsnJrnlFile:C:\temp\$UsnJrnl_$J.bin /TSPrecision:NanoSec /TSFormat:2 /ScanMode:1 /OutputFormat:bodyfile
UsnJrnl2Csv.exe /UsnJrnlFile:C:\temp\fragment.bin /ScanMode:1 /VerifyFragment:1 /OutputPath:e:\UsnJrnlOutput /OutFragmentName:FragmentCollection.bin /CleanUp:1
UsnJrnl2Csv.exe /UsnJrnlFile:e:\UsnJrnlOutput\FragmentCollection.bin /OutputPath:e:\UsnJrnlOutput

Last example is a basic that uses common defaults that work out just fine in most cases. Also compatible with MySql imports.


ToDo
Add support for USN_RECORD_V4.
