@echo off
chcp 65001 >nul
setlocal
set "SRC=%~dp0android"
set "WORK=C:\Users\Public\cfbuild"
set "GRADLE_USER_HOME=C:\Users\Public\cfgradle"
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
if exist "%USERPROFILE%\.jdks\jbr-21.0.11\bin\java.exe" set "JAVA_HOME=%USERPROFILE%\.jdks\jbr-21.0.11"
if exist "C:\Program Files\Java\jdk-17\bin\java.exe" set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
set "ANDROID_SDK_ROOT=%ANDROID_HOME%"
set "LOG=%~dp0build.log"
echo CF FACEIT: building APK, wait 3-10 minutes... 
echo started %date% %time% > "%LOG%"
robocopy "%SRC%" "%WORK%" /MIR /XD build .gradle /NFL /NDL /NJH /NJS >nul
cd /d "%WORK%"
call gradlew.bat assembleDebug --no-daemon --console=plain >> "%LOG%" 2>&1
if exist "%WORK%\app\build\outputs\apk\debug\app-debug.apk" (
  copy /y "%WORK%\app\build\outputs\apk\debug\app-debug.apk" "%~dp0CF-FACEIT.apk" >nul
  echo BUILD_OK >> "%LOG%"
  echo.
  echo DONE: CF-FACEIT.apk is next to this file.
) else (
  echo BUILD_FAILED >> "%LOG%"
  echo.
  echo ERROR - see build.log
)
pause
