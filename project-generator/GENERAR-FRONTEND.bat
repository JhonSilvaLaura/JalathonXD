@echo off
chcp 65001 >nul
cls

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║   🎨 GENERADOR DE FRONTEND ANGULAR 21                  ║
echo ║      CRUD Completo - Estilo Demo-Front                ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo Verificando Angular CLI 21...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0generar-crud-angular.ps1"

if errorlevel 1 (
    echo.
    echo ❌ Ocurrió un error durante la generación
    pause
    exit /b 1
)

echo.
echo ✅ Generación completada
pause
