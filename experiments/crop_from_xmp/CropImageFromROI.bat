@setlocal ENABLEDELAYEDEXPANSION
:: This script crops an image using the coordinates read from an XMP sidecar file.  If no sidecar file exists the full size image is processed.
:: Drag and drop source is an image file.
:: Crop variables stored as xmp-mwg-rs (normalised percentages) and converted to pixel coordinates for all values as Imagemagick requires pixels for the crop offset.

::=============================================
:: Customisable processing presets 
::=============================================

:: JPEG derivative
@set "resize=2048"
@set "jpg_quality=65"

::Thumbnail
@set "thumb_size=512"
@set "thumb_quality=25"

:: OCR maximum size
@set "ocr_maxsize=8000"

:: PDF display
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
@set "in_file=%1"
@set "in_fileN=%~n1"

@set "itemid=%itemid:~0,17%"
@set "in_dir=%~dp1"
@set "in_dir=%in_dir:~0,-1%"
::
@set "archive_dir=V:\Pergatory\PRNT\%itemid:~0,4%\%itemid:~5,4%\%itemid:~10,3%\%itemid:~14,3%\%itemid:~17,5%"
@set "out_dir=%in_dir%"
@set "temp_dir=c:\temp\%~n1"
@set "ocr_in=%temp_dir%\ocr"
@set "ocr_out=%out_dir%"
@set "scan_in=c:\scans\raw"
@set "scan_out=c:\scans\export"
@set "undo_dir=%~dp1UNDO\%~n1"

:: Helper files
@set "exif_template=C:\tools\EXIFTool\templates\read_metadata_template.txt"
@set "xmp_file=%~dpn1.xmp"
@set "xmp_item=%archive_dir%\%itemid%-item.xmp"
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

::Run CMD from c:\temp unless otherwise specified
@cd /d c:\temp

::=============================================
:: Begin script
::=============================================

:: Define empty crop variable for images without an XMP sidecar
IF NOT EXIST %xmp_file% ( SET "im_crop="
) ELSE (
   :: set crop parameters from file-level XMP sidecar file if it exists and image dimensions
   FOR /F "tokens=*" %%G IN ('%exiftool% -ImageWidth -s3  %in_file%') do (SET "ImageWidth=%%G")
   FOR /F "tokens=*" %%G IN ('%exiftool% -ImageHeight -s3  %in_file%') do (SET "ImageHeight=%%G")
   FOR /F "tokens=*" %%G IN ('%exiftool% -p "${RegionAreaW;$_*=!Imagewidth!}" %xmp_file%') do (SET  /a "RegionAreaW=%%G")
   FOR /F "tokens=*" %%G IN ('%exiftool% -p "${RegionAreaH;$_*=!ImageHeight!}" %xmp_file%') do (SET  /a "RegionAreaH=%%G")
   FOR /F "tokens=*" %%G IN ('%exiftool% -p "${RegionAreaX;$_*=!Imagewidth!}" %xmp_file%') do (SET  /a "RegionAreaX=%%G")
   FOR /F "tokens=*" %%G IN ('%exiftool% -p "${RegionAreaY;$_*=!ImageHeight!}" %xmp_file%') do (SET  /a "RegionAreaY=%%G")

   set /a "OffsetX=(!RegionAreaX! * 2 - !RegionAreaW!) / 2"
   set /a "OffsetY=(!RegionAreaY! * 2 - !RegionAreaH!) / 2"

   set "im_crop=-crop !RegionAreaW!x!RegionAreaH!+!OffsetX!+!OffsetY!"
)

::Crop the image
%magick% "%in_file%[0]" -auto-orient %im_crop% -resize %resize%x%resize%^> -unsharp 1.5x1+0.7+0.02 -colorspace sRGB -profile "%srgb_profile%" -depth 8 -compress JPEG -quality %jpg_quality% "%out_dir%\%in_fileN%.jpg"

::Update the metadata
if exist "%xmp_item%" (
%exiftool% -tagsfromfile "%xmp_item%" -all:all -overwrite_original "%out_dir%\%in_fileN%_%resize%.jpg"
)

exit
