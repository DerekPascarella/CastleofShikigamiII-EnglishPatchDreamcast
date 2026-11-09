@echo off
mode con:cols=56 lines=15
cd tools
echo GDI build in progress!
echo:
buildgdi.exe -data "..\gdi_extracted" -ip "..\bootsector\IP.BIN" -output "..\gdi" -gdi "..\gdi\disc.gdi" -raw
echo:
pause