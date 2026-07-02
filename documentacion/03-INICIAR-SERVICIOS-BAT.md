# 🚀 INICIAR-SERVICIOS.BAT - EXPLICACIÓN DETALLADA

## 📋 ¿Qué es este script?

`iniciar-servicios.bat` es un **script de Windows** que **automáticamente** expone los servicios de Kubernetes en `localhost` usando `kubectl port-forward`.

### Ubicación:
```
c:\Users\USER\Documents\JalatonJuC\iniciar-servicios.bat
```

---

## 📄 CONTENIDO COMPLETO DEL SCRIPT

```batch
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
```

---

## 🔍 EXPLICACIÓN LÍNEA POR LÍNEA

### 1️⃣ Inicio del script

```batch
@echo off
```
- **Qué hace**: Oculta los comandos (solo muestra resultados)
- **Sin esto**: Verías cada comando ejecutándose
- **Con esto**: Solo ves los mensajes limpios

---

### 2️⃣ Mensajes informativos

```batch
echo ==========================================
echo   INICIANDO SERVICIOS CON PORT-FORWARD
echo ==========================================
echo.
```
- **Qué hace**: Muestra un banner informativo
- **`echo.`**: Imprime una línea en blanco

```batch
echo Backend estara disponible en: http://localhost:8080
echo Frontend estara disponible en: http://localhost:4200
```
- **Qué hace**: Te dice en qué URLs estarán disponibles los servicios

---

### 3️⃣ Port-forward del Backend

```batch
start "Backend Port-Forward" cmd /k "kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080"
```

**Desglose**:

| Parte | Qué hace |
|-------|----------|
| `start` | Abre una nueva ventana de terminal |
| `"Backend Port-Forward"` | Título de la ventana |
| `cmd /k` | Ejecuta comando y MANTIENE la ventana abierta |
| `kubectl port-forward` | Comando de Kubernetes |
| `-n jhon-silva-backend` | En el namespace backend |
| `service/jhon-silva-backend-service` | El servicio a exponer |
| `8080:8080` | Puerto local:Puerto del servicio |

**Resultado**: 
- Abre una ventana nueva
- Expone el backend en `localhost:8080`
- La ventana queda abierta (si la cierras, se detiene)

---

### 4️⃣ Espera entre comandos

```batch
timeout /t 3 /nobreak >nul
```
- **Qué hace**: Espera 3 segundos
- **Por qué**: Dar tiempo al backend antes de iniciar el frontend
- **`/nobreak`**: No se puede cancelar con tecla
- **`>nul`**: Oculta el mensaje de cuenta regresiva

---

### 5️⃣ Port-forward del Frontend

```batch
start "Frontend Port-Forward" cmd /k "kubectl port-forward -n jhon-silva-frontend service/jhon-silva-frontend-service 4200:80"
```

**Desglose**:

| Parte | Qué hace |
|-------|----------|
| `start` | Abre otra ventana nueva |
| `"Frontend Port-Forward"` | Título de la ventana |
| `cmd /k` | Ejecuta y mantiene abierta |
| `-n jhon-silva-frontend` | Namespace frontend |
| `service/jhon-silva-frontend-service` | Servicio frontend |
| `4200:80` | Local 4200 → Servicio 80 |

**Resultado**:
- Abre segunda ventana
- Expone frontend en `localhost:4200`

---

### 6️⃣ Mensaje final

```batch
echo.
echo ==========================================
echo   SERVICIOS INICIADOS
echo ==========================================
```
- **Qué hace**: Confirma que todo está listo

```batch
echo Abre tu navegador en:
echo   - Backend API: http://localhost:8080/api/users
echo   - Frontend: http://localhost:4200
```
- **Qué hace**: Te dice las URLs exactas para probar

```batch
pause >nul
```
- **Qué hace**: Espera que presiones una tecla
- **`>nul`**: Oculta el mensaje "Presione una tecla..."
- **Por qué**: Mantiene la ventana principal abierta para ver los mensajes

---

## 🎬 ¿QUÉ PASA CUANDO LO EJECUTAS?

### Paso a paso:

1. **Doble clic** en `iniciar-servicios.bat`

2. **Se abre 1 ventana** con el banner:
   ```
   ==========================================
     INICIANDO SERVICIOS CON PORT-FORWARD
   ==========================================
   
   Backend estara disponible en: http://localhost:8080
   Frontend estara disponible en: http://localhost:4200
   ```

3. **Se abre 2da ventana** (Backend):
   ```
   Backend Port-Forward
   Forwarding from 127.0.0.1:8080 -> 8080
   Forwarding from [::1]:8080 -> 8080
   ```

4. **Espera 3 segundos**

5. **Se abre 3ra ventana** (Frontend):
   ```
   Frontend Port-Forward
   Forwarding from 127.0.0.1:4200 -> 80
   Forwarding from [::1]:4200 -> 80
   ```

6. **Ventana principal** muestra:
   ```
   ==========================================
     SERVICIOS INICIADOS
   ==========================================
   
   Abre tu navegador en:
     - Backend API: http://localhost:8080/api/users
     - Frontend: http://localhost:4200
   ```

---

## 🔧 VARIACIONES DEL SCRIPT

### Opción 1: Con diferentes puertos

```batch
start "Backend Port-Forward" cmd /k "kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 9090:8080"
```
- Backend en `localhost:9090` en lugar de 8080

### Opción 2: Sin timeout (más rápido)

```batch
start "Backend Port-Forward" cmd /k "kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080"
start "Frontend Port-Forward" cmd /k "kubectl port-forward -n jhon-silva-frontend service/jhon-silva-frontend-service 4200:80"
```
- Ambos se inician al mismo tiempo

### Opción 3: Con logs

```batch
start "Backend Port-Forward" cmd /k "kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080 --v=5"
```
- Muestra más detalles de qué está haciendo

---

## 🛑 CÓMO DETENER LOS SERVICIOS

### Método 1: Cerrar las ventanas
- Cierra la ventana "Backend Port-Forward"
- Cierra la ventana "Frontend Port-Forward"

### Método 2: Ctrl+C en cada ventana
- Ve a cada ventana
- Presiona `Ctrl+C`
- Confirma con `S` (Sí)

### Método 3: Matar todos los port-forward
```bash
# En PowerShell
Get-Process | Where-Object {$_.CommandLine -like "*port-forward*"} | Stop-Process -Force
```

---

## 🎯 ¿POR QUÉ NECESITAS ESTE SCRIPT?

### El problema:

En Docker Desktop, las IPs del LoadBalancer (`172.19.255.200`) **NO son accesibles** desde Windows.

```
❌ NO funciona:
curl http://172.19.255.200:8080/api/users
```

### La solución:

Port-forward expone el servicio en `localhost`:

```
✅ SÍ funciona:
curl http://localhost:8080/api/users
```

---

## 📊 COMPARACIÓN: CON vs SIN SCRIPT

### SIN el script (Manual):

```bash
# Terminal 1
kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080

# Terminal 2
kubectl port-forward -n jhon-silva-frontend service/jhon-silva-frontend-service 4200:80
```

**Inconvenientes**:
- Tienes que abrir 2 terminales
- Copiar y pegar comandos largos
- Recordar los puertos
- Puede haber errores de tipeo

### CON el script (Automático):

```
1. Doble clic en iniciar-servicios.bat
2. Esperar 5 segundos
3. Listo ✅
```

**Ventajas**:
- ✅ Un solo clic
- ✅ Todo automático
- ✅ Sin errores
- ✅ Mensajes claros

---

## 🧪 TESTING

### Después de ejecutar el script:

#### Test 1: Backend
```bash
curl http://localhost:8080/api/users
```

**Esperado**: JSON con usuarios

#### Test 2: Frontend
Abre navegador:
```
http://localhost:4200
```

**Esperado**: Aplicación Angular cargando

#### Test 3: Crear usuario
```bash
curl -X POST http://localhost:8080/api/users -H "Content-Type: application/json" -d "{\"username\":\"test\",\"email\":\"test@test.com\",\"firstName\":\"Test\",\"lastName\":\"User\",\"phone\":\"+51-999\",\"address\":\"Test\"}"
```

**Esperado**: Usuario creado en JSON

---

## 🎓 RESUMEN

### ¿Qué hace?
- Expone backend en `localhost:8080`
- Expone frontend en `localhost:4200`
- Todo con un solo clic

### ¿Cómo lo hace?
- Usa `kubectl port-forward`
- Abre 2 ventanas de terminal automáticamente
- Muestra mensajes informativos

### ¿Cuándo usarlo?
- **Siempre** en Docker Desktop
- Cada vez que quieras acceder a tu aplicación
- Antes de hacer demos o pruebas

### Comandos equivalentes:
```bash
# El script hace esto automáticamente:
kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080
kubectl port-forward -n jhon-silva-frontend service/jhon-silva-frontend-service 4200:80
```

### URLs finales:
- Backend: `http://localhost:8080`
- Frontend: `http://localhost:4200`

¡Listo mano! Script completamente explicado. 🚀✨
