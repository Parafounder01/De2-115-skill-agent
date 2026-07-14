@echo off
REM ============================================================
REM  restore-skills.bat — Restore DE2-115 skill from backup
REM  Usage: restore-skills.bat [platform]
REM    platform: opencode | mythos | all  (default: all)
REM ============================================================
setlocal enabledelayedexpansion

set BACKUP_DIR=%~dp0skills-backup
set OPTS=/E /I /Y /Q

if /I "%1"=="opencode" goto :restore_opencode
if /I "%1"=="mythos" goto :restore_mythos
if /I "%1"=="" goto :restore_all
echo Unknown platform: %1
echo Usage: restore-skills.bat [opencode ^| mythos ^| all]
exit /b 1

:restore_all
call :restore_opencode
call :restore_mythos
goto :end

:restore_opencode
echo [Opencode] Restoring skill to %%USERPROFILE%%\.config\opencode\skills\de2-115...
if exist "%BACKUP_DIR%\opencode" (
    xcopy "%BACKUP_DIR%\opencode" "%USERPROFILE%\.config\opencode\skills\de2-115\" %OPTS%
    echo [Opencode] ✔ Done
) else (
    echo [Opencode] ✘ Backup not found at %BACKUP_DIR%\opencode
)
exit /b 0

:restore_mythos
echo [Mythos] Restoring skill to %%USERPROFILE%%\.mythos-router\skills\de2-115...
if exist "%BACKUP_DIR%\mythos" (
    xcopy "%BACKUP_DIR%\mythos" "%USERPROFILE%\.mythos-router\skills\de2-115\" %OPTS%
    echo [Mythos] ✔ Done
) else (
    echo [Mythos] ✘ Backup not found at %BACKUP_DIR%\mythos
)
exit /b 0

:end
echo ============================================================
echo  Restore complete.
echo  Tip: Re-run the installer to sync MCP configs:
echo    node scripts\install-skill.mjs
echo ============================================================
endlocal
