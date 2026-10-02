:: Copy all changes files, folders and sub-folder from current working directory to target.
:: WARNING : New files won't be added to avoid adding solution files !

:: XO :  Exclude files that are older, 
:: XL :  Exclude new files
:: PURGE :  Remove non existing file in destination folder
:: S : Copy Subfolders.
ROBOCOPY %cd% %1 /S /XO /XL /PURGE 