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

