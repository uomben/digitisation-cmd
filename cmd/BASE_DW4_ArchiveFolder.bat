setlocal ENABLEDELAYEDEXPANSION

@rem set paths to utilities
set 7zip=C:\Tools\7zip\7za.exe
set b64=C:\Tools\b64\b64.exe
set EXIFTool=c:\Tools\EXIFTool\EXIFTool.exe
set EXIFReadTemplate=C:\tools\EXIFTool\templates\read_metadata_template.txt
set ffmpeg=C:\Tools\ffmpeg\bin\ffmpeg.exe
set ffplay=C:\Tools\ffmpeg\bin\ffplay.exe
set hashdeep=C:\Tools\hashdeep\hasdeep.exe
set ghostscript="C:\Program Files\gs\gs10.00.0\bin\gswin64.exe"
set magick=magick
set sRGB=c:\tools\ICC\sRGB_v4_ICC_preference.icc
set pdftk=c:\Tools\pdftk\pdftk.exe
set qpdf=C:\Tools\qpdf\bin\qpdf.exe
set tesseract=C:\Tools\Tesseract\Tesseract.exe
set vips=C:\Tools\vips\bin\vips.exe
set vipsthumbnail=C:\Tools\vips\bin\vipsthumbnail.exe
set wget=C:\Tools\wget\wget.exe

rem set script variable
set ItemID=%~n1
set SourceFolder=%~1
set ArchiveFolder=V:\Pergatory\LBRY\%ItemID:~0,2%\%ItemID:~2,2%\%ItemID:~4,2%\%ItemID:~6,2%\%ItemID:~-5%
set DestinationFolder=%~1
set TempFolder=c:\temp\%~n1
set OCRin=%TempFolder%\ocr
set OCRout=%~1
set SCANin=c:\scans\raw
set SCANout=c:\scans\export
set UndoFolder=%~dp1UNDO\%~n1

@echo Script variables:
@echo ItemID            - %ItemID%
@echo SourceFolder      - %SourceFolder%
@echo DestinationFolder - %DestinationFolder%
@echo TempFolder        - %TempFolder%
@echo OCRin             - %OCRin%
@echo OCRout            - %OCRout%
@echo UndoFolder        - %UndoFolder%
@echo ArchiveFolder     - %ArchiveFolder%

:: list files
@echo Post-processing data gathering
robocopy "%DestinationFolder%" NULL /S /L /NDL /NC /LOG:"%TempFolder%\%ItemID%_files.txt" /TEE /NJH /NJS /BYTES /NODD /XD meta thumb*

robocopy "%TempFolder%" "%DestinationFolder%\meta" "%ItemID%_files.txt" /w:5

:: Compress non-PDF per-image OCR outputs

@echo Create a tar.gz for per-image OCR outputs 
tar -cvzf "%OCRout%\%ItemID%_alto_xml.tar.gz" -C "%OCRout%" "%ItemID%_ocr_alto_xml" && rmdir /s /q "%OCRout%\%ItemID%_alto_xml"
tar -cvzf "%OCRout%\%ItemID%_hocr.tar.gz" -C "%OCRout%" "%ItemID%_ocr_hocr" && rmdir /s /q "%OCRout%\%ItemID%_hocr"
tar -cvzf "%OCRout%\%ItemID%_txt.tar.gz" -C "%OCRout%" "%ItemID%_ocr_txt" && rmdir /s /q "%OCRout%\%ItemID%_txt"

:: Collect EXIF metadata and checksums
@echo Collect EXIF metadata

@del "%DestinationFolder%\meta\%ItemID%_exif.txt"
%exiftool% -m -s -r -q -p "%EXIFReadTemplate%" "%DestinationFolder%" > "%TempFolder%\%ItemID%_exif.txt" 
robocopy %TempFolder% "%DestinationFolder%\meta" %ItemID%_exif.txt /MOV

@echo Collect checksums

@del "%DestinationFolder%\%ItemID%_chksum.xml"
%hashdeep% -c md5,sha256 -r -d "%DestinationFolder%\*.*" > "%TempFolder%\%ItemID%_chksum.xml"
robocopy "%TempFolder%" "%DestinationFolder%" %ItemID%_chksum.xml /MOV

@echo Cleanup temp folder
:: disabled for testing/debugging
:: rmdir /s /q "%TempFolder%"