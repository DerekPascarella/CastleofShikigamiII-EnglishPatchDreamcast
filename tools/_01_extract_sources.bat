@echo off
cd /d "%~dp0"
if not exist gdi_orig\*.gdi (
	echo Put the original Shikigami no Shiro II GDI files in the gdi_orig folder first.
	pause
	exit /b
)
set patched_gdi=
if exist "gdi_patched\disc.gdi" set "patched_gdi=disc.gdi"
if exist "gdi_patched\Shikigami no Shiro II v1.002 (2004)(Alfa System)(JP)[!].gdi" set "patched_gdi=Shikigami no Shiro II v1.002 (2004)(Alfa System)(JP)[!].gdi"
if not defined patched_gdi (
	echo Put the patched English GDI files in the gdi_patched folder first.
	pause
	exit /b
)
for %%d in (gdi gdi_extracted gdi_orig_extracted gdi_patched_extracted bootsector) do (
	if exist %%d rmdir /s /q %%d
	mkdir %%d
)
echo Copying gdi_orig to gdi...
copy /y gdi_orig\* gdi\ >nul
for %%f in (gdi\*.gdi) do if /i not "%%~nxf"=="disc.gdi" ren "%%f" disc.gdi
echo Extracting the GDI files...
tools\gditools.exe -i "gdi\disc.gdi" --data-folder "..\gdi_orig_extracted" -b "..\bootsector\IP.BIN" --extract-all --silent
xcopy /e /i /q /y gdi_orig_extracted gdi_extracted >nul
echo Extracting the patched GDI files...
tools\gditools.exe -i "gdi_patched\%patched_gdi%" --data-folder "..\gdi_patched_extracted" --extract-all --silent
perl custom_tools\misc\extract_patch.pl
echo:
echo Extraction complete!
pause
