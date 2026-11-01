@echo off
rem zip-to-jar: drag a Forge 1.20.1 mod project .zip onto this file, get the built .jar next to the zip.
set "ZIP=%~1"
if "%ZIP%"=="" (
  echo Drag your mod project .zip onto this file.
  pause
  exit /b 1
)
set "OUTDIR=%~dp1"
set "TOOLS=%USERPROFILE%\.zip2jar"
set "WORK=%TEMP%\zip2jar_work"

if not exist "%TOOLS%\gradlew.bat" (
  echo [1/3] First run: downloading Forge MDK, wait...
  mkdir "%TOOLS%" 2>nul
  powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.3.0/forge-1.20.1-47.3.0-mdk.zip' -OutFile '%TOOLS%\mdk.zip'; Expand-Archive -LiteralPath '%TOOLS%\mdk.zip' -DestinationPath '%TOOLS%\mdk' -Force"
  copy /y "%TOOLS%\mdk\gradlew.bat" "%TOOLS%\" >nul
  copy /y "%TOOLS%\mdk\gradlew" "%TOOLS%\" >nul
  copy /y "%TOOLS%\mdk\gradle\wrapper\gradle-wrapper.jar" "%TOOLS%\" >nul
  rmdir /s /q "%TOOLS%\mdk"
  del "%TOOLS%\mdk.zip"
)
if not exist "%TOOLS%\gradlew.bat" (
  echo Could not download Forge MDK. Check the internet and try again.
  pause
  exit /b 1
)

echo [2/3] Unpacking the zip...
if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%WORK%"
powershell -NoProfile -Command "Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%WORK%' -Force"

set "PROJ="
for /r "%WORK%" %%f in (build.gradle) do if exist "%%f" if not defined PROJ set "PROJ=%%~dpf"
if not defined PROJ (
  echo build.gradle not found in the zip. This is not a mod project.
  pause
  exit /b 1
)

if not exist "%PROJ%gradlew.bat" copy /y "%TOOLS%\gradlew.bat" "%PROJ%" >nul
if not exist "%PROJ%gradlew" copy /y "%TOOLS%\gradlew" "%PROJ%" >nul
if not exist "%PROJ%gradle\wrapper" mkdir "%PROJ%gradle\wrapper"
if not exist "%PROJ%gradle\wrapper\gradle-wrapper.jar" copy /y "%TOOLS%\gradle-wrapper.jar" "%PROJ%gradle\wrapper\" >nul
if not exist "%PROJ%gradle\wrapper\gradle-wrapper.properties" (
  echo distributionBase=GRADLE_USER_HOME> "%PROJ%gradle\wrapper\gradle-wrapper.properties"
  echo distributionPath=wrapper/dists>> "%PROJ%gradle\wrapper\gradle-wrapper.properties"
  echo distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-bin.zip>> "%PROJ%gradle\wrapper\gradle-wrapper.properties"
  echo zipStoreBase=GRADLE_USER_HOME>> "%PROJ%gradle\wrapper\gradle-wrapper.properties"
  echo zipStorePath=wrapper/dists>> "%PROJ%gradle\wrapper\gradle-wrapper.properties"
)

echo [3/3] Building the mod (first time takes several minutes)...
pushd "%PROJ%"
call gradlew.bat build
popd

set "FOUND="
for %%j in ("%PROJ%build\libs\*.jar") do (
  echo %%~nj | findstr /i "sources javadoc" >nul || (
    copy /y "%%j" "%OUTDIR%" >nul
    echo.
    echo DONE: %%~nxj is next to your zip.
    set "FOUND=1"
  )
)
if not defined FOUND (
  echo.
  echo BUILD FAILED. Send the red text above to Claude.
)
rmdir /s /q "%WORK%" 2>nul
pause
