@echo off
cls

echo.
echo ================================================================
echo    GENERADOR DE BACKEND SPRING BOOT 3
echo    WebFlux + R2DBC + Docker + Kubernetes
echo ================================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0generar-proyecto.ps1"

if errorlevel 1 (
    echo.
    echo ERROR: Ocurrio un error durante la generacion
    pause
    exit /b 1
)

echo.
echo EXITO: Generacion completada
pause
