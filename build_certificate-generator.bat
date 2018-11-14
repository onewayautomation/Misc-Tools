@ECHO
REM ****************************************************************************************************************
REM ** This script builds the CertificateGenerator.
REM ****************************************************************************************************************

REM check if the msbuild command is available. If not, try to call the script which sets Visual C++ environment variables.
where msbuild >nul 2>nul
IF %ERRORLEVEL% == 0 GOTO VCOK

REM SET vc_bat_name1="C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"
SET vc_bat_name="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
IF EXIST %vc_bat_name% GOTO CMDOK
echo Failed to find Visual Studio batch file to setup environment.
exit

:CMDOK
call %vc_bat_name% x86

:VCOK	
SETLOCAL
set SRCDIR=%~dp0
set INSTALLDIR=%~dp0
set GIT=C:\Program Files (x86)\Git\bin\git.exe
set SIGNTOOL=C:\Build\sign_output.bat

IF "%1"=="no-clean" (IF EXIST %INSTALLDIR%\third-party\openssl GOTO noClean)

ECHO STEP 1) Deleting Output Directories
IF EXIST %INSTALLDIR%\bin rmdir /s /q %INSTALLDIR%\bin
IF EXIST %INSTALLDIR%\build rmdir /s /q %INSTALLDIR%\build
IF EXIST %INSTALLDIR%\third-party\openssl rmdir /s /q %INSTALLDIR%\third-party\openssl

IF NOT EXIST %INSTALLDIR%\bin MKDIR %INSTALLDIR%\bin
IF NOT EXIST %INSTALLDIR%\build MKDIR %INSTALLDIR%\build
IF NOT EXIST %INSTALLDIR%\third-party\openssl MKDIR %INSTALLDIR%\third-party\openssl

ECHO STEP 2) Fetch from Source Control
cd %SRCDIR%
"%GIT%" checkout master
"%GIT%" reset --hard
"%GIT%" submodule update --init --recursive
"%GIT%" pull

ECHO STEP 3) Building OpenSSL
cd %SRCDIR%\third-party
CALL build_openssl.bat
:noClean

ECHO STEP 4) Building CertificateGenerator
cd %SRCDIR%
IF DEFINED BUILD_NUMBER ECHO #define BUILD_NUMBER %BUILD_NUMBER% > CertificateGenerator\BuildVersion.h
msbuild "CertificateGenerator Solution.sln" /p:Configuration=Release 

ECHO STEP 5) Sign the Binaries
IF EXIST "%SIGNTOOL%" "%SIGNTOOL%" %INSTALLDIR%\bin\*.exe /dual

ECHO *** ALL DONE ***
GOTO theEnd

:theEnd
ENDLOCAL