@echo off
setlocal
cd /d "%~dp0"

:: ============================================================
::  CONFIGURE THESE TWO LINES
::  QUARTUS_BIN : path to quartus\bin of your installed Quartus
::  CABLE       : JTAG cable name (run: quartus_pgm --l  to see it)
::
::  IMPORTANT (Windows 11 / 64-bit):
::  Quartus II 10.0 will NOT detect the USB-Blaster here because its
::  JTAG stack needs the old Jungo driver, which Driver Signature
::  Enforcement blocks. Point QUARTUS_BIN at a version whose JTAG
::  stack matches the already-installed SIGNED modern driver:
::    -> Quartus Prime Lite  (free, supports Cyclone IV EP4CE115)
::    -> or Quartus 13.0 / 15.0 / 18.0+
::  The signed driver (Altera 2.12.28) is already installed and working.
:: ============================================================
set QUARTUS_BIN=C:\altera\10.0\quartus\bin
set CABLE=USB-Blaster [USB-0]
set PROJECT=blink_led
:: ============================================================

if not exist "%QUARTUS_BIN%\quartus_map.exe" (
    echo ERROR: quartus_map.exe not found at "%QUARTUS_BIN%"
    echo        Edit QUARTUS_BIN at the top of this script.
    exit /b 1
)
set "PATH=%QUARTUS_BIN%;%PATH%"

echo [1/5] Analysis (quartus_map)...
call quartus_map %PROJECT% || goto :fail

echo [2/5] Fitting (quartus_fit)...
call quartus_fit %PROJECT% || goto :fail

echo [3/5] Assemble SOF (quartus_asm)...
call quartus_asm %PROJECT% || goto :fail

echo [4/5] Timing analysis (quartus_sta)...
call quartus_sta %PROJECT% || goto :fail

echo [5/5] Detect cables...
call quartus_pgm -l

if not exist "output_files\%PROJECT%.sof" (
    echo ERROR: output_files\%PROJECT%.sof was not produced.
    exit /b 1
)

echo Programming output_files\%PROJECT%.sof to "%CABLE%"...
call quartus_pgm -c "%CABLE%" -m jtag -o "p;output_files\%PROJECT%.sof" || goto :fail

echo.
echo ============================================================
echo  DONE. LED on the DE2-115 should now blink every 30 ms.
echo ============================================================
goto :eof

:fail
echo.
echo BUILD/PROGRAM FAILED at the step shown above.
exit /b 1
