# 🚀 GUÍA COMPLETA DE EJECUCIÓN

## 📋 PREREQUISITOS

Antes de empezar, asegúrate de tener:

- ✅ Docker Desktop instalado y corriendo
- ✅ Kubernetes habilitado en Docker Desktop
- ✅ kubectl instalado
- ✅ Las imágenes Docker en Docker Hub

### Verificar prerequisitos:

```bash
# Docker
docker --version

# Kubernetes
kubectl version --client

# Cluster activo
kubectl cluster-info

# Context actual
kubectl config current-context
```

**Resultado esperado**: `docker-desktop`

---

## 🎯 PASO 1: INSTALAR METALLB

### ¿Qué es?
MetalLB es un balanceador de carga para clusters que no tienen LoadBalancer nativo (como Docker Desktop).

### Instalación:

```bash
# 1. Aplicar manifiestos de MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

# 2. Esperar a que esté listo (puede tardar 1-2 minutos)
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s

# 3. Verificar que esté corriendo
kubectl get pods -n metallb-system
```

**Deberías ver**:
```
NAME                          READY   STATUS    RESTARTS   AGE
controller-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
speaker-xxxxx                 1/1     Running   0          2m
speaker-xxxxx                 1/1     Running   0          2m
speaker-xxxxx                 1/1     Running   0          2m
speaker-xxxxx                 1/1     Running   0          2m
```

### Configurar pool de IPs:

```bash
# Aplicar configuración de IPs
kubectl apply -f c:\Users\USER\Documents\JalatonJuC\metallb-config.yaml

# Verificar
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
```

---

## 🎯 PASO 2: DESPLEGAR BACKEND

### Navegar a la carpeta:

```bash
cd c:\Users\USER\Documents\JalatonJuC\demo
```

### Aplicar manifiestos (en orden):

```bash
# 1. Namespace
kubectl apply -f k8s/jhon-silva-00-namespace-be.yml

# 2. Secret
kubectl apply -f k8s/jhon-silva-00-secret-be.yml

# 3. Service
kubectl apply -f k8s/jhon-silva-00-service-be.yml

# 4. Deployment
kubectl apply -f k8s/jhon-silva-00-deployment-be.yml
```

O todos a la vez:
```bash
kubectl apply -f k8s/
```

### Verificar:

```bash
# Ver todo
kubectl get all -n jhon-silva-backend

# Ver pods (espera hasta que estén 2/2 Running)
kubectl get pods -n jhon-silva-backend

# Ver servicio (debe tener EXTERNAL-IP)
kubectl get service -n jhon-silva-backend
```

**Resultado esperado**:
```
NAME                         TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
jhon-silva-backend-service   LoadBalancer   10.96.240.191   172.19.255.200   8080:30080/TCP
```

### Ver logs:

```bash
kubectl logs -n jhon-silva-backend -l app=jhon-silva-backend --tail=50
```

---

## 🎯 PASO 3: DESPLEGAR FRONTEND

### Navegar a la carpeta:

```bash
cd c:\Users\USER\Documents\JalatonJuC\demo-front
```

### Aplicar manifiestos:

```bash
# 1. Namespace
kubectl apply -f k8s/jhon-silva-00-namespace-fe.yml

# 2. Secret
kubectl apply -f k8s/jhon-silva-00-secret-fe.yml

# 3. Service
kubectl apply -f k8s/jhon-silva-00-service-fe.yml

# 4. Deployment
kubectl apply -f k8s/jhon-silva-00-deployment-fe.yml
```

O todos a la vez:
```bash
kubectl apply -f k8s/
```

### Verificar:

```bash
# Ver todo
kubectl get all -n jhon-silva-frontend

# Ver pods
kubectl get pods -n jhon-silva-frontend

# Ver servicio
kubectl get service -n jhon-silva-frontend
```

**Resultado esperado**:
```
NAME                          TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)
jhon-silva-frontend-service   LoadBalancer   10.96.169.81   172.19.255.201   80:30200/TCP
```

---

## 🎯 PASO 4: EXPONER SERVICIOS CON PORT-FORWARD

### Opción A: Usar el script (RECOMENDADO)

```bash
# Navegar a la carpeta
cd c:\Users\USER\Documents\JalatonJuC

# Ejecutar script (doble clic o desde terminal)
iniciar-servicios.bat
```

**Qué hace**:
- Abre 2 ventanas automáticamente
- Backend en `localhost:8080`
- Frontend en `localhost:4200`

### Opción B: Manual (2 terminales)

**Terminal 1 - Backend**:
```bash
kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080
```

**Terminal 2 - Frontend**:
```bash
kubectl port-forward -n jhon-silva-frontend service/jhon-silva-frontend-service 4200:80
```

**⚠️ Mantén ambas terminales abiertas**

---

## 🎯 PASO 5: PROBAR LA APLICACIÓN

### Backend API:

```bash
# Listar usuarios
curl http://localhost:8080/api/users

# Obtener usuario por ID
curl http://localhost:8080/api/users/1

# Crear usuario
curl -X POST http://localhost:8080/api/users -H "Content-Type: application/json" -d "{\"username\":\"testuser\",\"email\":\"test@example.com\",\"firstName\":\"Test\",\"lastName\":\"User\",\"phone\":\"+51-999-888-777\",\"address\":\"Test Street 123\"}"

# Activar usuario
curl -X PATCH http://localhost:8080/api/users/3/activate

# Desactivar usuario
curl -X PATCH http://localhost:8080/api/users/1/deactivate

# Suspender usuario
curl -X PATCH http://localhost:8080/api/users/2/suspend

# Actualizar usuario
curl -X PUT http://localhost:8080/api/users/1 -H "Content-Type: application/json" -d "{\"username\":\"updated\",\"email\":\"updated@test.com\",\"firstName\":\"Updated\",\"lastName\":\"User\",\"phone\":\"+51-999\",\"address\":\"Updated St\",\"status\":\"ACTIVE\"}"

# Eliminar usuario
curl -X DELETE http://localhost:8080/api/users/4
```

### Frontend Web:

Abre tu navegador en:
```
http://localhost:4200
```

**Deberías ver**:
- Lista de usuarios
- Formulario para crear
- Botones para editar, eliminar
- Botones condicionales (Activar/Desactivar/Suspender)
- Iconos Font Awesome

---

## 📊 VERIFICACIÓN COMPLETA

### Ver todo lo desplegado:

```bash
# Todos los namespaces
kubectl get namespaces

# Backend completo
kubectl get all -n jhon-silva-backend

# Frontend completo
kubectl get all -n jhon-silva-frontend

# Todos los servicios LoadBalancer
kubectl get services --all-namespaces | findstr LoadBalancer
```

### Estado esperado:

#### Namespaces:
```
jhon-silva-backend     Active
jhon-silva-frontend    Active
metallb-system         Active
```

#### Backend:
```
pod/jhon-silva-backend-deployment-xxxxx   1/1     Running
pod/jhon-silva-backend-deployment-xxxxx   1/1     Running

service/jhon-silva-backend-service   LoadBalancer   10.x.x.x   172.19.255.200   8080:30080/TCP

deployment.apps/jhon-silva-backend-deployment   2/2     2            2
```

#### Frontend:
```
pod/jhon-silva-frontend-deployment-xxxxx   1/1     Running
pod/jhon-silva-frontend-deployment-xxxxx   1/1     Running

service/jhon-silva-frontend-service   LoadBalancer   10.x.x.x   172.19.255.201   80:30200/TCP

deployment.apps/jhon-silva-frontend-deployment   2/2     2            2
```

---

## 🔧 COMANDOS ÚTILES

### Ver logs en tiempo real:

```bash
# Backend
kubectl logs -n jhon-silva-backend -l app=jhon-silva-backend -f

# Frontend
kubectl logs -n jhon-silva-frontend -l app=jhon-silva-frontend -f
```

### Reiniciar servicios:

```bash
# Backend
kubectl rollout restart deployment jhon-silva-backend-deployment -n jhon-silva-backend

# Frontend
kubectl rollout restart deployment jhon-silva-frontend-deployment -n jhon-silva-frontend
```

### Escalar réplicas:

```bash
# Backend a 3 pods
kubectl scale deployment jhon-silva-backend-deployment --replicas=3 -n jhon-silva-backend

# Frontend a 3 pods
kubectl scale deployment jhon-silva-frontend-deployment --replicas=3 -n jhon-silva-frontend

# Volver a 2
kubectl scale deployment jhon-silva-backend-deployment --replicas=2 -n jhon-silva-backend
kubectl scale deployment jhon-silva-frontend-deployment --replicas=2 -n jhon-silva-frontend
```

### Entrar a un pod:

```bash
# Backend
kubectl exec -it -n jhon-silva-backend <pod-name> -- /bin/sh

# Frontend
kubectl exec -it -n jhon-silva-frontend <pod-name> -- /bin/sh

# Ver variables de entorno
kubectl exec -n jhon-silva-backend <pod-name> -- env | grep DB_
```

### Ver eventos:

```bash
# Backend
kubectl get events -n jhon-silva-backend --sort-by='.lastTimestamp'

# Frontend
kubectl get events -n jhon-silva-frontend --sort-by='.lastTimestamp'
```

---

## 🛑 CÓMO DETENER TODO

### Detener port-forwards:
- Cierra las ventanas que abrió `iniciar-servicios.bat`
- O presiona `Ctrl+C` en cada terminal

### Eliminar deployments (mantiene namespace y service):

```bash
kubectl delete deployment jhon-silva-backend-deployment -n jhon-silva-backend
kubectl delete deployment jhon-silva-frontend-deployment -n jhon-silva-frontend
```

### Eliminar todo el namespace (borra todo):

```bash
kubectl delete namespace jhon-silva-backend
kubectl delete namespace jhon-silva-frontend
```

### Desinstalar MetalLB:

```bash
kubectl delete -f c:\Users\USER\Documents\JalatonJuC\metallb-config.yaml
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
```

---

## 🔄 REINICIAR TODO DESDE CERO

```bash
# 1. Eliminar todo
kubectl delete namespace jhon-silva-backend
kubectl delete namespace jhon-silva-frontend

# 2. Volver a desplegar
cd c:\Users\USER\Documents\JalatonJuC\demo
kubectl apply -f k8s/

cd c:\Users\USER\Documents\JalatonJuC\demo-front
kubectl apply -f k8s/

# 3. Esperar a que estén listos
kubectl get pods -n jhon-silva-backend --watch
kubectl get pods -n jhon-silva-frontend --watch

# 4. Ejecutar port-forward
cd c:\Users\USER\Documents\JalatonJuC
iniciar-servicios.bat
```

---

## 🎓 RESUMEN DE EJECUCIÓN

### Orden completo:

1. ✅ Instalar MetalLB
2. ✅ Configurar pool de IPs
3. ✅ Desplegar backend (namespace → secret → service → deployment)
4. ✅ Desplegar frontend (namespace → secret → service → deployment)
5. ✅ Ejecutar `iniciar-servicios.bat`
6. ✅ Abrir `http://localhost:4200`

### URLs finales:

- **Backend API**: http://localhost:8080
- **Frontend Web**: http://localhost:4200
- **LoadBalancer Backend**: 172.19.255.200:8080 (solo interno)
- **LoadBalancer Frontend**: 172.19.255.201:80 (solo interno)

### Tiempo estimado:

- Instalación MetalLB: 2-3 minutos
- Deploy backend: 1-2 minutos
- Deploy frontend: 1-2 minutos
- **Total**: ~5-7 minutos

¡Todo listo para ejecutar mano! 🚀✨
