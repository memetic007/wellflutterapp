@echo off
echo Starting Flutter cleanup process...

echo.
echo Killing processes...
taskkill /F /IM command_interface.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM msbuild.exe 2>nul
taskkill /F /IM devenv.exe 2>nul

echo.
echo Cleaning Flutter build...
call flutter clean

echo.
echo Removing build directories...
if exist "build" rd /s /q build
if exist ".dart_tool" rd /s /q .dart_tool
if exist "windows\build" rd /s /q windows\build
if exist "%TEMP%\flutter_tools*" rd /s /q %TEMP%\flutter_tools*
if exist "%LOCALAPPDATA%\Temp\flutter_tools*" rd /s /q %LOCALAPPDATA%\Temp\flutter_tools*

echo.
echo Shutting down Flutter daemon...
call flutter daemon --shutdown

echo.
echo Getting packages...
call flutter pub get

echo.
echo Cleanup complete! You can now run 'flutter run -d windows'
echo.

pause