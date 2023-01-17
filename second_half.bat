@echo off
@REM set /p folder=folder path: e.g. C:\Users\AnZhou\Downloads\temp\LSReview
@REM start /b /wait python moving_LPUs.py --path=%folder%
@REM start /b /wait python Omniscript.py %folder%\LPUs_Only\ %folder%\ForALQM\
@REM pause

@echo off
echo Type in the folder path you want to put the single language lpu:
echo e.g.:C:\Users\AnZhou\Downloads\temp\LSReview
echo This folder should also contain the old lpu (named like'old_All_Moldflow.lpu' and new lpu (named like'new_All_Moldflow.lpu'

set /p folder=folder path: e.g. C:\Users\AnZhou\Downloads\temp\LSReview
@REM start /b /wait python prepare_folders.py --path=%folder%
@REM echo muilt-language lpu files done copying
@REM echo start removing extra languages from lpu, this may take a while...
@REM for %%i in (chs, cht, fra, deu, ita,jpn,kor,ptg,esn) do pslcmd.exe /openproject:%folder%\%%i\new\%%i_All_Moldflow.lpu /runmacro=Remove_langs_from_project.bas & pslcmd.exe /openproject:%folder%\%%i\old\%%i_All_Moldflow.lpu /runmacro=Remove_langs_from_project.bas
@REM echo all the extra languages have been successfully removed from lpus
@REM mshta vbscript:msgbox("all the extra languages have been successfully removed from lpus, please go and check before proceeding to create creating for_review lpus",64,"Notification")(window.close)
@REM pause
@REM for %%i in (chs, cht, fra, deu, ita,jpn,kor,ptg,esn) do DiffLpuWrapper.bat "%folder%\%%i\old" "%folder%\%%i\new" %%i
for %%i in (cht, fra, deu, ita,jpn,kor,ptg,esn) do DiffLpuWrapper.bat "%folder%\%%i\old" "%folder%\%%i\new" %%i
pause
