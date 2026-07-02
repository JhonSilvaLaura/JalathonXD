# 🚀 Guía de Despliegue - CRUD Reactivo con Spring WebFlux + Angular + PostgreSQL

## 📋 Resumen del Proyecto

### ✅ Tareas Completadas

1. **Backend Reactivo**: Spring Boot WebFlux con R2DBC PostgreSQL
2. **Frontend Moderno**: Angular 21 con arquitectura estructurada
3. **Base de Datos Cloud**: PostgreSQL en Neon Cloud
4. **Dockerización**: Imágenes optimizadas (BE: 102MB, FE: 26.4MB)
5. **Imágenes en Docker Hub**: Publicadas y listas para usar
6. **Kubernetes**: Manifiestos para 2 clusters separados

---

## 🏗️ Arquitectura

### Backend (Spring WebFlux)
- **Framework**: Spring Boot 3.x con WebFlux (Reactive)
- **Base de Datos**: R2DBC PostgreSQL (Reactive)
- **Modelo**: User con 10 campos
- **Patrón**: Service/Impl
- **Estados**: ACTIVE, INACTIVE, SUSPENDED
- **Endpoints**: CRUD completo + cambios de estado

### Frontend (Angular 21)
- **Framework**: Angular 21 Standalone Components
- **Arquitectura**:
  - `core/interfaces/` - Interfaces TypeScript
  - `core/services/` - Servicios HTTP
  - `features/user-management/` - Componentes de funcionalidad
  - `layout/` - Componentes de layout
  - `shared/` - Componentes compartidos
- **UI**: Font Awesome icons, botones condicionales por estado

---

## 🐳 Imágenes Docker

### Backend
```
Imagen: jhonbrayansilvalaura/jhon-silva-be:1.0
Tamaño: 102MB
Puerto: 8080
```

### Frontend
```
Imagen: jhonbrayansilvalaura/jhon-silva-fe:1.0
Tamaño: 26.4MB
Puerto: 80
```

### Links Docker Hub
- Backend: https://hub.docker.com/r/jhonbrayansilvalaura/jhon-silva-be
- Frontend: https://hub.docker.com/r/jhonbrayansilvalaura/jhon-silva-fe

---

## ☸️ Despliegue en Kubernetes

### 📦 Prerequisitos

1. Tener `kubectl` instalado y configurado
2. Acceso a dos clusters de Kubernetes (o usar el mismo con diferentes namespaces)
3. Las imágenes están públicas en Docker Hub, no requieren autenticación

---

## 🔧 PASO 1: Desplegar Backend

### 1.1 Aplicar Manifiestos Backend

```bash
cd c:\Users\USER\Documents\JalatonJuC\demo

# Crear namespace
kubectl apply -f k8s/jhon-silva-00-namespace-be.yml

# Crear secrets con credenciales DB
kubectl apply -f k8s/jhon-silva-00-secret-be.yml

# Crear servicio LoadBalancer
kubectl apply -f k8s/jhon-silva-00-service-be.yml

# Crear deployment con 2 pods
kubectl apply -f k8s/jhon-silva-00-deployment-be.yml
```

### 1.2 Verificar Estado del Backend

```bash
# Ver pods
kubectl get pods -n jhon-silva-backend

# Ver servicio y obtener EXTERNAL-IP
kubectl get service jhon-silva-backend-service -n jhon-silva-backend

# Ver logs
kubectl logs -n jhon-silva-backend -l app=jhon-silva-backend --tail=100
```

### 1.3 Esperar por EXTERNAL-IP

El servicio LoadBalancer puede tardar unos minutos en asignar la IP externa:

```bash
# Monitorear hasta que aparezca EXTERNAL-IP (no <pending>)
kubectl get service jhon-silva-backend-service -n jhon-silva-backend --watch
```

**⚠️ IMPORTANTE**: Copia la EXTERNAL-IP del backend, la necesitarás para el frontend.

Ejemplo:
```
NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
jhon-silva-backend-service     LoadBalancer   10.96.45.123    34.123.45.67    8080:30123/TCP
```

En este ejemplo, la EXTERNAL-IP es: `34.123.45.67`

---

## 🔧 PASO 2: Configurar y Desplegar Frontend

### 2.1 Actualizar Secret del Frontend

El secret del frontend necesita la URL del backend en **base64**.

**Paso 1**: Obtén la EXTERNAL-IP del backend (del paso 1.3)

Ejemplo: `34.123.45.67`

**Paso 2**: Convierte la URL completa a base64:

```bash
# Windows PowerShell
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://34.123.45.67:8080'))"

# Linux/Mac
echo -n "http://34.123.45.67:8080" | base64
```

**Paso 3**: Edita `c:\Users\USER\Documents\JalatonJuC\demo-front\k8s\jhon-silva-00-secret-fe.yml`

Reemplaza el valor de `API_URL` con el base64 que obtuviste:

```yaml
data:
  API_URL: aHR0cDovLzM0LjEyMy40NS42Nzo4MDgw  # <- Tu valor en base64
```

**Opción alternativa - Mismo cluster (DNS interno)**:

Si ambos servicios están en el mismo cluster, puedes usar DNS interno:

```bash
# Convertir a base64
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://jhon-silva-backend-service.jhon-silva-backend.svc.cluster.local:8080'))"

# Resultado: aHR0cDovL2pob24tc2lsdmEtYmFja2VuZC1zZXJ2aWNlLmpob24tc2lsdmEtYmFja2VuZC5zdmMuY2x1c3Rlci5sb2NhbDo4MDgw
```

### 2.2 Aplicar Manifiestos Frontend

```bash
cd c:\Users\USER\Documents\JalatonJuC\demo-front

# Crear namespace
kubectl apply -f k8s/jhon-silva-00-namespace-fe.yml

# Crear secrets con URL del backend
kubectl apply -f k8s/jhon-silva-00-secret-fe.yml

# Crear servicio LoadBalancer
kubectl apply -f k8s/jhon-silva-00-service-fe.yml

# Crear deployment con 2 pods
kubectl apply -f k8s/jhon-silva-00-deployment-fe.yml
```

### 2.3 Verificar Estado del Frontend

```bash
# Ver pods
kubectl get pods -n jhon-silva-frontend

# Ver servicio y obtener EXTERNAL-IP
kubectl get service jhon-silva-frontend-service -n jhon-silva-frontend

# Ver logs
kubectl logs -n jhon-silva-frontend -l app=jhon-silva-frontend --tail=100
```

### 2.4 Obtener URL del Frontend

```bash
kubectl get service jhon-silva-frontend-service -n jhon-silva-frontend
```

Busca la EXTERNAL-IP y accede desde tu navegador:
```
http://<EXTERNAL-IP-FRONTEND>
```

---

## 🔍 Verificación de Conectividad

### Probar Backend directamente

```bash
# Listar todos los usuarios
curl http://<EXTERNAL-IP-BACKEND>:8080/api/users

# Obtener usuario por ID
curl http://<EXTERNAL-IP-BACKEND>:8080/api/users/1

# Crear usuario
curl -X POST http://<EXTERNAL-IP-BACKEND>:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "firstName": "Test",
    "lastName": "User",
    "phone": "+51-999-888-777",
    "address": "Calle Test 123"
  }'

# Activar usuario
curl -X PATCH http://<EXTERNAL-IP-BACKEND>:8080/api/users/1/activate

# Desactivar usuario
curl -X PATCH http://<EXTERNAL-IP-BACKEND>:8080/api/users/1/deactivate

# Suspender usuario
curl -X PATCH http://<EXTERNAL-IP-BACKEND>:8080/api/users/1/suspend

# Actualizar usuario
curl -X PUT http://<EXTERNAL-IP-BACKEND>:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "username": "updateduser",
    "email": "updated@example.com",
    "firstName": "Updated",
    "lastName": "User",
    "phone": "+51-999-888-777",
    "address": "Calle Updated 456",
    "status": "ACTIVE"
  }'

# Eliminar usuario
curl -X DELETE http://<EXTERNAL-IP-BACKEND>:8080/api/users/1
```

### Probar Frontend

Abre el navegador en: `http://<EXTERNAL-IP-FRONTEND>`

Deberías ver:
- Lista de usuarios desde la base de datos
- Formulario para crear nuevos usuarios
- Botones para editar, eliminar, activar, desactivar, suspender
- Búsqueda por nombre
- Iconos Font Awesome en lugar de emojis

---

## 📊 Comandos Útiles de Monitoreo

### Ver estado general

```bash
# Backend
kubectl get all -n jhon-silva-backend

# Frontend
kubectl get all -n jhon-silva-frontend
```

### Ver logs en tiempo real

```bash
# Backend
kubectl logs -n jhon-silva-backend -l app=jhon-silva-backend -f

# Frontend
kubectl logs -n jhon-silva-frontend -l app=jhon-silva-frontend -f
```

### Describir pods (para troubleshooting)

```bash
# Backend
kubectl describe pod -n jhon-silva-backend <pod-name>

# Frontend
kubectl describe pod -n jhon-silva-frontend <pod-name>
```

### Reiniciar deployments

```bash
# Backend
kubectl rollout restart deployment jhon-silva-backend-deployment -n jhon-silva-backend

# Frontend
kubectl rollout restart deployment jhon-silva-frontend-deployment -n jhon-silva-frontend
```

---

## 🗄️ Datos de Prueba

La base de datos incluye usuarios de prueba:

```
1. Juan Pérez - jperez - ACTIVE
2. María García - mgarcia - ACTIVE
3. Pedro López - plopez - INACTIVE
4. Carlos Rodriguez - crodriguez - ACTIVE
```

---

## 🔐 Credenciales Base de Datos (Neon Cloud)

**⚠️ NOTA**: Las credenciales están encodeadas en base64 en `jhon-silva-00-secret-be.yml`

**Valores originales**:
```
DB_URL: r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require
DB_USERNAME: neondb_owner
DB_PASSWORD: npg_pHT4NJx3gnSG
SERVER_PORT: 8080
```

**Valores en base64** (ya aplicados en el secret):
```yaml
data:
  DB_URL: cjJkYmM6cG9zdGdyZXNxbDovL2VwLXJvdWdoLXZpb2xldC1hZGk2cmkway1wb29sZXIuYy0yLnVzLWVhc3QtMS5hd3MubmVvbi50ZWNoL2RlbW8/c3NsbW9kZT1yZXF1aXJl
  DB_USERNAME: bmVvbmRiX293bmVy
  DB_PASSWORD: bnBnX3BIVDROSngzZ25TRw==
  SERVER_PORT: ODA4MA==
```

**Para convertir tus propios valores a base64**:
```bash
# Windows PowerShell
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('tu-valor-aqui'))"

# Linux/Mac
echo -n "tu-valor-aqui" | base64
```

---

## 🎯 Funcionalidades Implementadas

### Backend (API REST Reactiva)
- ✅ GET `/api/users` - Listar todos los usuarios
- ✅ GET `/api/users/{id}` - Obtener usuario por ID
- ✅ GET `/api/users?name={name}` - Buscar por nombre
- ✅ GET `/api/users?status={status}` - Filtrar por estado
- ✅ GET `/api/users/username/{username}` - Obtener por username
- ✅ GET `/api/users/email/{email}` - Obtener por email
- ✅ POST `/api/users` - Crear usuario (status = ACTIVE por defecto)
- ✅ PUT `/api/users/{id}` - Actualizar usuario
- ✅ DELETE `/api/users/{id}` - Eliminar usuario
- ✅ PATCH `/api/users/{id}/activate` - Activar usuario
- ✅ PATCH `/api/users/{id}/deactivate` - Desactivar usuario
- ✅ PATCH `/api/users/{id}/suspend` - Suspender usuario

### Frontend (Angular UI)
- ✅ Listar todos los usuarios con tabla responsive
- ✅ Buscar usuarios por nombre
- ✅ Crear nuevos usuarios (formulario sin campo status)
- ✅ Editar usuarios existentes
- ✅ Eliminar usuarios (con confirmación)
- ✅ Botones condicionales de estado:
  - Usuario ACTIVE: Muestra "Desactivar" y "Suspender"
  - Usuario INACTIVE: Muestra solo "Activar"
  - Usuario SUSPENDED: Muestra solo "Activar"
- ✅ Iconos Font Awesome en lugar de emojis
- ✅ Arquitectura limpia con core, features, layout, shared

---

## 🐛 Troubleshooting

### Backend no inicia
```bash
# Ver logs detallados
kubectl logs -n jhon-silva-backend <pod-name>

# Verificar secrets
kubectl get secret jhon-silva-backend-secrets -n jhon-silva-backend -o yaml

# Verificar conectividad a Neon DB
# Los pods deben poder alcanzar: ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech:5432
```

### Frontend no se conecta al backend
```bash
# Verificar que el secret del frontend tenga la URL en base64
kubectl get secret jhon-silva-frontend-secrets -n jhon-silva-frontend -o yaml

# Decodificar el secret para ver la API_URL
kubectl get secret jhon-silva-frontend-secrets -n jhon-silva-frontend -o jsonpath='{.data.API_URL}' | powershell -Command "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((Get-Content)))"

# Si necesitas actualizarlo, primero convertir a base64:
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://TU-IP-BACKEND:8080'))"

# Luego editar el secret y aplicar:
kubectl apply -f k8s/jhon-silva-00-secret-fe.yml
kubectl rollout restart deployment jhon-silva-frontend-deployment -n jhon-silva-frontend
```

### LoadBalancer en estado <pending>
- Algunos proveedores cloud (Minikube, Kind) no soportan LoadBalancer
- Alternativa: Cambiar el tipo de servicio a `NodePort` o usar `port-forward`:

```bash
# Para backend
kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080

# Para frontend
kubectl port-forward -n jhon-silva-frontend service/jhon-silva-frontend-service 8080:80
```

---

## 📝 Notas Importantes

1. **Clusters Separados**: Los manifiestos están diseñados para clusters separados usando LoadBalancer external IPs
2. **Mismo Cluster**: Si usas el mismo cluster, puedes usar DNS interno de Kubernetes en el secret del frontend
3. **Seguridad**: En producción, usar secrets externos (Vault, AWS Secrets Manager, etc.) en lugar de hardcodear en YAML. Todos los valores están en base64 como requiere Kubernetes.
4. **Escalabilidad**: Ambos deployments tienen 2 réplicas. Puedes escalar con: `kubectl scale deployment <nombre> --replicas=N -n <namespace>`
5. **Rolling Updates**: Los deployments están configurados con `RollingUpdate` para cero downtime
6. **Health Checks**: Liveness y readiness probes configurados para auto-healing

---

## ✅ Checklist de Verificación Final

- [ ] Backend pods en estado Running (2/2)
- [ ] Frontend pods en estado Running (2/2)
- [ ] Backend service tiene EXTERNAL-IP asignada
- [ ] Frontend service tiene EXTERNAL-IP asignada
- [ ] Backend responde a: `curl http://<IP-BACKEND>:8080/api/users`
- [ ] Frontend carga en navegador: `http://<IP-FRONTEND>`
- [ ] Frontend muestra lista de usuarios desde el backend
- [ ] Se puede crear un usuario nuevo
- [ ] Se puede editar un usuario
- [ ] Se puede eliminar un usuario
- [ ] Botones de estado funcionan correctamente
- [ ] Búsqueda por nombre funciona

---

## 🎉 ¡Despliegue Completado!

Si todos los checks están ✅, tu aplicación está completamente desplegada y funcionando en Kubernetes con:

- ✅ Backend reactivo con Spring WebFlux
- ✅ Frontend Angular 21 moderno
- ✅ Base de datos PostgreSQL en la nube (Neon)
- ✅ Alta disponibilidad (2 réplicas por servicio)
- ✅ Auto-healing con health checks
- ✅ Escalabilidad horizontal lista

**URLs de Acceso**:
- Backend API: `http://<EXTERNAL-IP-BACKEND>:8080/api/users`
- Frontend UI: `http://<EXTERNAL-IP-FRONTEND>`

---

## 📧 Contacto y Soporte

Para dudas o problemas:
- Revisa los logs: `kubectl logs -n <namespace> -l app=<app-name>`
- Verifica el estado: `kubectl get all -n <namespace>`
- Describe los recursos: `kubectl describe <resource> -n <namespace>`
