SET $folder=%CD%

@echo off
FOR /f %%G IN ('dir /b /o:n "%$folder%\*.cso" ') DO (call :decompile %%G)

GOTO :eof

:decompile
SETLOCAL
SET $file=%1
SET $stage=frag
IF %$file:~0,2%==cs (
  SET $stage=comp
)

cmd_Decompiler.exe -d "%$folder%\%$file%"