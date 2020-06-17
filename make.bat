@echo off

REM The name portion of the top source file and all generated files
set SOURCE=mkboot

REM The location of 64TASS
set TASSHOME=d:\64tass

set OPTS=--long-address --flat -b
set DEST=--m65816 -o build\%SOURCE%.pgx
set AUXFILES=--list=build\%SOURCE%.lst --labels=build\%SOURCE%.lbl

%TASSHOME%\64tass %OPTS% %DEST% %AUXFILES% src\%SOURCE%.s
