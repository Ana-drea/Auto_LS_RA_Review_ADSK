@echo off
echo Type in the folder path you want to put the single language lpu:
echo e.g.:C:\Users\AnZhou\Downloads\temp\LSReview
echo This folder should also contain the old lpu (named like'old_All_Moldflow.lpu' and new lpu (named like'new_All_Moldflow.lpu'

set lan=(ptb,trk,plk)
set /p folder=folder path: e.g. C:\Users\AnZhou\Downloads\temp\LSReview
@REM start /b /wait python prepare_folders_SIM_MAT.py --path=%folder% --lan=%lan%
@REM echo muilt-language lpu files done copying
@REM echo start removing extra languages from lpu, this may take a while...
@REM for %%i in %lan% do pslcmd.exe /openproject:%folder%\%%i\new\%%i_All_SIM_MAT.lpu /runmacro=Remove_langs_from_project.bas & pslcmd.exe /openproject:%folder%\%%i\old\%%i_All_SIM_MAT.lpu /runmacro=Remove_langs_from_project.bas
@REM echo all the extra languages have been successfully removed from lpus
@REM mshta vbscript:msgbox("all the extra languages have been successfully removed from lpus, please go and check before proceeding to create creating for_review lpus",64,"Notification")(window.close)
@REM pause
@REM for %%i in %lan% do DiffLpuWrapper.bat "%folder%\%%i\old" "%folder%\%%i\new" %%i
start /b /wait python moving_LPUs.py --path=%folder% --lan=%lan%
echo all the for_review lpus moved to 'LPUs_Only' folder, press any key to start creating files for LS review(LPUs should not exported)
@REM echo but exported LPUs seem to generate needed files ok?
pause
@REM for %%i in %lan% do pslcmd.exe /openproject:%folder%\LPUs_Only\%%i\%%i_All_SIM_MAT_ForLSReview.lpu /runmacro=HideForReviewRepetitions.bas
start /b /wait python Omniscript.py %folder%\LPUs_Only\ %folder%\ForALQM\
echo all the process done! You can find the csv files in the folder ForALQM
pause
