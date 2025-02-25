@setlocal ENABLEDELAYEDEXPANSION

::Run CMD from c:\temp unless otherwise specified
@c:
@cd\temp

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
@set "vipsthumbnail=C:\Tools\vips\bin\vipsthumbnail.exe"
@set "wget=C:\Tools\wget\wget.exe"

:: Helper files
@set "XMPsidecar=%SourceFolder%\%ItemID%.xmp"
@set "sRGBprofile=c:\tools\srgb\sRGB_v4_ICC_preference.icc"

::=============================================
:: Local variables
::=============================================
:: IDs and folder paths
@set "ItemID=%~n1"
@set "SourceFolder=%~1"
@set "ArchiveFolder=V:\Pergatory\LBRY\%ItemID:~0,2%\%ItemID:~2,2%\%ItemID:~4,2%\%ItemID:~6,2%\%ItemID:~-5%"
@set "DestinationFolder=%SourceFolder%"
@set "TempFolder=c:\temp\%~n1"
@set "OCRin=%TempFolder%\ocr"
@set "OCRout=%DestinationFolder%"
@set "SCANin=c:\scans\raw"
@set "SCANout=c:\scans\export"
@set "UndoFolder=%~dp1UNDO\%~n1"

:: Helper files
@set "EXIFReadTemplate=C:\tools\EXIFTool\templates\read_metadata_template.txt"

:: Default imageprocessing parameters

:: JPEG derivative
@set "JPEGquality=30"
@set "JPEGresize=10240"

::Thumbnail
@set "THUMBresize=512"
@set "THUMBquality=25"

:: OCR maximum size
@set "OCRresize=8000"

:: PDF display
@set "PDFquality=35"
:: Compress options: 
:: Colour/Greyscale: JPEG, JPEG2000, ZIP
:: Bitonal BW: Group4
@set "PDFcompress=JPEG"
@set "PDFresample=200"
@set "PDFresize=3172"
@set "PDFheight=3172"

:: Display local variables for debugging
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

:: Run commands from the source folder
@echo Rename Images files 
@%~d1
@cd "%SourceFolder%"

:: Copy source files to Undo folder
robocopy "%SourceFolder%" "%UndoFolder%" *.* /s /w:5

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
:: Relocate files and embed metadata
@echo Move images into subfolders by filetype AND embed metadata from XMP sidecar file if the sidecar file exists

:: Move TIFs
@for /f "tokens=*" %%F in ('robocopy "%SourceFolder%" NULL *.tif /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do (
  @IF NOT EXIST "%DestinationFolder%\tif" (mkdir "%DestinationFolder%\tif")
  IF EXIST "%XMPsidecar%" (
     %exiftool% -directory="%DestinationFolder%\tif" -TagsFromFile "%XMPsidecar%" -overwrite_original %%F ) ELSE (
	 move %%F "%DestinationFolder%\tif" )
  )
  
:: Move JPGs
@for /f "tokens=*" %%F in ('robocopy "%SourceFolder%" NULL *.jpg /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do (
  @IF NOT EXIST "%DestinationFolder%\jpg" (mkdir "%DestinationFolder%\jpg")
  IF EXIST "%XMPsidecar%" (
     %exiftool% -directory="%DestinationFolder%\jpg" -TagsFromFile "%XMPsidecar%" -overwrite_original %%F ) ELSE (
	 move %%F "%DestinationFolder%\jpg" )
  )

:: Move DNGs
@for /f "tokens=*" %%F in ('robocopy "%SourceFolder%" NULL *.dng /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do (
  @IF NOT EXIST "%DestinationFolder%\dng" (mkdir "%DestinationFolder%\dng")
  IF EXIST "%XMPsidecar%" (
     %exiftool% -directory="%DestinationFolder%\dng" -TagsFromFile "%XMPsidecar%" -overwrite_original %%F ) ELSE (
	 move %%F "%DestinationFolder%\dng" )
  )
:: OCR processes

:: Prepare temp and output directory
@mkdir %OCRin%  2> nul
@mkdir %OCRout%  2> nul

for /f "tokens=*" %%a in  ('robocopy "%SourceFolder%\tif" NULL *.tif /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') DO (
:: Clean BW image for OCR
%magick% ^( "%%a[0]" -auto-orient -colorspace gray -type grayscale -contrast-stretch 0 ^) ^( -clone 0 -colorspace gray -negate -lat 15x15+10%% -contrast-stretch 0 ^) -compose copy_opacity -composite -fill "white" -opaque none -alpha Off -sharpen 0x1 "%OCRin%\%%~na_bw.tif"

:: OCR image - PDF is text only, no image
%tesseract% "%OCRin%\%%~na_bw.tif" "%OCRin%\%%~na" --psm 3 -c textonly_pdf=1 pdf txt alto hocr

:: Make Image PDF for display - set output size/quality here
%magick% "%%a[0]" -auto-orient -resample %PDFresample% -unsharp 1.5x1+0.7+0.02 -colorspace sRGB -profile "%sRGBprofile%" -depth 8 -compress JPEG -quality 35 "%OCRin%\%%~na_img.pdf"

:: Merge text and image PDF
%pdftk% "%OCRin%\%%~na.pdf" background "%OCRin%\%%~na_img.pdf" output "%OCRin%\%%~na_merged.pdf"
)
@echo Merge PDF
%pdftk% "%OCRin%\%ItemID%*_merged.pdf" cat output "%OCRin%\%ItemID%_combined.pdf" dont_ask

@echo Embed metadata in merged PDF file from XMP
IF EXIST %XMPsidecar% %exiftool% -tagsFromFile "%XMPsidecar%" -overwrite_original "%OCRin%\%ItemID%_combined.pdf" 

@echo Linearise PDF 
%qpdf%  --linearize "%OCRin%\%ItemID%_combined.pdf" "%OCRout%\%ItemID%.pdf"

@echo Make thumbnail of PDF
:: Relocated to Create Derivatives sub-template

robocopy "%TempFolder%" "%DestinationFolder%\thumb_pdf" "%ItemID%.jpg" /MOV /W:5

@echo Move non-image outputs into filetype-based subfolders

%exiftool% -directory="%OCRout%\%ItemID%_alto_xml" -overwrite_original "%OCRin%\*.xml" 
%exiftool% -directory="%OCRout%\%ItemID%_txt" -overwrite_original "%OCRin%\*.txt" 
%exiftool% -directory="%OCRout%\%ItemID%_hocr" -overwrite_original "%OCRin%\*.hocr"

@echo Create a composite text file
@del "%DestinationFolder%\%ItemID%_ocr.txt" 2> nul
FOR %%f IN ("%OCRout%\%ItemID%_txt\*.txt") DO type %%f >> "%OCRout%\%ItemID%_ocr.txt"


@echo Cleanup temporary files

:: skip cleanup during testing to allow checking of intermediate files
goto skipcleanup
rmdir /s /q %OCRin%

:skipcleanup

:: Pause to debug screen output during development
pause

:: Make JPEG derivatives
for /f "tokens=*" %%a in  ('robocopy "%DestinationFolder%" NULL *.tif /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') DO (
    %magick% "%%a[0]" -auto-orient -resize %JPEGresize%^> -unsharp 1.5x1+0.7+0.02 -colorspace sRGB -profile "%sRGBprofile%" -depth 8 -compress JPEG -quality %JPEGquality% "%DestinationFolder%\jpg\%%~na.jpg"
)

:: Make Thumbnails for TIF
for /f "tokens=*" %%a in  ('robocopy "%DestinationFolder%" NULL *.tif *.pdf /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') DO (
    %magick% "%%a[0]" -auto-orient -resize %THUMBresize%^> -unsharp 0x1 -colorspace sRGB -profile "%sRGBprofile%" -depth 8 -compress JPEG -quality %THUMBquality% "%DestinationFolder%\thumb_tif\%%~na.jpg"
)

:: Make Thumbnails for PDF
for /f "tokens=*" %%a in  ('robocopy "%DestinationFolder%" NULL *.tif *.pdf /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') DO (
    %magick% "%%a[0]" -auto-orient -resize %THUMBresize%^> -unsharp 0x1 -colorspace sRGB -profile "%sRGBprofile%" -depth 8 -compress JPEG -quality %THUMBquality% "%DestinationFolder%\thumb_pdf\%%~na.jpg"
)

:: Make Thumbnails for DNG (additional  -auto-level step)
for /f "tokens=*" %%a in  ('robocopy "%DestinationFolder%" NULL *.dng /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') DO (
    %magick% "%%a[0]" -auto-orient -auto-level -resize %THUMBresize%^> -unsharp 0x1 -colorspace sRGB -profile "%sRGBprofile%" -depth 8 -compress JPEG -quality %THUMBquality% "%DestinationFolder%\thumb_dng\%%~na.jpg"
):: list files
@echo Post-processing data gathering
robocopy "%DestinationFolder%" NULL /S /L /NDL /NC /LOG:"%TempFolder%\%ItemID%_files.txt" /TEE /NJH /NJS /BYTES /NODD /XD meta thumb*

robocopy "%TempFolder%" "%DestinationFolder%\meta" "%ItemID%_files.txt" /w:5

:: Compress non-PDF per-image OCR outputs

@echo Create a tar.gz for per-image OCR outputs 
:: ALTO XML
tar -cvzf "%OCRout%\%ItemID%_alto_xml.tar.gz" -C "%OCRout%" "%ItemID%_ocr_alto_xml" 
rmdir /s /q "%OCRout%\%ItemID%_alto_xml"

:: hOCR
tar -cvzf "%OCRout%\%ItemID%_hocr.tar.gz" -C "%OCRout%" "%ItemID%_ocr_hocr" 
rmdir /s /q "%OCRout%\%ItemID%_hocr"

:: Text
tar -cvzf "%OCRout%\%ItemID%_txt.tar.gz" -C "%OCRout%" "%ItemID%_ocr_txt" 
rmdir /s /q "%OCRout%\%ItemID%_txt"

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