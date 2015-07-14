@ECHO OFF
ECHO Deep Archive Reverse
ECHO Written by: Jason Faulkner, modified by Frank Perry
ECHO SysadminGeek.com
ECHO No licence specified in original script, MIT license assumed.
ECHO.
ECHO.

REM The intent of the origin script was to do zip-to-7z conversion.
REM This script does the opposite (7z-to-zip) conversion.
REM It still has some of the bells and whistles of the original script, but entirely untested.
REM
REM 
REM Takes a 7z file and recompresses it as zip archive.
REM Script process:
REM    1. Decompress the existing archive.
REM    2. Compress the extracted files in zip format.
REM    3. (optional) Validate the new zip file (untested).
REM    4. (optional) Delete the source archive.
REM
REM Usage:
REM DeepArchive 7zFile
REM
REM Requirements:
REM    The 7-Zip command line tool (7za.exe) is in a location set in the PATH variable.
REM
REM Additional Notes:
REM This script processes a single 7z archive.
REM To process all 7z archives in a folder, use the ForFiles command from the command line:
REM    FORFILES /P "pathto7zfiles" /M *.zip /C "cmd /c DeepArchive @path"
REM
REM To run the archive compression/decompression as low priority background processes
REM add this in front of the 7ZA commands (DO NOT add this in front of the validation 7ZA command):
REM    START /BelowNormal /Wait 
REM Adding the above command will use a new window to perform these operations.

SETLOCAL EnableExtensions EnableDelayedExpansion

REM Should the deep archive file be validated? (1=yes, 0=no)
SET Validate=0

REM Compression level: 1,3,5,7,9 (higher=slower but more compression)
SET CompressLevel=5

REM Delete source zip file on success? (1=yes, 0=no)
SET DeleteSourceOnSuccess=1


REM ---- Do not modify anything below this line ----

SET cur_dir=%CD%
SET ArchiveFile=%1
SET DeepFile="%ArchiveFile:.7z=.zip%"
SET tmpPath=%TEMP%%~nx1
SET tmpPathZip="%tmpPath%*"
SET tmpPath="%tmpPath%"
SET tmpFile="%TEMP%tmpDeepArchive.txt"

IF NOT EXIST %tmpPath% (
   MKDIR %tmpPath%
) ELSE (
   RMDIR /S /Q %tmpPath%
)

ECHO Extracting archive: %ArchiveFile%
7ZA x %ArchiveFile% -o%tmpPath%
ECHO.

ECHO Changing to temp folder: %tmpPath%
CHDIR /D %tmpPath%
ECHO.

ECHO Compressing archive: %DeepFile%
7ZA a -tzip -mx%CompressLevel% -r "%DeepFile%" *
ECHO.

ECHO Changing back to work folder: %cur_dir%
CHDIR /D %cur_dir%
ECHO.

IF {%Validate%}=={1} (
   ECHO Validating archive: %DeepFile%
   7ZA t %DeepFile% | FIND /C "Everything is Ok" > %tmpFile%
   SET /P IsValid=< %tmpFile%
   IF !IsValid!==0 (
      ECHO Validation failed!
      DEL /F /Q %DeepFile%
      ECHO.
      GOTO Fail
   ) ELSE (
      ECHO Validation passed.
   )
   ECHO.
)
GOTO Success


:Success
IF {%DeleteSourceOnSuccess%}=={1} DEL /F /Q %ArchiveFile%
ECHO Success
GOTO End


:Fail
ECHO Failed
GOTO End


:End
IF EXIST %tmpFile% DEL /F /Q %tmpFile%
IF EXIST %tmpPath% RMDIR /S /Q %tmpPath%

ENDLOCAL