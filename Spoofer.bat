@echo off
REM Copyright (c) 2026 Kholoudbendriss (Smofeng, sswdwsw)
REM SPDX-License-Identifier: Apache-2.0
REM License: https://github.com/kholoudbendriss/SpooferMyRust/blob/main/LICENSE

chcp 65001 >nul
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%Spoofer.ps1"

echo [INFO] Initializing system randomization process...
echo [INFO] Elevating privileges and executing PowerShell payload...

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ''%PS_SCRIPT%''' -Verb RunAs"

echo [INFO] Execution triggered successfully.
echo [INFO] Please review the generated log file located in your TEMP folder for details.
pause
