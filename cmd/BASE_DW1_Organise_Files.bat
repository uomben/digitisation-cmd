@setlocal ENABLEDELAYEDEXPANSION

::=============================================
:: Customisable processing presets 
::=============================================

:: Image derivatives
@set "resize=10240"
@set "resample=200"

:: JPEG derivative
@set "jpg_quality=30"

::Thumbnail
@set "thumb_size=512"
@set "thumb_quality=25"

:: OCR maximum size
@set "ocr_maxsize=8000"

:: PDF 
@set "pdf_quality=35"
:: Compress options: 
:: Colour/Greyscale: JPEG, JPEG2000, ZIP
:: Bitonal BW: Group4
@set "pdf_compress=JPEG"
@set "pdf_resample=200"
@set "pdf_resize=3172"
@set "pdf_height=3172"

::=============================================
:: Local variables
::=============================================
:: IDs and folder paths
@set "itemid=%~n1"
@set "in_dir=%~1"
@set "archive_dir=V:\Pergatory\LBRY\%itemid:~0,2%\%itemid:~2,2%\%itemid:~4,2%\%itemid:~6,2%\%itemid:~-5%"
@set "out_dir=%in_dir%"
@set "temp_dir=c:\temp\%~n1"
@set "ocr_in=%temp_dir%\ocr"
@set "ocr_out=%out_dir%"
@set "scan_in=c:\scans\raw"
@set "scan_out=c:\scans\export"
@set "undo_dir=%~dp1UNDO\%~n1"

:: Helper files
@set "exif_template=C:\tools\EXIFTool\templates\read_metadata_template.txt"
@set "xmp_item=%in_dir%\%itemid%.xmp"
@set "srgb_profile=c:\tools\srgb\sRGB_v4_ICC_preference.icc"

::=============================================
:: Global variables
::=============================================
:: Utililty paths
@set "7zip=C:\Tools\7zip\7za.exe"
@set "b64=C:\Tools\b64\b64.exe"
@set "exiftool=c:\Tools\EXIFTool\EXIFTool.exe"
@set "ffmpeg=C:\Tools\ffmpeg\bin\ffmpeg.exe"
@set "ffplay=C:\Tools\ffmpeg\bin\ffplay.exe"
@set "hashdeep=C:\Tools\hashdeep\hasdeep.exe"
@set "hashit=c:\tools\hashit\hashit.exe"
@set "ghostscript="C:\Program Files\gs\gs10.00.0\bin\gswin64.exe""
@set "magick=magick"
@set "pdftk=c:\Tools\pdftk\pdftk.exe"
@set "qpdf=C:\Tools\qpdf\bin\qpdf.exe"
@set "tesseract=C:\Tools\Tesseract\Tesseract.exe"
@set "vips=C:\Tools\vips\bin\vips.exe"
@set "vipsheader=C:\Tools\vips\bin\vipsheader.exe"
@set "vipsthumbnail=C:\Tools\vips\bin\vipsthumbnail.exe"
@set "wget=C:\Tools\wget\wget.exe"


:: Display local variables for debugging
@echo Script variables:
@echo itemid        - %itemid%
@echo in_dir        - %in_dir%
@echo out_dir       - %out_dir%
@echo temp_dir      - %temp_dir%
@echo scan_in       - %scan_in%
@echo scan_out      - %scan_out%
@echo ocr_in        - %ocr_in%
@echo ocr_out       - %ocr_out%
@echo undo_dir      - %undo_dir%
@echo archive_dir   - %archive_dir%

::Run CMD from c:\temp unless otherwise specified

@cd /d c:\temp

:: Remove unwanted files
@rmdir /s /q "%in_dir%\Color" 2> nul
@rmdir /s /q "%in_dir%\thumb" 2> nul
@rmdir /s /q "%in_dir%\tmpFilename" 2> nul
@rmdir /s /q "%in_dir%\undo" 2> nul
@del "%in_dir%\*.OIP" 2> nul
@del "%in_dir%\*.OIS" 2> nul
@del "%in_dir%\*.OJP" 2> nul
@del "%in_dir%\*.OJS" 2> nul

:: Run commands from the source folder
@echo Rename Images files 
@cd / d "%in_dir%"

:: Copy source files to Undo folder
robocopy "%in_dir%" "%undo_dir%" *.* /s /w:5

@echo Rename TIF files
@set /a counter=1
@set counterFormatted=0001
@for /f "tokens=*" %%f in ('robocopy "%in_dir%" NULL *.tif /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do @(
  @set counterFormatted=0000!counter!
  @rename "%%f" "%itemid%-!counterFormatted:~-5!.tif"
  @set /a counter = !counter! + 1
)

@echo Rename DNG files
@set /a counter=1
@set counterFormatted=00001
@for /f "tokens=*" %%f in ('robocopy "%in_dir%" NULL *.dng /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do @(
  @set counterFormatted=0000!counter!
  @rename "%%f" "%itemid%-!counterFormatted:~-5!.dng"
  @set /a counter = !counter! + 1
)

@echo Rename JPG files
@set /a counter=1
@set counterFormatted=00001
@for /f "tokens=*" %%F in ('robocopy "%in_dir%" NULL *.jpg /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do (
  @set counterFormatted=0000!counter!
  @rename "%%F" "%itemid%-!counterFormatted:~-5!.jpg"
  @set /a counter = !counter! + 1
)
:: Relocate files and embed metadata
@echo Move images into subfolders by filetype AND embed metadata from XMP sidecar file if the sidecar file exists

:: Move TIFs
@for /f "tokens=*" %%F in ('robocopy "%in_dir%" NULL *.tif /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do (
  @IF NOT EXIST "%out_dir%\tif" (mkdir "%out_dir%\tif")
  IF EXIST "%xmp_item%" (
     %exiftool% -directory="%out_dir%\tif" -TagsFromFile "%xmp_item%" -overwrite_original %%F ) ELSE (
	 move %%F "%out_dir%\tif" )
  )
  
:: Move JPGs
@for /f "tokens=*" %%F in ('robocopy "%in_dir%" NULL *.jpg /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do (
  @IF NOT EXIST "%out_dir%\jpg" (mkdir "%out_dir%\jpg")
  IF EXIST "%xmp_item%" (
     %exiftool% -directory="%out_dir%\jpg" -TagsFromFile "%xmp_item%" -overwrite_original %%F ) ELSE (
	 move %%F "%out_dir%\jpg" )
  )

:: Move DNGs
@for /f "tokens=*" %%F in ('robocopy "%in_dir%" NULL *.dng /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do (
  @IF NOT EXIST "%out_dir%\dng" (mkdir "%out_dir%\dng")
  IF EXIST "%xmp_item%" (
     %exiftool% -directory="%out_dir%\dng" -TagsFromFile "%xmp_item%" -overwrite_original %%F ) ELSE (
	 move %%F "%out_dir%\dng" )
  )