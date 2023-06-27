@echo off
echo Type in the folder path you want to put the single language lpu:
echo e.g.:C:\Users\AnZhou\Downloads\temp\RA\Nastran
echo This folder should also contain the old lpu (named like'old_All_Nastran_InCAD.lpu' and new lpu (named like'new_All_Nastran_InCAD.lpu'

set /p folder=folder path: e.g. C:\Users\AnZhou\Downloads\temp\RA\Nastran
set /p build=Type in the build number, e.g.: 45.0.46
start /b /wait python prepare_RA_folders.py --path=%folder% --project=Nastran
echo muilt-language lpu files done copying
@REM echo start removing extra languages from lpu, this may take a while...
@REM for %%i in (chs, cht, fra, deu, ita,jpn,kor) do pslcmd.exe /openproject:%folder%\%%i\CurrentReleaseLpu\%%i_All_Nastran_InCAD.lpu /runmacro=Remove_langs_from_project.bas & pslcmd.exe /openproject:%folder%\%%i\LastReleaseLpu\%%i_All_Nastran_InCAD.lpu /runmacro=Remove_langs_from_project.bas
@REM echo all the extra languages have been successfully removed from lpus, and mapping files have been created
@REM echo you can go and check before proceeding to create creating for_review lpus
@REM pause
for %%i in (chs, cht, fra, deu, ita,jpn,kor) do cSmoke_CommandLine --test=RA --user=andrea.zhou@rws.com --product=NSTRN --language=%%i --release=2024 --build=%build% --previouslpu="%folder%\%%i\LastReleaseLpu" --currentlpu="%folder%\%%i\CurrentReleaseLpu" --mappingfile="%folder%\%%i\CurrentReleaseLpu\mapping.txt" --enablelog=true
pause
