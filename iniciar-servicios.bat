@echo off
echo ==========================================
echo   INICIANDO SERVICIOS CON PORT-FORWARD
echo ==========================================
echo.
echo Backend estara disponible en: http://localhost:8080
echo Frontend estara disponible en: http://localhost:4200
echo.
echo Presiona Ctrl+C para detener los servicios
echo.

start "Backend Port-Forward" cmd /k "kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080"

timeout /t 3 /nobreak >nul

start "Frontend Port-Forward" cmd /k "kubectl port-forward -n jhon-silva-frontend service/jhon-silva-frontend-service 4200:80"

echo.
echo ==========================================
echo   SERVICIOS INICIADOS
echo ==========================================
echo.
echo Abre tu navegador en:
echo   - Backend API: http://localhost:8080/api/users
echo   - Frontend: http://localhost:4200
echo.
echo Presiona cualquier tecla para cerrar esta ventana...
pause >nul
