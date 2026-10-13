@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NeonVoidGodot\tools\neon.ps1" %*
endlocal
