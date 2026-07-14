@echo off
REM ============================================================
REM  setenv.bat — Set environment variables for Quartus II 10.0
REM  Usage: setenv.bat
REM  Run before any quartus_* commands in this terminal.
REM ============================================================
set QUARTUS_ROOTDIR=C:\altera\10.0\quartus
set QUARTUS_BIN=%QUARTUS_ROOTDIR%\bin
set PATH=%QUARTUS_BIN%;%PATH%
set QSYS_ROOTDIR=C:\altera\10.0\quartus\sopc_builder\bin
echo [DE2-115] Quartus II 10.0 environment ready.
echo   QUARTUS_BIN=%QUARTUS_BIN%
echo   Cable: USB-Blaster [USB-0]
