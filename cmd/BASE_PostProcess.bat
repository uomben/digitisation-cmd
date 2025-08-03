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
:: OCR processes

:: Prepare temp and output directory
@mkdir %ocr_in%  2> nul
@mkdir %ocr_out%  2> nul

for /f "tokens=*" %%a in  ('robocopy "%in_dir%\tif" NULL *.tif /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') DO (
:: Clean BW image for OCR
%magick% ^( "%%a[0]" -auto-orient -colorspace gray -type grayscale -contrast-stretch 0 ^) ^( -clone 0 -colorspace gray -negate -lat 15x15+10%% -contrast-stretch 0 ^) -compose copy_opacity -composite -fill "white" -opaque none -alpha Off -sharpen 0x1 "%ocr_in%\%%~na_bw.tif"

:: OCR image - PDF is text only, no image
%tesseract% "%ocr_in%\%%~na_bw.tif" "%ocr_in%\%%~na" --psm 3 -c textonly_pdf=1 pdf txt alto hocr

:: Make Colour Image PDF for display - set output size/quality here
%magick% "%%a[0]" -auto-orient -resample %pdf_resample% -unsharp 1.5x1+0.7+0.02 -colorspace sRGB -profile "%srgb_profile%" -depth 8 -compress JPEG -quality 35 "%ocr_in%\%%~na_img.pdf"

:: Make BW Image PDF for display - set output size/quality here
%magick% "%ocr_in%\%%~na_bw.tif" -threshold 50 -depth 1 -compress Group4 "%ocr_in%\%%~na_bw.pdf"

:: Merge text and colour image PDF
%pdftk% "%ocr_in%\%%~na.pdf" background "%ocr_in%\%%~na_img.pdf" output "%ocr_in%\%%~na_merged.pdf"

:: Merge text and BW image PDF
%pdftk% "%ocr_in%\%%~na.pdf" background "%ocr_in%\%%~na_bw.pdf" output "%ocr_in%\%%~na_merged_bw.pdf"

)
@echo Merge Colour and BW PDF pages
%pdftk% "%ocr_in%\%itemid%*_merged.pdf" cat output "%ocr_in%\%itemid%_combined.pdf" dont_ask
%pdftk% "%ocr_in%\%itemid%*_merged_bw.pdf" cat output "%ocr_in%\%itemid%_combined_bw.pdf" dont_ask

@echo Embed metadata in merged PDF files from XMP
IF EXIST %xmp_item% %exiftool% -tagsFromFile "%xmp_item%" -overwrite_original "%ocr_in%\%itemid%_combined.pdf" 
IF EXIST %xmp_item% %exiftool% -tagsFromFile "%xmp_item%" -overwrite_original "%ocr_in%\%itemid%_combined_bw.pdf" 

@echo Linearise PDF 
:: ...without stripping the newly added metadata!!!
%qpdf%  --linearize "%ocr_in%\%itemid%_combined.pdf" "%ocr_out%\%itemid%.pdf"
%qpdf%  --linearize "%ocr_in%\%itemid%_bw_combined.pdf" "%ocr_out%\%itemid%_bw.pdf"

@echo Make thumbnail of PDF
:: Relocated to Create Derivatives sub-template

robocopy "%temp_dir%" "%out_dir%\thumb_pdf" "%itemid%.jpg" /MOV /W:5

@echo Move non-image outputs into filetype-based subfolders

%exiftool% -directory="%ocr_out%\%itemid%_alto_xml" -overwrite_original "%ocr_in%\*.xml" 
%exiftool% -directory="%ocr_out%\%itemid%_txt" -overwrite_original "%ocr_in%\*.txt" 
%exiftool% -directory="%ocr_out%\%itemid%_hocr" -overwrite_original "%ocr_in%\*.hocr"

@echo Create a composite text file
@del "%out_dir%\%itemid%_ocr.txt" 2> nul
FOR %%f IN ("%ocr_out%\%itemid%_txt\*.txt") DO type %%f >> "%ocr_out%\%itemid%_ocr.txt"


@echo Cleanup temporary files

:: uncomment goto to skip cleanup during testing to allow checking of intermediate files
:: goto skipcleanup
rmdir /s /q %ocr_in%

:skipcleanup


:: Make JPEG derivatives
for /f "tokens=*" %%a in  ('robocopy "%out_dir%" NULL *.tif /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') DO (
    %magick% "%%a[0]" -auto-orient -resize %resize%^> -unsharp 1.5x1+0.7+0.02 -colorspace sRGB -profile "%srgb_profile%" -depth 8 -compress JPEG -quality %jpg_quality% "%out_dir%\jpg\%%~na.jpg"
)

:: Make Thumbnails for TIF
for /f "tokens=*" %%a in  ('robocopy "%out_dir%" NULL *.tif *.pdf /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') DO (
    %magick% "%%a[0]" -auto-orient -resize %thumb_size%^> -unsharp 0x1 -colorspace sRGB -profile "%srgb_profile%" -depth 8 -compress JPEG -quality %thumb_quality% "%out_dir%\thumb_tif\%%~na.jpg"
)

:: Make Thumbnails for PDF
for /f "tokens=*" %%a in  ('robocopy "%out_dir%" NULL *.tif *.pdf /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') DO (
    %magick% "%%a[0]" -auto-orient -resize %thumb_size%^> -unsharp 0x1 -colorspace sRGB -profile "%srgb_profile%" -depth 8 -compress JPEG -quality %thumb_quality% "%out_dir%\thumb_pdf\%%~na.jpg"
)

:: Make Thumbnails for DNG (additional  -auto-level step)
for /f "tokens=*" %%a in  ('robocopy "%out_dir%" NULL *.dng /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') DO (
    %magick% "%%a[0]" -auto-orient -auto-level -resize %thumb_size%^> -unsharp 0x1 -colorspace sRGB -profile "%srgb_profile%" -depth 8 -compress JPEG -quality %thumb_quality% "%out_dir%\thumb_dng\%%~na.jpg"
):: list files
@echo Post-processing data gathering
robocopy "%out_dir%" NULL /S /L /NDL /NC /LOG:"%temp_dir%\%itemid%_files.txt" /TEE /NJH /NJS /BYTES /NODD /XD meta thumb*

robocopy "%temp_dir%" "%out_dir%\meta" "%itemid%_files.txt" /w:5

:: Compress non-PDF per-image OCR outputs

@echo Create a tar.gz for per-image OCR outputs 
:: ALTO XML
tar -cvzf "%ocr_out%\%itemid%_alto_xml.tar.gz" -C "%ocr_out%" "%itemid%_ocr_alto_xml" 
rmdir /s /q "%ocr_out%\%itemid%_alto_xml"

:: hOCR
tar -cvzf "%ocr_out%\%itemid%_hocr.tar.gz" -C "%ocr_out%" "%itemid%_ocr_hocr" 
rmdir /s /q "%ocr_out%\%itemid%_hocr"

:: Text
tar -cvzf "%ocr_out%\%itemid%_txt.tar.gz" -C "%ocr_out%" "%itemid%_ocr_txt" 
rmdir /s /q "%ocr_out%\%itemid%_txt"

:: Collect EXIF metadata and checksums
@echo Collect EXIF metadata

@del "%out_dir%\meta\%itemid%_exif.txt"
%exiftool% -m -s -r -q -p "%exif_template%" "%out_dir%" > "%temp_dir%\%itemid%_exif.txt" 
robocopy %temp_dir% "%out_dir%\meta" %itemid%_exif.txt /MOV

@echo Collect checksums

@del "%out_dir%\%itemid%_chksum.xml"
%hashdeep% -c md5,sha256 -r -d "%out_dir%\*.*" > "%temp_dir%\%itemid%_chksum.xml"
robocopy "%temp_dir%" "%out_dir%" %itemid%_chksum.xml /MOV
@echo Cleanup temp folder
:: disabled for testing/debugging
:: rmdir /s /q "%temp_dir%"