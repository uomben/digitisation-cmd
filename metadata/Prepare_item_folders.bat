@setlocal ENABLEDELAYEDEXPANSION

::=============================================
:: Customisable processing presets 
::=============================================
@set "SourceFolder=%~dp0meta"
@set "DestinationFolder=C:\SCANS\ITEMS"
@set "CompletedFolder=%~dp0done"


::=============================================
:: Global variables
::=============================================
:: Utililty paths
@set "exiftool=c:\Tools\EXIFTool\EXIFTool.exe"

::Run CMD from c:\temp unless otherwise specified

@cd /d c:\temp

:: create XMP files and move the text files to the "completed" folder.
:: create desitnation folders if they don't exist

@for /f "tokens=*" %%F in ('robocopy "%SourceFolder%" NULL *.txt /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do (

	%exiftool% -@ %%F -o "%DestinationFolder%\%%~nF\%%~nF.xmp"
	robocopy "%SourceFolder%" "%CompletedFolder%" %%~nxF /mov /NJH /NJS 

)

