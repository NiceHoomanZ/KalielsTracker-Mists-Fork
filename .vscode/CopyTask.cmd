:: Copy all changes files, folders and sub-folder from "!KalielsTracker" directory to target.

SET @addonDirectory="%cd%\!KalielsTracker-Mists"

:: XO : Exclude files that are older, 
:: PURGE : Remove non existing file in destination folder
:: S : Copy Subfolders.
ROBOCOPY %@addonDirectory% %1 /S /XO /PURGE 