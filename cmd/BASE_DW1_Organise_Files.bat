setlocal ENABLEDELAYEDEXPANSION

:: set script variables
:: Utililty paths
set 7zip=C:\Tools\7zip\7za.exe
set b64=C:\Tools\b64\b64.exe
set EXIFTool=c:\Tools\EXIFTool\EXIFTool.exe
set ffmpeg=C:\Tools\ffmpeg\bin\ffmpeg.exe
set ffplay=C:\Tools\ffmpeg\bin\ffplay.exe
set hashdeep=C:\Tools\hashdeep\hasdeep.exe
set hashit=c:\tools\hashit\hashit.exe
set ghostscript="C:\Program Files\gs\gs10.00.0\bin\gswin64.exe"
set magick=magick
set pdftk=c:\Tools\pdftk\pdftk.exe
set qpdf=C:\Tools\qpdf\bin\qpdf.exe
set tesseract=C:\Tools\Tesseract\Tesseract.exe
set vips=C:\Tools\vips\bin\vips.exe
set vipsthumbnail=C:\Tools\vips\bin\vipsthumbnail.exe
set wget=C:\Tools\wget\wget.exe

:: IDs and folder paths
set ItemID=%~n1
set SourceFolder=%~1
set ArchiveFolder=V:\Pergatory\LBRY\%ItemID:~0,2%\%ItemID:~2,2%\%ItemID:~4,2%\%ItemID:~6,2%\%ItemID:~-5%
set DestinationFolder=%SourceFolder%
set TempFolder=c:\temp\%~n1
set OCRin=%TempFolder%\ocr
set OCRout=%DestinationFolder%
set SCANin=c:\scans\raw
set SCANout=c:\scans\export
set UndoFolder=%~dp1UNDO\%~n1

:: Helper files
set XMPsidecar=%SourceFolder%\%ItemID%.xmp
set sRGBprofile=c:\tools\ICC\sRGB_v4_ICC_preference.icc
set EXIFReadTemplate=C:\tools\EXIFTool\templates\read_metadata_template.txt

:: Default imageprocessing parameters

:: JPEG derivative
set JPEGquality=30
set JPEGresize=10240

::Thumbnail
set THUMBresize=512
set THUMBquality=25

:: OCR maximum size
set OCRresize=8000

:: PDF display
set PDFquality=35
set PDFcompress=JPEG
set PDFresample=200
set PDFresize=3172
set PDFheight=3172


@echo Script variables:
@echo ItemID            - %ItemID%
@echo SourceFolder      - %SourceFolder%
@echo DestinationFolder - %DestinationFolder%
@echo TempFolder        - %TempFolder%
@echo SCANin            - %SCANin%
@echo SCANout           - %SCANout%
@echo OCRin             - %OCRin%
@echo OCRout            - %OCRout%
@echo UndoFolder        - %UndoFolder%
@echo ArchiveFolder     - %ArchiveFolder%

:: Remove unwanted files
@rmdir /s /q "%SourceFolder%\Color" 2> nul
@rmdir /s /q "%SourceFolder%\thumb" 2> nul
@rmdir /s /q "%SourceFolder%\tmpFilename" 2> nul
@rmdir /s /q "%SourceFolder%\undo" 2> nul
@del "%SourceFolder%\*.OIP" 2> nul
@del "%SourceFolder%\*.OIS" 2> nul
@del "%SourceFolder%\*.OJP" 2> nul
@del "%SourceFolder%\*.OJS" 2> nul

@echo Rename Images files 
%~d1
cd "%SourceFolder%"

:: Copy source files to Undo folder
REM  This could possibly be done with EXIFTool (in the same line as embedding metadata?).  Need to check with filename sorting on CIFS 

@echo Rename TIF files
@set /a counter=1
@set counterFormatted=0001
@for /f "tokens=*" %%f in ('robocopy "%SourceFolder%" NULL *.tif /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do @(
  @set counterFormatted=0000!counter!
  @rename "%%f" "%ItemID%-!counterFormatted:~-5!.tif"
  @set /a counter = !counter! + 1
)

@echo Rename DNG files
@set /a counter=1
@set counterFormatted=00001
@for /f "tokens=*" %%f in ('robocopy "%SourceFolder%" NULL *.dng /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do @(
  @set counterFormatted=0000!counter!
  @rename "%%f" "%ItemID%-!counterFormatted:~-5!.dng"
  @set /a counter = !counter! + 1
)

@echo Rename JPG files
@set /a counter=1
@set counterFormatted=00001
@for /f "tokens=*" %%F in ('robocopy "%SourceFolder%" NULL *.jpg /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do (
  @set counterFormatted=0000!counter!
  @rename "%%F" "%ItemID%-!counterFormatted:~-5!.jpg"
  @set /a counter = !counter! + 1
)

@echo Move images into subfolders by filetype AND embed metadata from XMP sidecar file if the sidecar file exists

@for /f "tokens=*" %%F in ('robocopy "%SourceFolder%" NULL *.tif *.dng *.jpg /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do (
  IF EXIST "%SourceFolder%\%ItemID%.xmp" (
     %exiftool% -directory="%DestinationFolder%\%%~xF" -TagsFromFile "%SourceFolder%\%ItemID%.xmp" -overwrite_original %%F ) ELSE (
	 %exiftool% -directory="%DestinationFolder%\%%~xF"  -overwrite_original %%F )
  )