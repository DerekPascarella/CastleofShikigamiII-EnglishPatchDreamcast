@echo off
cd /d "%~dp0"
perl custom_tools\asm\asm_patch.pl
perl custom_tools\misc\bootsector_patch.pl
pause
