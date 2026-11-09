@echo off
cd /d "%~dp0"
perl custom_tools\text\dialogue_insert.pl
perl custom_tools\text\executable_insert.pl
pause
