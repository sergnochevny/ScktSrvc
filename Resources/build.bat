@echo off

REM Build strings.res
brcc32 tscktsrv.rc
if errorlevel 1 goto Fail

goto Exit

:Fail
echo Build failed.

:Exit
