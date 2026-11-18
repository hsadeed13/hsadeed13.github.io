@echo off
setlocal EnableExtensions
title Publish portfolio to GitHub Pages
cd /d "%~dp0"

set "GIT=C:\Program Files\Git\cmd\git.exe"
set "GH=C:\Program Files\GitHub CLI\gh.exe"
set "G="%GIT%" -c safe.directory=*"

if not exist "%GIT%" goto :nogit
if not exist "%GH%" goto :nogh

echo.
echo  =====================================================
echo     Publish your portfolio website on GitHub Pages
echo     This creates a PUBLIC repository named
echo     YOUR-USERNAME.github.io with only the website files.
echo     Your affiliate site code stays private.
echo  =====================================================
echo.

echo [1/5] Checking your GitHub sign-in...
"%GH%" auth status -h github.com >nul 2>&1
if not errorlevel 1 goto :signedin
echo You need to sign in to GitHub once. Follow the steps below - a browser window will open.
"%GH%" auth login -h github.com -p https -w
if errorlevel 1 goto :fail
:signedin
"%GH%" auth setup-git -h github.com >nul 2>&1
for /f "usebackq delims=" %%L in (`"%GH%" api user --jq .login`) do set "LOGIN=%%L"
if not defined LOGIN goto :fail
set "REPO=%LOGIN%.github.io"
echo       Signed in as %LOGIN%

echo.
echo [2/5] Saving the current version of the website...
if not exist ".git" %G% init -q -b main
%G% config user.name "Habeeb E Sadeed"
%G% config user.email "195645636+hsadeed13@users.noreply.github.com"
%G% add -A
%G% diff --cached --quiet
if not errorlevel 1 goto :nochanges
> "%TEMP%\portfolio-commit.txt" echo Update portfolio website
>> "%TEMP%\portfolio-commit.txt" echo.
>> "%TEMP%\portfolio-commit.txt" echo Home page with featured work, skills and contact, plus the
>> "%TEMP%\portfolio-commit.txt" echo TopPick Reviews case study with screenshots.
>> "%TEMP%\portfolio-commit.txt" echo.
>> "%TEMP%\portfolio-commit.txt" echo Co-Authored-By: Claude Opus 5.5 ^<noreply@anthropic.com^>
>> "%TEMP%\portfolio-commit.txt" echo Claude-Session: https://claude.ai/code/session_01C1TMNG1abBLVDFviHpr7gu
%G% commit -q -F "%TEMP%\portfolio-commit.txt"
if errorlevel 1 goto :fail
goto :repo
:nochanges
echo       No changes since the last publish.

:repo
echo.
echo [3/5] Making sure the public repository %LOGIN%/%REPO% exists...
"%GH%" repo view "%LOGIN%/%REPO%" >nul 2>&1
if not errorlevel 1 goto :haverepo
"%GH%" repo create "%LOGIN%/%REPO%" --public --description "Portfolio website of Habeeb E Sadeed" --homepage "https://%REPO%/"
if errorlevel 1 goto :fail
:haverepo
%G% remote get-url origin >nul 2>&1
if errorlevel 1 %G% remote add origin "https://github.com/%LOGIN%/%REPO%.git"

echo.
echo [4/5] Uploading...
%G% push -u origin main
if errorlevel 1 goto :fail

echo.
echo [5/5] Turning on GitHub Pages...
"%GH%" api "repos/%LOGIN%/%REPO%/pages" >nul 2>&1
if not errorlevel 1 goto :pageson
"%GH%" api -X POST "repos/%LOGIN%/%REPO%/pages" -f "source[branch]=main" -f "source[path]=/" >nul
if errorlevel 1 echo       Could not turn on Pages automatically. In the repository open Settings - Pages and choose branch "main".
:pageson

echo.
echo  =====================================================
echo     Done!  Your portfolio address:
echo         https://%REPO%/
echo     The first time, it can take 1-2 minutes to appear.
echo     Run this file again any time to publish changes.
echo  =====================================================
start "" "https://github.com/%LOGIN%/%REPO%/actions"
timeout /t 60 /nobreak >nul
start "" "https://%REPO%/"
pause
exit /b 0

:nogit
echo Git was not found at %GIT%
goto :fail
:nogh
echo GitHub CLI was not found at %GH%
goto :fail
:fail
echo.
echo  Publishing stopped - see the message above.
pause
exit /b 1
