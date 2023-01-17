@echo off
echo Type in the folder path you want to put the single language lpu:
echo e.g.:C:\Users\AnZhou\Downloads\temp\LSReview
echo This folder should also contain the old lpu (named like'old_All_Moldflow.lpu' and new lpu (named like'new_All_Moldflow.lpu'

set /p folder=folder path: e.g. C:\Users\AnZhou\Downloads\temp\LSReview
for %%i in (chs, cht, fra, deu, ita,jpn,kor,ptg,esn) do pslcmd.exe /openproject:%folder%\LPUs_Only\%%i_All_Moldflow_ForLSReview.lpu /runmacro=ManageRepetitions.bas
start /b /wait python Omniscript.py %folder%\LPUs_Only\ %folder%\ForALQM\
echo all the process done! You can find the csv files in the folder ForALQM
pause
