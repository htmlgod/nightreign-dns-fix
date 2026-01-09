@echo off

setlocal enabledelayedexpansion

REM Run as Administrator required
NET SESSION >nul 2>&1
if %errorlevel% neq 0 (
  echo Please run as Administrator!
  pause
  exit /b 1
)

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0ern-update-dns.ps1'"
pause
