# 10 - RESUMEN DE COMANDOS

## 📋 Índice Rápido

1. [Comandos Base64 (Hashear Secrets)](#1-comandos-base64-hashear-secrets)
2. [Comandos Docker](#2-comandos-docker)
3. [Comandos Kubernetes](#3-comandos-kubernetes)
4. [Comandos MetalLB](#4-comandos-metallb)
5. [Comandos Port-Forward](#5-comandos-port-forward)
6. [Comandos Diagnóstico](#6-comandos-diagnóstico)
7. [Comandos Base de Datos](#7-comandos-base-de-datos)
8. [Scripts del Proyecto](#8-scripts-del-proyecto)

---

## 1. Comandos Base64 (Hashear Secrets)

### 🐧 Linux / Mac

```bash
# Codificar (hashear) un valor
echo -n "mipassword" | base64
# Resultado: bWlwYXNzd29yZA==

# IMPORTANTE: Usar -n para NO incluir salto de línea

# Decodificar para verificar
echo "bWlwYXNzd29yZA==" | base64 -d
# Resultado: mipassword

# Codificar URL completa
echo -n "r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require" | base64
```

### 🪟 Windows PowerShell

```powershell
# Codificar (hashear) un valor
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("mipassword"))
# Resultado: bWlwYXNzd29yZA==

# Decodificar para verificar
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("bWlwYXNzd29yZA=="))
# Resultado: mipassword

# Codificar URL completa (ejemplo del proyecto)
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require"))
```

### 🌐 Online (alternativa)

```
https://www.base64encode.org/
```

### 📝 Valores del Proyecto (Ya hasheados)

```yaml
# Backend Secrets
DB_URL: cjJkYmM6cG9zdGdyZXNxbDovL2VwLXJvdWdoLXZpb2xldC1hZGk2cmkway1wb29sZXIuYy0yLnVzLWVhc3QtMS5hd3MubmVvbi50ZWNoL2RlbW8/c3NsbW9kZT1yZXF1aXJl
# Decodificado: r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require

DB_USERNAME: bmVvbmRiX293bmVy
# Decodificado: neondb_owner

DB_PASSWORD: bnBnX3BIVDROSngzZ25TRw==
# Decodificado: npg_pHT4NJx3gnSG

# Frontend Secrets
API_URL: aHR0cDovL2xvY2FsaG9zdDozMDA4MA==
# Decodificado: http://localhost:30080
```

---

## 2. Comandos Docker

### 🏗️ Construir Imágenes

```bash
# Backend
cd demo
docker build -t jhonbrayansilvalaura/jhon-silva-be:1.0 .

# Frontend
cd demo-front
docker build -t jhonbrayansilvalaura/jhon-silva-fe:1.0 .
```

### 📤 Subir a Docker Hub

```bash
# Login (solo la primera vez)
docker login
# Usuario: jhonbrayansilvalaura
# Password: [tu password]

# Subir backend
docker push jhonbrayansilvalaura/jhon-silva-be:1.0

# Subir frontend
docker push jhonbrayansilvalaura/jhon-silva-fe:1.0
```

### 🔍 Ver Imágenes

```bash
# Listar todas las imágenes
docker images

# Listar solo las imágenes del proyecto
docker images | grep jhon-silva

# Ver tamaño de una imagen específica
docker images jhonbrayansilvalaura/jhon-silva-be:1.0
```

### 🧹 Limpiar Docker

```bash
# Eliminar imágenes no usadas
docker image prune -a

# Limpiar cache de build
docker builder prune -a

# Ver espacio usado
docker system df
```

### 🧪 Probar Imágenes Localmente

```bash
# Probar backend
docker run -p 8080:8080 \
  -e DB_URL="r2dbc:postgresql://..." \
  -e DB_USERNAME="neondb_owner" \
  -e DB_PASSWORD="npg_pHT4NJx3gnSG" \
  jhonbrayansilvalaura/jhon-silva-be:1.0

# Probar frontend
docker run -p 4200:80 jhonbrayansilvalaura/jhon-silva-fe:1.0
```

---

## 3. Comandos Kubernetes

### 🚀 Desplegar Aplicaciones

```bash
# Backend (en orden)
cd demo
kubectl apply -f k8s/jhon-silva-00-namespace-be.yml
kubectl apply -f k8s/jhon-silva-00-secret-be.yml
kubectl apply -f k8s/jhon-silva-00-service-be.yml
kubectl apply -f k8s/jhon-silva-00-deployment-be.yml

# Frontend (en orden)
cd ../demo-front
kubectl apply -f k8s/jhon-silva-00-namespace-fe.yml
kubectl apply -f k8s/jhon-silva-00-secret-fe.yml
kubectl apply -f k8s/jhon-silva-00-service-fe.yml
kubectl apply -f k8s/jhon-silva-00-deployment-fe.yml

# O aplicar todos a la vez por carpeta
kubectl apply -f k8s/
```

### 👀 Ver Estado de los Recursos

```bash
# Ver todos los pods
kubectl get pods --all-namespaces

# Ver pods del backend
kubectl get pods -n jhon-silva-backend

# Ver pods del frontend
kubectl get pods -n jhon-silva-frontend

# Ver servicios
kubectl get services --all-namespaces

# Ver service del backend
kubectl get service -n jhon-silva-backend jhon-silva-backend-service

# Ver deployments
kubectl get deployments --all-namespaces

# Ver secrets
kubectl get secrets -n jhon-silva-backend

# Ver TODO (pods, services, deployments)
kubectl get all -n jhon-silva-backend
```

### 📊 Ver Detalles de Recursos

```bash
# Detalles de un pod
kubectl describe pod -n jhon-silva-backend POD_NAME

# Detalles de un service
kubectl describe service -n jhon-silva-backend jhon-silva-backend-service

# Detalles de un deployment
kubectl describe deployment -n jhon-silva-backend jhon-silva-backend-deployment

# Ver un secret (sin decodificar)
kubectl get secret -n jhon-silva-backend jhon-silva-backend-secrets -o yaml

# Decodificar un valor del secret
kubectl get secret -n jhon-silva-backend jhon-silva-backend-secrets -o jsonpath='{.data.db-password}' | base64 -d
```

### 📝 Ver Logs

```bash
# Logs de un pod específico
kubectl logs -n jhon-silva-backend POD_NAME

# Logs en tiempo real (follow)
kubectl logs -f -n jhon-silva-backend POD_NAME

# Logs de todos los pods del deployment
kubectl logs -n jhon-silva-backend -l app=jhon-silva-backend

# Logs de las últimas 50 líneas
kubectl logs -n jhon-silva-backend POD_NAME --tail=50
```

### 🔄 Actualizar Recursos

```bash
# Reiniciar deployment (recrear pods)
kubectl rollout restart deployment -n jhon-silva-backend jhon-silva-backend-deployment

# Ver estado del rollout
kubectl rollout status deployment -n jhon-silva-backend jhon-silva-backend-deployment

# Escalar réplicas
kubectl scale deployment jhon-silva-backend-deployment -n jhon-silva-backend --replicas=3

# Aplicar cambios de un archivo modificado
kubectl apply -f k8s/jhon-silva-00-deployment-be.yml
```

### 🗑️ Eliminar Recursos

```bash
# Eliminar un recurso específico
kubectl delete -f k8s/jhon-silva-00-deployment-be.yml

# Eliminar todos los recursos de una carpeta
kubectl delete -f k8s/

# Eliminar un namespace completo (y todo dentro)
kubectl delete namespace jhon-silva-backend

# Eliminar un pod específico (se recreará automáticamente)
kubectl delete pod -n jhon-silva-backend POD_NAME

# Forzar eliminación de un pod
kubectl delete pod -n jhon-silva-backend POD_NAME --grace-period=0 --force
```

### 🔧 Ejecutar Comandos en Pods

```bash
# Entrar al pod (shell interactivo)
kubectl exec -it -n jhon-silva-backend POD_NAME -- /bin/sh

# Ejecutar un comando sin entrar
kubectl exec -n jhon-silva-backend POD_NAME -- env

# Ver archivos dentro del pod
kubectl exec -n jhon-silva-backend POD_NAME -- ls -la /app
```

---

## 4. Comandos MetalLB

### 📥 Instalar MetalLB

```bash
# Descargar e instalar MetalLB v0.14.3
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

# Verificar instalación
kubectl get pods -n metallb-system

# Esperar a que todos los pods estén Running
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s
```

### ⚙️ Configurar MetalLB

```bash
# Aplicar configuración (IPAddressPool + L2Advertisement)
kubectl apply -f metallb-config.yaml

# Verificar configuración
kubectl get ipaddresspools -n metallb-system
kubectl get l2advertisements -n metallb-system
```

### 🔍 Verificar MetalLB

```bash
# Ver pods de MetalLB
kubectl get pods -n metallb-system

# Ver logs del controller
kubectl logs -n metallb-system -l app=metallb,component=controller

# Ver logs del speaker
kubectl logs -n metallb-system -l app=metallb,component=speaker

# Ver IPs asignadas
kubectl get services --all-namespaces -o wide | grep LoadBalancer
```

### 🗑️ Desinstalar MetalLB (si es necesario)

```bash
# Eliminar configuración
kubectl delete -f metallb-config.yaml

# Eliminar MetalLB
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
```

---

## 5. Comandos Port-Forward

### 🔌 Port-Forward Manual

```bash
# Backend: Mapear localhost:8080 -> service:8080
kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080

# Frontend: Mapear localhost:4200 -> service:80
kubectl port-forward -n jhon-silva-frontend service/jhon-silva-frontend-service 4200:80

# Port-forward a un pod específico
kubectl port-forward -n jhon-silva-backend POD_NAME 8080:8080

# Port-forward en background (Linux/Mac)
kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080 &
```

### 🤖 Port-Forward Automático (Script)

```bash
# Windows
.\iniciar-servicios.bat

# El script abre 2 terminales automáticamente con port-forward
```

### 🛑 Detener Port-Forward

```bash
# Presionar Ctrl+C en la terminal donde está corriendo

# Si está en background (Linux/Mac)
# Ver procesos
ps aux | grep port-forward

# Matar proceso
kill PID
```

---

## 6. Comandos Diagnóstico

### 🩺 Checklist de Salud

```bash
# 1. Ver estado de todos los recursos
kubectl get all --all-namespaces

# 2. Ver eventos recientes (errores, warnings)
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# 3. Ver pods con problemas
kubectl get pods --all-namespaces | grep -v Running

# 4. Ver servicios sin IP externa
kubectl get services --all-namespaces | grep pending
```

### 🔍 Diagnóstico de Problemas

```bash
# Ver por qué un pod no arranca
kubectl describe pod -n jhon-silva-backend POD_NAME

# Ver logs de error
kubectl logs -n jhon-silva-backend POD_NAME --previous

# Ver uso de recursos
kubectl top nodes
kubectl top pods -n jhon-silva-backend

# Ver configuración completa de un deployment
kubectl get deployment -n jhon-silva-backend jhon-silva-backend-deployment -o yaml

# Verificar conectividad desde un pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Dentro del pod:
wget -O- http://jhon-silva-backend-service.jhon-silva-backend:8080/api/users
```

### 🧪 Probar Endpoints

```bash
# Probar backend (con port-forward activo)
curl http://localhost:8080/api/users

# Probar backend (usando NodePort)
curl http://localhost:30080/api/users

# Probar frontend
curl http://localhost:4200

# Probar desde dentro del cluster
kubectl run -it --rm curl-pod --image=curlimages/curl --restart=Never -- \
  curl http://jhon-silva-backend-service.jhon-silva-backend:8080/api/users
```

---

## 7. Comandos Base de Datos

### 🔗 Conectarse a Neon Database

```bash
# Instalar psql (si no lo tienes)
# Windows: Incluido con PostgreSQL
# Mac: brew install postgresql
# Linux: apt install postgresql-client

# Conectarse
psql "postgresql://neondb_owner:npg_pHT4NJx3gnSG@ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require"
```

### 🗃️ Comandos SQL Útiles

```sql
-- Ver todas las tablas
\dt

-- Describir tabla users
\d users

-- Ver todos los usuarios
SELECT * FROM users;

-- Contar usuarios
SELECT COUNT(*) FROM users;

-- Ver usuarios por estado
SELECT status, COUNT(*) FROM users GROUP BY status;

-- Crear un usuario de prueba
INSERT INTO users (username, email, first_name, last_name, phone, address, status)
VALUES ('testuser', 'test@example.com', 'Test', 'User', '1234567890', 'Test Address', 'ACTIVE');

-- Actualizar un usuario
UPDATE users SET status = 'INACTIVE' WHERE id = 1;

-- Eliminar un usuario
DELETE FROM users WHERE id = 1;

-- Salir
\q
```

### 🔧 Verificar Schema

```sql
-- Ver estructura de la tabla
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users';

-- Recrear tabla (si es necesario)
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 8. Scripts del Proyecto

### 🚀 iniciar-servicios.bat

```bash
# Ejecutar (Windows)
.\iniciar-servicios.bat

# Qué hace:
# 1. Abre terminal para port-forward del backend (8080)
# 2. Abre terminal para port-forward del frontend (4200)
# 3. Accesos:
#    - Backend: http://localhost:8080/api/users
#    - Frontend: http://localhost:4200
```

### 🏗️ Script de Despliegue Completo (Ejemplo)

```bash
#!/bin/bash
# deploy.sh - Desplegar todo el proyecto

echo "🚀 Desplegando Backend..."
cd demo
kubectl apply -f k8s/

echo "⏳ Esperando a que el backend esté listo..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/jhon-silva-backend-deployment -n jhon-silva-backend

echo "🚀 Desplegando Frontend..."
cd ../demo-front
kubectl apply -f k8s/

echo "⏳ Esperando a que el frontend esté listo..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/jhon-silva-frontend-deployment -n jhon-silva-frontend

echo "✅ Despliegue completado!"
echo "📊 Estado de los recursos:"
kubectl get all -n jhon-silva-backend
kubectl get all -n jhon-silva-frontend

echo "🔗 Accesos:"
echo "Backend: http://172.19.255.200:8080/api/users"
echo "Frontend: http://172.19.255.201"
echo ""
echo "💡 Recuerda ejecutar port-forward para acceder desde Windows:"
echo ".\iniciar-servicios.bat"
```

---

## 📚 Comandos por Escenario

### 🆕 Primera Vez - Despliegue Inicial

```bash
# 1. Instalar MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl apply -f metallb-config.yaml

# 2. Desplegar Backend
cd demo
kubectl apply -f k8s/

# 3. Desplegar Frontend
cd ../demo-front
kubectl apply -f k8s/

# 4. Verificar
kubectl get pods --all-namespaces
kubectl get services --all-namespaces

# 5. Acceder
.\iniciar-servicios.bat
```

### 🔄 Actualizar Aplicación

```bash
# 1. Reconstruir imagen
docker build -t jhonbrayansilvalaura/jhon-silva-be:1.1 .
docker push jhonbrayansilvalaura/jhon-silva-be:1.1

# 2. Actualizar deployment
# Editar k8s/jhon-silva-00-deployment-be.yml
# Cambiar image: jhonbrayansilvalaura/jhon-silva-be:1.1

# 3. Aplicar cambios
kubectl apply -f k8s/jhon-silva-00-deployment-be.yml

# 4. Verificar rollout
kubectl rollout status deployment -n jhon-silva-backend jhon-silva-backend-deployment
```

### 🧹 Limpiar Todo

```bash
# Eliminar aplicaciones
kubectl delete namespace jhon-silva-backend
kubectl delete namespace jhon-silva-frontend

# Eliminar MetalLB (opcional)
kubectl delete -f metallb-config.yaml
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

# Limpiar Docker
docker image prune -a
```

### 🔍 Debugging Rápido

```bash
# Ver qué está fallando
kubectl get pods --all-namespaces | grep -v Running

# Ver logs del backend
kubectl logs -n jhon-silva-backend -l app=jhon-silva-backend --tail=100

# Ver logs del frontend
kubectl logs -n jhon-silva-frontend -l app=jhon-silva-frontend --tail=100

# Reiniciar todo
kubectl rollout restart deployment -n jhon-silva-backend jhon-silva-backend-deployment
kubectl rollout restart deployment -n jhon-silva-frontend jhon-silva-frontend-deployment
```

---

## 🎯 Atajos y Tips

```bash
# Alias útiles (agregar a ~/.bashrc o ~/.zshrc)
alias k='kubectl'
alias kgp='kubectl get pods --all-namespaces'
alias kgs='kubectl get services --all-namespaces'
alias kl='kubectl logs -f'
alias kd='kubectl describe'

# Autocompletado de kubectl (Bash)
source <(kubectl completion bash)

# Autocompletado de kubectl (Zsh)
source <(kubectl completion zsh)

# Ver recursos con watch (actualización automática)
watch kubectl get pods -n jhon-silva-backend

# JSON query con jq
kubectl get pods -n jhon-silva-backend -o json | jq '.items[].metadata.name'
```

---

**✅ ¡Guarda este documento para referencia rápida!**
