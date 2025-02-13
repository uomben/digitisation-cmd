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
@set "PDFcompress=JPEG"
@set "PDFresample=200"
@set "PDFresize=3172"
@set "PDFheight=3172"

:: Display local variables for debugging
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
%magick% "%%a[0]" -auto-orient -resample %PDFresample% -unsharp 1.5x1+0.7+0.02 -colorspace sRGB -profile "%sRGBprofile%"-depth 8 -compress JPEG -quality 35 "%OCRin%\%%~na_img.pdf"

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
