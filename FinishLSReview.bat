@echo off
echo Type in the folder path you want to put the single language lpu:
echo e.g.:C:\Users\AnZhou\Downloads\temp\LSReview
echo This folder should also contain the old lpu (named like'old_All_Moldflow.lpu' and new lpu (named like'new_All_Moldflow.lpu'

@REM set lan=(cht)
@REM set lan=(fra,deu,ita,ptg,esn)
set lan=(chs,cht,fra,deu,ita,jpn,kor,ptg,esn)
set /p folder=folder path: e.g. C:\Users\AnZhou\Downloads\temp\LSReview
@REM start /b /wait python prepare_folders.py --path=%folder% --lan=%lan%
@REM echo multi-language lpu files done copying
@REM echo start removing extra languages from lpu, this may take a while...
@REM for %%i in %lan% do pslcmd.exe /openproject:%folder%\%%i\new\%%i_All_Moldflow.lpu /runmacro=Remove_langs_from_project.bas & pslcmd.exe /openproject:%folder%\%%i\old\%%i_All_Moldflow.lpu /runmacro=Remove_langs_from_project.bas
@REM echo all the extra languages have been successfully removed from lpus
pause
@REM for %%i in %lan% do DiffLpuWrapper.bat "%folder%\%%i\old" "%folder%\%%i\new" %%i
start /b /wait python moving_LPUs.py --path=%folder% --lan=%lan%
echo all the for_review lpus moved to 'LPUs_Only' folder, press any key to start removing repetition from LPUs(LPUs should not exported)
pause
for %%i in %lan% do pslcmd.exe /openproject:%folder%\LPUs_Only\%%i\%%i_All_Moldflow_ForLSReview.lpu /runmacro=HideForReviewRepetitions.bas
start /b /wait python Omniscript.py %folder%\LPUs_Only\ %folder%\ForALQM\
echo all the process done! You can find the csv files in the folder ForALQM
pause
