@echo off
setlocal EnableExtensions
title CITY ZERO - NFS UNDERGROUND 2 ORIGINAL CARS COMPLETE IMPORT
cd /d "%~dp0\.."
set "CITYZERO_REPO=%CD%"
set "UPSTREAM=%CITYZERO_REPO%\tools\_nfsu2_world_editor"
set "OUTPUT=%USERPROFILE%\Documents\CityZeroNFSU2Imported"

echo ============================================================
echo CITY ZERO - ORIGINAL NFSU2 3D CARS, BODYKITS, VINYLS, SOUNDS
echo ============================================================
echo Original NFSU2 media stays on this computer and is NOT uploaded.
echo.

where python >nul 2>&1
if errorlevel 1 (
  echo ERROR: Python 3 is required. Get it at https://www.python.org/downloads/
  pause
  exit /b 1
)
where git >nul 2>&1
if errorlevel 1 (
  echo ERROR: Git is required. Get it at https://git-scm.com/download/win
  pause
  exit /b 1
)
set "BLENDER_EXE="
for /f "delims=" %%B in ('where blender.exe 2^>nul') do if not defined BLENDER_EXE set "BLENDER_EXE=%%B"
if not defined BLENDER_EXE (
  for /d %%D in ("%ProgramFiles%\Blender Foundation\Blender *") do (
    if exist "%%~fD\blender.exe" set "BLENDER_EXE=%%~fD\blender.exe"
  )
)
if not defined BLENDER_EXE (
  echo ERROR: Blender 4.2+ was not found. Cannot export real original GLBs.
  echo Install Blender from https://www.blender.org/download/
  pause
  exit /b 1
)
echo Blender: "%BLENDER_EXE%"

if not exist "%UPSTREAM%\nfsu2_world_editor\core\cars.py" (
  echo Fetching MIT-licensed NFSU2 World Editor importer...
  git clone --depth 1 https://github.com/mininxd/NFSU2-World-Editor.git "%UPSTREAM%"
  if errorlevel 1 (
    echo ERROR: Unable to install the verified NFSU2 parser.
    pause
    exit /b 1
  )
)

set "GAME_ROOT="
for %%G in (
  "C:\Program Files (x86)\EA GAMES\Need for Speed Underground 2"
  "C:\Program Files\EA GAMES\Need for Speed Underground 2"
  "D:\Games\Need for Speed Underground 2"
) do if not defined GAME_ROOT if exist "%%~G\CARS" set "GAME_ROOT=%%~G"
if not defined GAME_ROOT (
  set /p "GAME_ROOT=Enter full folder path of your installed NFSU2 game: "
)
if not exist "%GAME_ROOT%\CARS" (
  echo ERROR: No genuine CARS directory at "%GAME_ROOT%".
  echo Nothing was fabricated or downloaded in its place.
  pause
  exit /b 1
)

where vgmstream-cli.exe >nul 2>&1
if errorlevel 1 (
  echo NOTE: vgmstream-cli was not found. Audio bank inventory will work,
  echo but ABK/GIN to WAV extraction will be marked not_run.
)
echo.
echo NFSU2 game: "%GAME_ROOT%"
echo Private output: "%OUTPUT%"
echo.
python "%CITYZERO_REPO%\tools\nfsu2_import_all.py" ^
  --game-root "%GAME_ROOT%" ^
  --converter-dir "%UPSTREAM%" ^
  --out "%OUTPUT%" ^
  --blender "%BLENDER_EXE%" ^
  --export-all
if errorlevel 1 (
  echo ERROR: Import failed. Check the above message.
  pause
  exit /b 1
)
echo.
echo Complete manifest:
echo %OUTPUT%\nfsu2_all_manifest.json
echo Godot 3D showroom library:
echo %OUTPUT%\cityzero_godot_library.json
echo.
echo To view your real cars in Godot:
echo Run scene city_zero/nfsu2_private/CityZeroNFSU2Showroom.tscn
echo Click OPEN NFSU2 LIBRARY and select the JSON above.
echo NEVER publicly commit the extracted original NFSU2 media.
echo.
pause
endlocal
