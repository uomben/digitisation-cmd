@setlocal ENABLEDELAYEDEXPANSION
:: This script crops an image using the coordinates read from an XMP sidecar file.  If no sidecar file exists the full size image is processed.
:: Drag and drop source is an image file.
:: Crop parameter calculated in a powershell script (define_crop.ps1) because of limitations with using more than one field in a calculation with EXIFTool.
:: Requires define_crop.ps1 to be in the same location as the batch file.
:: Crop variables stored as xmp-mwg-rs (normalised percentages) and converted to pixel coordinates for all values as Imagemagick requires pixels for the crop offset.

::=============================================
:: Customisable processing presets 
::=============================================

:: JPEG derivative
@set "JPEGquality=65"
@set "JPEGresize=2048"

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

::=============================================
:: Local variables
::=============================================
:: IDs and folder paths
@set "ItemID=%~n1"
@set "filepath=%1"
@set "filenameN=%~n1"


@set "ItemID=%ItemID:~0,17%"
@set "SourceFolder=%~dp1"
@set "SourceFolder=%SourceFolder:~0,-1%"
::
@set "ArchiveFolder=V:\Pergatory\PRNT\%ItemID:~0,4%\%ItemID:~5,4%\%ItemID:~10,3%\%ItemID:~14,3%\%ItemID:~17,5%"
@set "DestinationFolder=%SourceFolder%"
@set "TempFolder=c:\temp\%~n1"
@set "OCRin=%TempFolder%\ocr"
@set "OCRout=%DestinationFolder%"
@set "SCANin=c:\scans\raw"
@set "SCANout=c:\scans\export"
@set "UndoFolder=%~dp1UNDO\%~n1"

:: Helper files
@set "EXIFReadTemplate=C:\tools\EXIFTool\templates\read_metadata_template.txt"
@set "sidecar=%1"
@set "XMPsidecar=%~dpn1.xmp"
@set "sRGBprofile=c:\tools\srgb\sRGB_v4_ICC_preference.icc"

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
@echo Filepath          - %filepath%
@echo FilenameID        - %filenameN%
@echo XMP sidecar       - %XMPsidecar%


::Run CMD from c:\temp unless otherwise specified
@cd /d c:\temp

:: Define empty crop variable for images without an XMP sidecar
SET "crop="

:: set crop parameters from file-level XMP sidecar file if it exists and image dimensions
If EXIST %XMPsidecar% (:: Pointless comment to push commands to the next line for readability
FOR /F "tokens=*" %%G IN ('%exiftool% -RegionAreaW -s3  %XMPsidecar%') do (SET "RegionAreaW=%%G")
FOR /F "tokens=*" %%G IN ('%exiftool% -RegionAreaH -s3  %XMPsidecar%') do (SET "RegionAreaH=%%G")
FOR /F "tokens=*" %%G IN ('%exiftool% -RegionAreaX -s3  %XMPsidecar%') do (SET "RegionAreaX=%%G")
FOR /F "tokens=*" %%G IN ('%exiftool% -RegionAreaY -s3  %XMPsidecar%') do (SET "RegionAreaY=%%G")
FOR /F "tokens=*" %%G IN ('%exiftool% -ImageWidth -s3  %filepath%') do (SET "ImageWidth=%%G")
FOR /F "tokens=*" %%G IN ('%exiftool% -ImageHeight -s3  %filepath%') do (SET "ImageHeight=%%G")

:: Call PowerShell script to calculate crop string and set the variable
for /f "delims=" %%i in ('powershell -ExecutionPolicy Bypass -File %~dp0define_crop.ps1 -RegionAreaW !RegionAreaW! -RegionAreaH !RegionAreaH! -RegionAreaX !RegionAreaX! -RegionAreaY !RegionAreaY! -ImageWidth !ImageWidth! -ImageHeight !ImageHeight!') do set "crop=%%i"
)

::Crop the image
%magick% "%filepath%[0]" -auto-orient %crop% -resize %JPEGresize%x%JPEGresize%^> -unsharp 1.5x1+0.7+0.02 -colorspace sRGB -profile "%sRGBprofile%" -depth 8 -compress JPEG -quality %JPEGquality% "%DestinationFolder%\%filenameN%_cropped.jpg"

exit
