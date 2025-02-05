setlocal ENABLEDELAYEDEXPANSION

set "INdir=%~dp0\templates"
set "OUTdir=%~dp0\cmd"
@if not exist %OUTdir% (mkdir %OUTdir%)

for /f "tokens=*" %%G in ('robocopy "%INdir%" NULL *Header.txt /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS') do (

  set "tmp=%%~nG"
  set "prefix=!tmp:~0,4!"
  set "header=%%~nxG"
  set "composite=!tmp:~0,-7!

  :: Create batch files combining the header and individual scripts
  for /f "tokens=*" %%H in ('robocopy "%INdir%" NULL !prefix!*.txt /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS /XF "!header!"') do (
      type "%%G" > %OUTdir%\%%~nH.bat
      type "%%~H" >> %OUTdir%\%%~nH.bat
    )

  :: Create batch files combining the header and individual scripts into a single script
  type "%%G" > %OUTdir%\!composite!.bat
  for /f "tokens=*" %%H in ('robocopy "%INdir%" NULL !prefix!*.txt /S /L /NDL /NC /TEE /NJH /NJS /NODD /NS /XF "!header!"') do (
      type "%%~H" >> %OUTdir%\!composite!.bat
    )
	
  :: Create batch file for debugging variables
  type %%G > %OUTdir%\headers\!prefix!_VariableCheck.bat
  echo pause >> %OUTdir%\headers\!prefix!_VariableCheck.bat
)
