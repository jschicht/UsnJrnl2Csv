#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Comment=Parser for $UsnJrnl (NTFS)
#AutoIt3Wrapper_Res_Description=Parser for $UsnJrnl (NTFS)
#AutoIt3Wrapper_Res_Fileversion=1.0.0.2
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Include <WinAPIEx.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#Include <FileConstants.au3>
Global $UsnJrnlCsv, $UsnJrnlCsvFile, $UsnJrnlDbfile, $de="|", $sOutputFile, $VerboseOn=false, $SurroundingQuotes=True, $PreviousUsn, $DoDefaultAll, $dol2t, $DoBodyfile
Global $_COMMON_KERNEL32DLL=DllOpen("kernel32.dll"), $outputpath=@ScriptDir, $File, $MaxRecords, $CurrentPage, $WithQuotes
Global $ProgressStatus, $ProgressUsnJrnl
Global $begin, $ElapsedTime
Global $tDelta = _WinTime_GetUTCToLocalFileTimeDelta()
Global $DateTimeFormat,$ExampleTimestampVal = "01CD74B3150770B8",$TimestampPrecision, $UTCconfig
Global $Record_Size = 4096, $Remainder="", $nBytes
Global $ParserOutDir = @ScriptDir

$Form = GUICreate("UsnJrnl2Csv 1.0.0.2", 540, 350, -1, -1)

$LabelTimestampFormat = GUICtrlCreateLabel("Timestamp format:",20,20,90,20)
$ComboTimestampFormat = GUICtrlCreateCombo("", 110, 20, 30, 25)
$LabelTimestampPrecision = GUICtrlCreateLabel("Precision:",150,20,50,20)
$ComboTimestampPrecision = GUICtrlCreateCombo("", 200, 20, 70, 25)
$InputExampleTimestamp = GUICtrlCreateInput("",340,20,190,20)
GUICtrlSetState($InputExampleTimestamp, $GUI_DISABLE)

$Label1 = GUICtrlCreateLabel("Set decoded timestamps to specific region:",20,45,230,20)
$Combo2 = GUICtrlCreateCombo("", 230, 45, 85, 25)

$LabelSeparator = GUICtrlCreateLabel("Set separator:",20,70,70,20)
$SaparatorInput = GUICtrlCreateInput($de,90,70,20,20)
$SaparatorInput2 = GUICtrlCreateInput($de,120,70,30,20)
GUICtrlSetState($SaparatorInput2, $GUI_DISABLE)
$checkquotes = GUICtrlCreateCheckbox("Quotation mark", 180, 70, 100, 20)
GUICtrlSetState($checkquotes, $GUI_CHECKED)

$checkl2t = GUICtrlCreateCheckbox("log2timeline", 20, 100, 130, 20)
GUICtrlSetState($checkl2t, $GUI_UNCHECKED)
GUICtrlSetState($checkl2t, $GUI_DISABLE)
$checkbodyfile = GUICtrlCreateCheckbox("bodyfile", 20, 120, 130, 20)
GUICtrlSetState($checkbodyfile, $GUI_UNCHECKED)
GUICtrlSetState($checkbodyfile, $GUI_DISABLE)
$checkdefaultall = GUICtrlCreateCheckbox("dump everything", 20, 140, 130, 20)
GUICtrlSetState($checkdefaultall, $GUI_CHECKED)
GUICtrlSetState($checkdefaultall, $GUI_DISABLE)

$ButtonOutput = GUICtrlCreateButton("Change Output", 400, 70, 100, 20)
$ButtonInput = GUICtrlCreateButton("Browse $UsnJrnl", 400, 100, 100, 20)
$ButtonStart = GUICtrlCreateButton("Start Parsing", 400, 130, 100, 20)
$myctredit = GUICtrlCreateEdit("Current output folder: " & $outputpath & @CRLF, 0, 170, 540, 100, BitOR($ES_AUTOVSCROLL,$WS_VSCROLL))
_GUICtrlEdit_SetLimitText($myctredit, 128000)

_InjectTimeZoneInfo()
_InjectTimestampFormat()
_InjectTimestampPrecision()
_TranslateTimestamp()

GUISetState(@SW_SHOW)

While 1
	$nMsg = GUIGetMsg()
	Sleep(100)
	_TranslateSeparator()
	_TranslateTimestamp()
	Select
		Case $nMsg = $ButtonOutput
			$newoutputpath = FileSelectFolder("Select output folder.", "",7,$ParserOutDir)
			If Not @error then
				_DisplayInfo("New output folder: " & $newoutputpath & @CRLF)
				$ParserOutDir = $newoutputpath
			EndIf
		Case $nMsg = $ButtonInput
			$File = FileOpenDialog("Select file",@ScriptDir,"All (*.*)")
			If Not @error Then _DisplayInfo("Input: " & $File & @CRLF)
		Case $nMsg = $ButtonStart
			_Main()
		Case $nMsg = $GUI_EVENT_CLOSE
			Exit
	EndSelect
WEnd

Func _Main()
	GUICtrlSetData($ProgressUsnJrnl, 0)

	If Int(GUICtrlRead($checkl2t) + GUICtrlRead($checkbodyfile) + GUICtrlRead($checkdefaultall)) <> 9 Then
		_DisplayInfo("Error: Output format can only be one of the options (not more than 1)." & @CRLF)
		Return
	EndIf
	If GUICtrlRead($checkl2t) = 1 Then
		$Dol2t = True
	ElseIf GUICtrlRead($checkbodyfile) = 1 Then
		$DoBodyfile = True
	ElseIf GUICtrlRead($checkdefaultall) = 1 Then
		$DoDefaultAll = True
	EndIf

	If GUICtrlRead($checkquotes) = 1 Then
		$WithQuotes=True
	Else
		$WithQuotes=False
	EndIf
	If Not FileExists($File) Then
		_DisplayInfo("Error: No $UsnJrnl chosen for input" & @CRLF)
		Return
	EndIf
	$TimestampStart = @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & "-" & @MIN & "-" & @SEC
	$UsnJrnlCsvFile = $ParserOutDir & "\UsnJrnl_"&$TimestampStart&".csv"
	$UsnJrnlCsv = FileOpen($UsnJrnlCsvFile, 2)
	If @error Then
		_DisplayInfo("Error creating: " & $UsnJrnlCsvFile & @CRLF)
		Return
	EndIf

	$Progress = GUICtrlCreateLabel("Decoding $UsnJrnl info and writing to csv", 10, 280,540,20)
	GUICtrlSetFont($Progress, 12)
	$ProgressStatus = GUICtrlCreateLabel("", 10, 275, 520, 20)
	$ElapsedTime = GUICtrlCreateLabel("", 10, 290, 520, 20)
	$ProgressUsnJrnl = GUICtrlCreateProgress(0,  315, 540, 30)
	$begin = TimerInit()

	$tBuffer = DllStructCreate("byte[" & $Record_Size & "]")
	$hFile = _WinAPI_CreateFile("\\.\" & $File,2,2,7)
	If $hFile = 0 Then
		_DisplayInfo("Error: Creating handle on file" & @CRLF)
		Return
	EndIf
	_WriteCSVHeader()
	$InputFileSize = _WinAPI_GetFileSizeEx($hFile)
	AdlibRegister("_UsnJrnlProgress", 500)
	$MaxRecords = Ceiling($InputFileSize/$Record_Size)
	For $i = 0 To $MaxRecords-1
		$CurrentPage=$i
		_WinAPI_SetFilePointerEx($hFile, $i*$Record_Size, $FILE_BEGIN)
		If $i = $MaxRecords-1 Then $tBuffer = DllStructCreate("byte[" & $Record_Size & "]")
		_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $Record_Size, $nBytes)
		$RawPage = DllStructGetData($tBuffer, 1)
		_UsnProcessPage(StringMid($RawPage,3))
	Next
	ProgressOff()
	AdlibUnRegister("_UsnJrnlProgress")
	_DisplayInfo("Parsing finished in " & _WinAPI_StrFromTimeInterval(TimerDiff($begin)) & @CRLF)
	_WinAPI_CloseHandle($hFile)
	FileFlush($UsnJrnlCsv)
	FileClose($UsnJrnlCsv)
	Return
EndFunc

Func _UsnProcessPage($TargetPage)
	Local $LocalUsnPart = 0, $NextOffset = 1, $TotalSizeOfPage = StringLen($TargetPage)
	Do
		$LocalUsnPart+=1
		$SizeOfNextUsnRecord = StringMid($TargetPage,$NextOffset,8)
		$SizeOfNextUsnRecord = Dec(_SwapEndian($SizeOfNextUsnRecord),2)
		If $SizeOfNextUsnRecord = 0 Then ExitLoop
		$SizeOfNextUsnRecord = $SizeOfNextUsnRecord*2
		$NextUsnRecord = StringMid($TargetPage,$NextOffset,$SizeOfNextUsnRecord)
		$FileNameLength = StringMid($TargetPage,$NextOffset+112,4)
		$FileNameLength = Dec(_SwapEndian($FileNameLength),2)
		$TestOffset = 60+$FileNameLength
		If $NextOffset+$SizeOfNextUsnRecord >= $TotalSizeOfPage Then Return
		_UsnDecodeRecord($NextUsnRecord)
		$NextOffset+=$SizeOfNextUsnRecord
	Until $NextOffset >= $TotalSizeOfPage
	Return ""
EndFunc

Func _UsnDecodeRecord($Record)
	$UsnJrnlRecordLength = StringMid($Record,1,8)
	$UsnJrnlRecordLength = Dec(_SwapEndian($UsnJrnlRecordLength),2)
;	$UsnJrnlMajorVersion = StringMid($Record,9,4)
;	$UsnJrnlMinorVersion = StringMid($Record,13,4)
	$UsnJrnlFileReferenceNumber = StringMid($Record,17,12)
	$UsnJrnlFileReferenceNumber = Dec(_SwapEndian($UsnJrnlFileReferenceNumber),2)
	$UsnJrnlMFTReferenceSeqNo = StringMid($Record,29,4)
	$UsnJrnlMFTReferenceSeqNo = Dec(_SwapEndian($UsnJrnlMFTReferenceSeqNo),2)
	$UsnJrnlParentFileReferenceNumber = StringMid($Record,33,12)
	$UsnJrnlParentFileReferenceNumber = Dec(_SwapEndian($UsnJrnlParentFileReferenceNumber),2)
	$UsnJrnlParentReferenceSeqNo = StringMid($Record,45,4)
	$UsnJrnlParentReferenceSeqNo = Dec(_SwapEndian($UsnJrnlParentReferenceSeqNo),2)
	$UsnJrnlUsn = StringMid($Record,49,16)
	$UsnJrnlUsn = Dec(_SwapEndian($UsnJrnlUsn),2)
;	If $i = 1704000 Then $PreviousUsn = $UsnJrnlUsn
;	If $PreviousUsn < $UsnJrnlUsn Then Exit
;	$PreviousUsn = $UsnJrnlUsn
	$UsnJrnlTimestamp = StringMid($Record,65,16)
	$UsnJrnlTimestamp = _DecodeTimestamp($UsnJrnlTimestamp)
	$UsnJrnlReason = StringMid($Record,81,8)
	$UsnJrnlReason = _DecodeReasonCodes("0x"&_SwapEndian($UsnJrnlReason))
;	$UsnJrnlSourceInfo = StringMid($Record,89,8)
;	$UsnJrnlSourceInfo = _DecodeSourceInfoFlag("0x"&_SwapEndian($UsnJrnlSourceInfo))
;	$UsnJrnlSourceInfo = "0x"&_SwapEndian($UsnJrnlSourceInfo)
;	$UsnJrnlSecurityId = StringMid($Record,97,8)
	$UsnJrnlFileAttributes = StringMid($Record,105,8)
	$UsnJrnlFileAttributes = _File_Attributes("0x"&_SwapEndian($UsnJrnlFileAttributes))
	$UsnJrnlFileNameLength = StringMid($Record,113,4)
	$UsnJrnlFileNameLength = Dec(_SwapEndian($UsnJrnlFileNameLength),2)
	$UsnJrnlFileNameOffset = StringMid($Record,117,4)
	$UsnJrnlFileNameOffset = Dec(_SwapEndian($UsnJrnlFileNameOffset),2)
	$UsnJrnlFileName = StringMid($Record,121,$UsnJrnlFileNameLength*2)
	$UsnJrnlFileName = _UnicodeHexToStr($UsnJrnlFileName)
	If $VerboseOn Then
		ConsoleWrite("$UsnJrnlFileReferenceNumber: " & $UsnJrnlFileReferenceNumber & @CRLF)
		ConsoleWrite("$UsnJrnlMFTReferenceSeqNo: " & $UsnJrnlMFTReferenceSeqNo & @CRLF)
		ConsoleWrite("$UsnJrnlParentFileReferenceNumber: " & $UsnJrnlParentFileReferenceNumber & @CRLF)
		ConsoleWrite("$UsnJrnlParentReferenceSeqNo: " & $UsnJrnlParentReferenceSeqNo & @CRLF)
		ConsoleWrite("$UsnJrnlUsn: " & $UsnJrnlUsn & @CRLF)
		ConsoleWrite("$UsnJrnlTimestamp: " & $UsnJrnlTimestamp & @CRLF)
		ConsoleWrite("$UsnJrnlReason: " & $UsnJrnlReason & @CRLF)
;		ConsoleWrite("$UsnJrnlSourceInfo: " & $UsnJrnlSourceInfo & @CRLF)
;		ConsoleWrite("$UsnJrnlSecurityId: " & $UsnJrnlSecurityId & @CRLF)
		ConsoleWrite("$UsnJrnlFileAttributes: " & $UsnJrnlFileAttributes & @CRLF)
		ConsoleWrite("$UsnJrnlFileName: " & $UsnJrnlFileName & @CRLF)
	EndIf
	If $WithQuotes Then
		FileWriteLine($UsnJrnlCsv, '"'&$UsnJrnlFileName&'"'&$de&'"'&$UsnJrnlUsn&'"'&$de&'"'&$UsnJrnlTimestamp&'"'&$de&'"'&$UsnJrnlReason&'"'&$de&'"'&$UsnJrnlFileReferenceNumber&'"'&$de&'"'&$UsnJrnlMFTReferenceSeqNo&'"'&$de&'"'&$UsnJrnlParentFileReferenceNumber&'"'&$de&'"'&$UsnJrnlParentReferenceSeqNo&'"'&$de&'"'&$UsnJrnlFileAttributes&'"'&@CRLF)
	Else
		FileWriteLine($UsnJrnlCsv, $UsnJrnlFileName&$de&$UsnJrnlUsn&$de&$UsnJrnlTimestamp&$de&$UsnJrnlReason&$de&$UsnJrnlFileReferenceNumber&$de&$UsnJrnlMFTReferenceSeqNo&$de&$UsnJrnlParentFileReferenceNumber&$de&$UsnJrnlParentReferenceSeqNo&$de&$UsnJrnlFileAttributes&@crlf)
	EndIf
EndFunc

Func _DecodeReasonCodes($USNReasonInput)
	Local $USNReasonOutput = ""
	If BitAND($USNReasonInput, 0x00008000) Then $USNReasonOutput &= 'BASIC_INFO_CHANGE+'
	If BitAND($USNReasonInput, 0x80000000) Then $USNReasonOutput &= 'CLOSE+'
	If BitAND($USNReasonInput, 0x00020000) Then $USNReasonOutput &= 'COMPRESSION_CHANGE+'
	If BitAND($USNReasonInput, 0x00000002) Then $USNReasonOutput &= 'DATA_EXTEND+'
	If BitAND($USNReasonInput, 0x00000001) Then $USNReasonOutput &= 'DATA_OVERWRITE+'
	If BitAND($USNReasonInput, 0x00000004) Then $USNReasonOutput &= 'DATA_TRUNCATION+'
	If BitAND($USNReasonInput, 0x00000400) Then $USNReasonOutput &= 'EA_CHANGE+'
	If BitAND($USNReasonInput, 0x00040000) Then $USNReasonOutput &= 'ENCRYPTION_CHANGE+'
	If BitAND($USNReasonInput, 0x00000100) Then $USNReasonOutput &= 'FILE_CREATE+'
	If BitAND($USNReasonInput, 0x00000200) Then $USNReasonOutput &= 'FILE_DELETE+'
	If BitAND($USNReasonInput, 0x00010000) Then $USNReasonOutput &= 'HARD_LINK_CHANGE+'
	If BitAND($USNReasonInput, 0x00004000) Then $USNReasonOutput &= 'INDEXABLE_CHANGE+'
	If BitAND($USNReasonInput, 0x00000020) Then $USNReasonOutput &= 'NAMED_DATA_EXTEND+'
	If BitAND($USNReasonInput, 0x00000010) Then $USNReasonOutput &= 'NAMED_DATA_OVERWRITE+'
	If BitAND($USNReasonInput, 0x00000040) Then $USNReasonOutput &= 'NAMED_DATA_TRUNCATION+'
	If BitAND($USNReasonInput, 0x00080000) Then $USNReasonOutput &= 'OBJECT_ID_CHANGE+'
	If BitAND($USNReasonInput, 0x00002000) Then $USNReasonOutput &= 'RENAME_NEW_NAME+'
	If BitAND($USNReasonInput, 0x00001000) Then $USNReasonOutput &= 'RENAME_OLD_NAME+'
	If BitAND($USNReasonInput, 0x00100000) Then $USNReasonOutput &= 'REPARSE_POINT_CHANGE+'
	If BitAND($USNReasonInput, 0x00000800) Then $USNReasonOutput &= 'SECURITY_CHANGE+'
	If BitAND($USNReasonInput, 0x00200000) Then $USNReasonOutput &= 'STREAM_CHANGE+'
	If BitAND($USNReasonInput, 0x00800000) Then $USNReasonOutput &= 'INTEGRITY_CHANGE+'
	$USNReasonOutput = StringTrimRight($USNReasonOutput, 1)
	Return $USNReasonOutput
EndFunc

Func _File_Attributes($FAInput)
	Local $FAOutput = ""
	If BitAND($FAInput, 0x0001) Then $FAOutput &= 'read_only+'
	If BitAND($FAInput, 0x0002) Then $FAOutput &= 'hidden+'
	If BitAND($FAInput, 0x0004) Then $FAOutput &= 'system+'
	If BitAND($FAInput, 0x0010) Then $FAOutput &= 'directory+'
	If BitAND($FAInput, 0x0020) Then $FAOutput &= 'archive+'
	If BitAND($FAInput, 0x0040) Then $FAOutput &= 'device+'
	If BitAND($FAInput, 0x0080) Then $FAOutput &= 'normal+'
	If BitAND($FAInput, 0x0100) Then $FAOutput &= 'temporary+'
	If BitAND($FAInput, 0x0200) Then $FAOutput &= 'sparse_file+'
	If BitAND($FAInput, 0x0400) Then $FAOutput &= 'reparse_point+'
	If BitAND($FAInput, 0x0800) Then $FAOutput &= 'compressed+'
	If BitAND($FAInput, 0x1000) Then $FAOutput &= 'offline+'
	If BitAND($FAInput, 0x2000) Then $FAOutput &= 'not_indexed+'
	If BitAND($FAInput, 0x4000) Then $FAOutput &= 'encrypted+'
	If BitAND($FAInput, 0x8000) Then $FAOutput &= 'integrity_stream+'
	If BitAND($FAInput, 0x10000) Then $FAOutput &= 'virtual+'
	If BitAND($FAInput, 0x20000) Then $FAOutput &= 'no_scrub_data+'
	If BitAND($FAInput, 0x10000000) Then $FAOutput &= 'directory+'
	If BitAND($FAInput, 0x20000000) Then $FAOutput &= 'index_view+'
	$FAOutput = StringTrimRight($FAOutput, 1)
	Return $FAOutput
EndFunc

Func _DecodeSourceInfoFlag($input)
	Select
		Case $input = 0x00000001
			$ret = "USN_SOURCE_DATA_MANAGEMENT"
		Case $input = 0x00000002
			$ret = "USN_SOURCE_AUXILIARY_DATA"
		Case $input = 0x00000004
			$ret = "USN_SOURCE_REPLICATION_MANAGEMENT"
		Case Else
			$ret = "EMPTY"
	EndSelect
	Return $ret
EndFunc

Func _DecodeTimestamp($StampDecode)
	$StampDecode = _SwapEndian($StampDecode)
	$StampDecode_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $StampDecode)
	$StampDecode = _WinTime_UTCFileTimeFormat(Dec($StampDecode,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$StampDecode = "-"
	ElseIf $TimestampPrecision = 3 Then
		$StampDecode = $StampDecode & ":" & _FillZero(StringRight($StampDecode_tmp, 4))
	EndIf
	Return $StampDecode
EndFunc

Func _UnicodeHexToStr($FileName)
   $str = ""
   For $i = 1 To StringLen($FileName) Step 4
	  $str &= ChrW(Dec(_SwapEndian(StringMid($FileName, $i, 4))))
   Next
   Return $str
EndFunc

Func _SwapEndian($iHex)
	Return StringMid(Binary(Dec($iHex,2)),3, StringLen($iHex))
EndFunc

Func _FillZero($inp)
	Local $inplen, $out, $tmp = ""
	$inplen = StringLen($inp)
	For $i = 1 To 4 - $inplen
		$tmp &= "0"
	Next
	$out = $tmp & $inp
	Return $out
EndFunc   ;==>_FillZero

Func _HexEncode($bInput)
    Local $tInput = DllStructCreate("byte[" & BinaryLen($bInput) & "]")
    DllStructSetData($tInput, 1, $bInput)
    Local $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", 0, _
            "dword*", 0)

    If @error Or Not $a_iCall[0] Then
        Return SetError(1, 0, "")
    EndIf
    Local $iSize = $a_iCall[5]
    Local $tOut = DllStructCreate("char[" & $iSize & "]")
    $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", DllStructGetPtr($tOut), _
            "dword*", $iSize)
    If @error Or Not $a_iCall[0] Then
        Return SetError(2, 0, "")
    EndIf
    Return SetError(0, 0, DllStructGetData($tOut, 1))
EndFunc

Func _WinTime_GetUTCToLocalFileTimeDelta()
	Local $iUTCFileTime=864000000000		; exactly 24 hours from the origin (although 12 hours would be more appropriate (max variance = 12))
	$iLocalFileTime=_WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If @error Then Return SetError(@error,@extended,-1)
	Return $iLocalFileTime-$iUTCFileTime	; /36000000000 = # hours delta (effectively giving the offset in hours from UTC/GMT)
EndFunc

Func _WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If $iUTCFileTime<0 Then Return SetError(1,0,-1)
	Local $aRet=DllCall($_COMMON_KERNEL32DLL,"bool","FileTimeToLocalFileTime","uint64*",$iUTCFileTime,"uint64*",0)
	If @error Then Return SetError(2,@error,-1)
	If Not $aRet[0] Then Return SetError(3,0,-1)
	Return $aRet[2]
EndFunc

Func _WinTime_UTCFileTimeFormat($iUTCFileTime,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
;~ 	If $iUTCFileTime<0 Then Return SetError(1,0,"")	; checked in below call

	; First convert file time (UTC-based file time) to 'local file time'
	Local $iLocalFileTime=_WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If @error Then Return SetError(@error,@extended,"")
	; Rare occassion: a filetime near the origin (January 1, 1601!!) is used,
	;	causing a negative result (for some timezones). Return as invalid param.
	If $iLocalFileTime<0 Then Return SetError(1,0,"")

	; Then convert file time to a system time array & format & return it
	Local $vReturn=_WinTime_LocalFileTimeFormat($iLocalFileTime,$iFormat,$iPrecision,$bAMPMConversion)
	Return SetError(@error,@extended,$vReturn)
EndFunc

Func _WinTime_LocalFileTimeFormat($iLocalFileTime,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
;~ 	If $iLocalFileTime<0 Then Return SetError(1,0,"")	; checked in below call

	; Convert file time to a system time array & return result
	Local $aSysTime=_WinTime_LocalFileTimeToSystemTime($iLocalFileTime)
	If @error Then Return SetError(@error,@extended,"")

	; Return only the SystemTime array?
	If $iFormat=0 Then Return $aSysTime

	Local $vReturn=_WinTime_FormatTime($aSysTime[0],$aSysTime[1],$aSysTime[2],$aSysTime[3], _
		$aSysTime[4],$aSysTime[5],$aSysTime[6],$aSysTime[7],$iFormat,$iPrecision,$bAMPMConversion)
	Return SetError(@error,@extended,$vReturn)
EndFunc

Func _WinTime_LocalFileTimeToSystemTime($iLocalFileTime)
	Local $aRet,$stSysTime,$aSysTime[8]=[-1,-1,-1,-1,-1,-1,-1,-1]

	; Negative values unacceptable
	If $iLocalFileTime<0 Then Return SetError(1,0,$aSysTime)

	; SYSTEMTIME structure [Year,Month,DayOfWeek,Day,Hour,Min,Sec,Milliseconds]
	$stSysTime=DllStructCreate("ushort[8]")

	$aRet=DllCall($_COMMON_KERNEL32DLL,"bool","FileTimeToSystemTime","uint64*",$iLocalFileTime,"ptr",DllStructGetPtr($stSysTime))
	If @error Then Return SetError(2,@error,$aSysTime)
	If Not $aRet[0] Then Return SetError(3,0,$aSysTime)
	Dim $aSysTime[8]=[DllStructGetData($stSysTime,1,1),DllStructGetData($stSysTime,1,2),DllStructGetData($stSysTime,1,4),DllStructGetData($stSysTime,1,5), _
		DllStructGetData($stSysTime,1,6),DllStructGetData($stSysTime,1,7),DllStructGetData($stSysTime,1,8),DllStructGetData($stSysTime,1,3)]
	Return $aSysTime
EndFunc

Func _WinTime_FormatTime($iYear,$iMonth,$iDay,$iHour,$iMin,$iSec,$iMilSec,$iDayOfWeek,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
	Local Static $_WT_aMonths[12]=["January","February","March","April","May","June","July","August","September","October","November","December"]
	Local Static $_WT_aDays[7]=["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

	If Not $iFormat Or $iMonth<1 Or $iMonth>12 Or $iDayOfWeek>6 Then Return SetError(1,0,"")

	; Pad MM,DD,HH,MM,SS,MSMSMSMS as necessary
	Local $sMM=StringRight(0&$iMonth,2),$sDD=StringRight(0&$iDay,2),$sMin=StringRight(0&$iMin,2)
	; $sYY = $iYear	; (no padding)
	;	[technically Year can be 1-x chars - but this is generally used for 4-digit years. And SystemTime only goes up to 30827/30828]
	Local $sHH,$sSS,$sMS,$sAMPM

	; 'Extra precision 1': +SS (Seconds)
	If $iPrecision Then
		$sSS=StringRight(0&$iSec,2)
		; 'Extra precision 2': +MSMSMSMS (Milliseconds)
		If $iPrecision>1 Then
;			$sMS=StringRight('000'&$iMilSec,4)
			$sMS=StringRight('000'&$iMilSec,3);Fixed an erronous 0 in front of the milliseconds
		Else
			$sMS=""
		EndIf
	Else
		$sSS=""
		$sMS=""
	EndIf
	If $bAMPMConversion Then
		If $iHour>11 Then
			$sAMPM=" PM"
			; 12 PM will cause 12-12 to equal 0, so avoid the calculation:
			If $iHour=12 Then
				$sHH="12"
			Else
				$sHH=StringRight(0&($iHour-12),2)
			EndIf
		Else
			$sAMPM=" AM"
			If $iHour Then
				$sHH=StringRight(0&$iHour,2)
			Else
			; 00 military = 12 AM
				$sHH="12"
			EndIf
		EndIf
	Else
		$sAMPM=""
		$sHH=StringRight(0 & $iHour,2)
	EndIf

	Local $sDateTimeStr,$aReturnArray[3]

	; Return an array? [formatted string + "Month" + "DayOfWeek"]
	If BitAND($iFormat,0x10) Then
		$aReturnArray[1]=$_WT_aMonths[$iMonth-1]
		If $iDayOfWeek>=0 Then
			$aReturnArray[2]=$_WT_aDays[$iDayOfWeek]
		Else
			$aReturnArray[2]=""
		EndIf
		; Strip the 'array' bit off (array[1] will now indicate if an array is to be returned)
		$iFormat=BitAND($iFormat,0xF)
	Else
		; Signal to below that the array isn't to be returned
		$aReturnArray[1]=""
	EndIf

	; Prefix with "DayOfWeek "?
	If BitAND($iFormat,8) Then
		If $iDayOfWeek<0 Then Return SetError(1,0,"")	; invalid
		$sDateTimeStr=$_WT_aDays[$iDayOfWeek]&', '
		; Strip the 'DayOfWeek' bit off
		$iFormat=BitAND($iFormat,0x7)
	Else
		$sDateTimeStr=""
	EndIf

	If $iFormat<2 Then
		; Basic String format: YYYYMMDDHHMM[SS[MSMSMSMS[ AM/PM]]]
		$sDateTimeStr&=$iYear&$sMM&$sDD&$sHH&$sMin&$sSS&$sMS&$sAMPM
	Else
		; one of 4 formats which ends with " HH:MM[:SS[:MSMSMSMS[ AM/PM]]]"
		Switch $iFormat
			; /, : Format - MM/DD/YYYY
			Case 2
				$sDateTimeStr&=$sMM&'/'&$sDD&'/'
			; /, : alt. Format - DD/MM/YYYY
			Case 3
				$sDateTimeStr&=$sDD&'/'&$sMM&'/'
			; "Month DD, YYYY" format
			Case 4
				$sDateTimeStr&=$_WT_aMonths[$iMonth-1]&' '&$sDD&', '
			; "DD Month YYYY" format
			Case 5
				$sDateTimeStr&=$sDD&' '&$_WT_aMonths[$iMonth-1]&' '
			Case 6
				$sDateTimeStr&=$iYear&'-'&$sMM&'-'&$sDD
				$iYear=''
			Case Else
				Return SetError(1,0,"")
		EndSwitch
		$sDateTimeStr&=$iYear&' '&$sHH&':'&$sMin
		If $iPrecision Then
			$sDateTimeStr&=':'&$sSS
			If $iPrecision>1 Then $sDateTimeStr&=':'&$sMS
		EndIf
		$sDateTimeStr&=$sAMPM
	EndIf
	If $aReturnArray[1]<>"" Then
		$aReturnArray[0]=$sDateTimeStr
		Return $aReturnArray
	EndIf
	Return $sDateTimeStr
EndFunc

Func _DisplayInfo($DebugInfo)
	GUICtrlSetData($myctredit, $DebugInfo, 1)
EndFunc

Func _DisplayProgress()
	ProgressSet(Round((($CurrentPage / $MaxRecords) * 100), 2), Round(($CurrentPage / $MaxRecords) * 100, 2) & "  % finished parsing", "")
EndFunc

Func _WriteCSVHeader()
	If $DoDefaultAll Then
		$UsnJrnl_Csv_Header = "FileName"&$de&"USN"&$de&"Timestamp"&$de&"Reason"&$de&"MFTReference"&$de&"MFTReferenceSeqNo"&$de&"MFTParentReference"&$de&"MFTParentReferenceSeqNo"&$de&"FileAttributes"
	ElseIf $dol2t Then
		$UsnJrnl_Csv_Header = "Date"&$de&"Time"&$de&"Timezone"&$de&"MACB"&$de&"Source"&$de&"SourceType"&$de&"Type"&$de&"User"&$de&"Host"&$de&"Short"&$de&"Desc"&$de&"Version"&$de&"Filename"&$de&"Inode"&$de&"Notes"&$de&"Format"&$de&"Extra"
	ElseIf $DoBodyfile Then
		$UsnJrnl_Csv_Header = "MD5"&$de&"name"&$de&"inode"&$de&"mode_as_string"&$de&"UID"&$de&"GID"&$de&"size"&$de&"atime"&$de&"mtime"&$de&"ctime"&$de&"crtime"
	EndIf
	FileWriteLine($UsnJrnlCsv, $UsnJrnl_Csv_Header & @CRLF)
EndFunc

Func _InjectTimeZoneInfo()
$Regions = "UTC: -12.00|" & _
	"UTC: -11.00|" & _
	"UTC: -10.00|" & _
	"UTC: -9.30|" & _
	"UTC: -9.00|" & _
	"UTC: -8.00|" & _
	"UTC: -7.00|" & _
	"UTC: -6.00|" & _
	"UTC: -5.00|" & _
	"UTC: -4.30|" & _
	"UTC: -4.00|" & _
	"UTC: -3.30|" & _
	"UTC: -3.00|" & _
	"UTC: -2.00|" & _
	"UTC: -1.00|" & _
	"UTC: 0.00|" & _
	"UTC: 1.00|" & _
	"UTC: 2.00|" & _
	"UTC: 3.00|" & _
	"UTC: 3.30|" & _
	"UTC: 4.00|" & _
	"UTC: 4.30|" & _
	"UTC: 5.00|" & _
	"UTC: 5.30|" & _
	"UTC: 5.45|" & _
	"UTC: 6.00|" & _
	"UTC: 6.30|" & _
	"UTC: 7.00|" & _
	"UTC: 8.00|" & _
	"UTC: 8.45|" & _
	"UTC: 9.00|" & _
	"UTC: 9.30|" & _
	"UTC: 10.00|" & _
	"UTC: 10.30|" & _
	"UTC: 11.00|" & _
	"UTC: 11.30|" & _
	"UTC: 12.00|" & _
	"UTC: 12.45|" & _
	"UTC: 13.00|" & _
	"UTC: 14.00|"
GUICtrlSetData($Combo2,$Regions,"UTC: 0.00")
EndFunc

Func _GetUTCRegion()
	$UTCRegion = GUICtrlRead($Combo2)
	If $UTCRegion = "" Then Return SetError(1,0,0)
	$part1 = StringMid($UTCRegion,StringInStr($UTCRegion," ")+1)
	Global $UTCconfig = $part1
	If StringRight($part1,2) = "15" Then $part1 = StringReplace($part1,".15",".25")
	If StringRight($part1,2) = "30" Then $part1 = StringReplace($part1,".30",".50")
	If StringRight($part1,2) = "45" Then $part1 = StringReplace($part1,".45",".75")
	$DeltaTest = $part1*36000000000
	Return $DeltaTest
EndFunc

Func _TranslateSeparator()
	; Or do it the other way around to allow setting other trickier separators, like specifying it in hex
	GUICtrlSetData($SaparatorInput,StringLeft(GUICtrlRead($SaparatorInput),1))
	GUICtrlSetData($SaparatorInput2,"0x"&Hex(Asc(GUICtrlRead($SaparatorInput)),2))
EndFunc

Func _InjectTimestampFormat()
Local $Formats = "1|" & _
	"2|" & _
	"3|" & _
	"4|" & _
	"5|" & _
	"6|"
	GUICtrlSetData($ComboTimestampFormat,$Formats,"6")
EndFunc

Func _InjectTimestampPrecision()
Local $Precision = "None|" & _
	"MilliSec|" & _
	"NanoSec|"
	GUICtrlSetData($ComboTimestampPrecision,$Precision,"NanoSec")
EndFunc

Func _TranslateTimestamp()
	Local $lPrecision,$lTimestamp,$lTimestampTmp
	$DateTimeFormat = StringLeft(GUICtrlRead($ComboTimestampFormat),1)
	$lPrecision = GUICtrlRead($ComboTimestampPrecision)
	Select
		Case $lPrecision = "None"
			$TimestampPrecision = 1
		Case $lPrecision = "MilliSec"
			$TimestampPrecision = 2
		Case $lPrecision = "NanoSec"
			$TimestampPrecision = 3
	EndSelect
	$lTimestampTmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $ExampleTimestampVal)
	$lTimestamp = _WinTime_UTCFileTimeFormat(Dec($ExampleTimestampVal,2), $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$lTimestamp = "-"
	ElseIf $TimestampPrecision = 3 Then
		$lTimestamp = $lTimestamp & ":" & _FillZero(StringRight($lTimestampTmp, 4))
	EndIf
	GUICtrlSetData($InputExampleTimestamp,$lTimestamp)
EndFunc

Func _UsnJrnlProgress()
    GUICtrlSetData($ProgressStatus, "Processing UsnJrnl record " & $CurrentPage & " of " & $MaxRecords)
    GUICtrlSetData($ElapsedTime, "Elapsed time = " & _WinAPI_StrFromTimeInterval(TimerDiff($begin)))
	GUICtrlSetData($ProgressUsnJrnl, 100 * $CurrentPage / $MaxRecords)
EndFunc
