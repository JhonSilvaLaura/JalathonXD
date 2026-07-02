# ☸️ ARCHIVOS KUBERNETES - FRONTEND

## 📁 ESTRUCTURA DE ARCHIVOS

```
demo-front/k8s/
├── jhon-silva-00-namespace-fe.yml
├── jhon-silva-00-secret-fe.yml
├── jhon-silva-00-service-fe.yml
└── jhon-silva-00-deployment-fe.yml
```

**4 archivos obligatorios** como pidió el profe.

---

## 1️⃣ NAMESPACE (jhon-silva-00-namespace-fe.yml)

### 📄 Contenido Completo:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: jhon-silva-frontend
  labels:
    name: jhon-silva-frontend
    environment: production
    app: angular-crud
```

### 🔍 Explicación:

```yaml
metadata:
  name: jhon-silva-frontend
```
- **Nombre**: `jhon-silva-frontend`
- **Diferente** del backend: `jhon-silva-backend`
- **Por qué**: Simular 2 clusters separados

```yaml
  labels:
    name: jhon-silva-frontend
    environment: production
    app: angular-crud
```
- **app: angular-crud**: Identifica que es Angular

### 📝 Comandos:

```bash
# Crear
kubectl apply -f jhon-silva-00-namespace-fe.yml

# Ver
kubectl get namespace jhon-silva-frontend

# Ver todo en el namespace
kubectl get all -n jhon-silva-frontend
```

---

## 2️⃣ SECRET (jhon-silva-00-secret-fe.yml)

### 📄 Contenido Completo:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jhon-silva-frontend-secrets
  namespace: jhon-silva-frontend
type: Opaque
data:
  # Valor actual: http://localhost:30080 (NodePort automático)
  API_URL: aHR0cDovL2xvY2FsaG9zdDozMDA4MA==
```

### 🔍 Explicación:

```yaml
data:
  API_URL: aHR0cDovL2xvY2FsaG9zdDozMDA4MA==
```

**Valor original**: `http://localhost:30080`  
**En base64**: `aHR0cDovL2xvY2FsaG9zdDozMDA4MA==`

### 🔧 Cómo se generó:

```bash
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://localhost:30080'))"
```

### ⚠️ IMPORTANTE:

Este secret tiene **3 versiones** posibles:

#### Versión 1: Con port-forward (8080)
```yaml
# Valor: http://localhost:8080
API_URL: aHR0cDovL2xvY2FsaG9zdDo4MDgw
```
**Usar cuando**: Ejecutas `iniciar-servicios.bat`

#### Versión 2: Con NodePort (30080)
```yaml
# Valor: http://localhost:30080
API_URL: aHR0cDovL2xvY2FsaG9zdDozMDA4MA==
```
**Usar cuando**: NodePort funciona en tu entorno

#### Versión 3: Con LoadBalancer IP (172.19.255.200)
```yaml
# Valor: http://172.19.255.200:8080
API_URL: aHR0cDovLzE3Mi4xOS4yNTUuMjAwOjgwODA=
```
**Usar cuando**: En un cluster real (AWS, GCP, Azure)

### 📝 Comandos:

```bash
# Crear
kubectl apply -f jhon-silva-00-secret-fe.yml

# Ver
kubectl get secret jhon-silva-frontend-secrets -n jhon-silva-frontend

# Decodificar API_URL
kubectl get secret jhon-silva-frontend-secrets -n jhon-silva-frontend -o jsonpath='{.data.API_URL}' | base64 -d
```

---

## 3️⃣ SERVICE (jhon-silva-00-service-fe.yml)

### 📄 Contenido Completo:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: jhon-silva-frontend-service
  namespace: jhon-silva-frontend
  labels:
    app: jhon-silva-frontend
    tier: frontend
spec:
  type: LoadBalancer
  selector:
    app: jhon-silva-frontend
    tier: frontend
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30200
  sessionAffinity: ClientIP
```

### 🔍 Explicación:

```yaml
spec:
  type: LoadBalancer
```
- **LoadBalancer**: Expone externamente
- **MetalLB asigna**: `172.19.255.201`

```yaml
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30200
```

| Campo | Valor | Significado |
|-------|-------|-------------|
| **port** | 80 | Puerto del Service |
| **targetPort** | 80 | Puerto de Nginx en el pod |
| **nodePort** | 30200 | Puerto en el nodo |

**Diferencias con backend**:
- Backend usa puerto 8080
- Frontend usa puerto 80 (HTTP estándar)

### 📊 Flujo de Tráfico:

```
Navegador
  ↓
LoadBalancer IP (172.19.255.201:80)
  ↓
Service (port 80)
  ↓
Pod 1 (Nginx:80) o Pod 2 (Nginx:80)
  ↓
Angular App (archivos estáticos)
```

### 📝 Comandos:

```bash
# Crear
kubectl apply -f jhon-silva-00-service-fe.yml

# Ver
kubectl get service jhon-silva-frontend-service -n jhon-silva-frontend

# Ver con detalles
kubectl describe service jhon-silva-frontend-service -n jhon-silva-frontend
```

---

## 4️⃣ DEPLOYMENT (jhon-silva-00-deployment-fe.yml)

### 📄 Contenido Completo:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jhon-silva-frontend-deployment
  namespace: jhon-silva-frontend
  labels:
    app: jhon-silva-frontend
    tier: frontend
    version: "1.0"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: jhon-silva-frontend
      tier: frontend
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: jhon-silva-frontend
        tier: frontend
        version: "1.0"
    spec:
      containers:
      - name: jhon-silva-frontend
        image: jhonbrayansilvalaura/jhon-silva-fe:1.0
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
      restartPolicy: Always
```

### 🔍 Explicación por Secciones:

#### Replicas:

```yaml
spec:
  replicas: 2
```
- **2 pods**: Alta disponibilidad
- **Igual que backend**: 2 réplicas

#### Contenedor:

```yaml
      containers:
      - name: jhon-silva-frontend
        image: jhonbrayansilvalaura/jhon-silva-fe:1.0
```
- **Imagen**: De Docker Hub
- **Tamaño**: 26.4MB (muy ligera)
- **Contiene**: Nginx + Angular compilado

```yaml
        ports:
        - name: http
          containerPort: 80
```
- **containerPort 80**: Nginx escucha en puerto 80
- **No 8080**: Frontend usa puerto estándar HTTP

#### Recursos (Menor que Backend):

```yaml
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

| Servicio | Memoria Request | CPU Request |
|----------|-----------------|-------------|
| Backend | 256Mi | 250m |
| Frontend | 64Mi | 100m |

**Por qué menos**: 
- Frontend solo sirve archivos estáticos
- Backend procesa datos y DB

#### Health Checks:

```yaml
        livenessProbe:
          httpGet:
            path: /
            port: 80
```
- **path: /**: Raíz del sitio
- **Backend usa**: `/api/users`
- **Por qué**: Frontend no tiene API, solo HTML

#### NO hay variables de entorno:

**Diferencia importante**:
- Backend: Tiene `env` con secrets
- Frontend: **NO tiene** `env`

**Por qué**: 
- La URL del backend está compilada en el build de Angular
- Se define en `environment.ts` antes de compilar
- No se puede cambiar en runtime sin recompilar

### 📝 Comandos:

```bash
# Crear
kubectl apply -f jhon-silva-00-deployment-fe.yml

# Ver deployment
kubectl get deployment jhon-silva-frontend-deployment -n jhon-silva-frontend

# Ver pods
kubectl get pods -n jhon-silva-frontend

# Ver logs de Nginx
kubectl logs -n jhon-silva-frontend -l app=jhon-silva-frontend

# Reiniciar
kubectl rollout restart deployment jhon-silva-frontend-deployment -n jhon-silva-frontend
```

---

## 🎯 ORDEN DE APLICACIÓN

```bash
# 1. Namespace
kubectl apply -f jhon-silva-00-namespace-fe.yml

# 2. Secret
kubectl apply -f jhon-silva-00-secret-fe.yml

# 3. Service
kubectl apply -f jhon-silva-00-service-fe.yml

# 4. Deployment
kubectl apply -f jhon-silva-00-deployment-fe.yml
```

O todos a la vez:
```bash
cd demo-front
kubectl apply -f k8s/
```

---

## 📊 COMPARACIÓN: BACKEND vs FRONTEND

| Característica | Backend | Frontend |
|----------------|---------|----------|
| **Namespace** | jhon-silva-backend | jhon-silva-frontend |
| **Puerto Service** | 8080 | 80 |
| **Puerto Container** | 8080 | 80 |
| **NodePort** | 30080 | 30200 |
| **LoadBalancer IP** | 172.19.255.200 | 172.19.255.201 |
| **Réplicas** | 2 | 2 |
| **Memoria Request** | 256Mi | 64Mi |
| **CPU Request** | 250m | 100m |
| **Health Check Path** | /api/users | / |
| **Variables de Entorno** | Sí (4) | No |
| **Imagen** | jhon-silva-be:1.0 (102MB) | jhon-silva-fe:1.0 (26.4MB) |

---

## 🔗 CONEXIÓN BACKEND ↔ FRONTEND

### Cómo se conectan:

```
Frontend (Angular en navegador)
  ↓
Hace fetch a: http://localhost:30080/api/users
  ↓
Port-forward redirige a: Service Backend
  ↓
Service Backend distribuye a: Pod Backend 1 o 2
  ↓
Spring Boot procesa y responde
  ↓
Respuesta JSON llega a Angular
```

### Configuración en Angular:

**Archivo**: `demo-front/src/environments/environment.ts`

```typescript
export const environment = {
  production: true,
  apiUrl: 'http://localhost:30080'  // URL del backend
};
```

**Esta URL se compila** en el build de Angular y se incluye en la imagen Docker.

---

## 🎯 ARQUITECTURA COMPLETA

```
┌─────────────────────────────────────────────┐
│         FRONTEND NAMESPACE                  │
│  (jhon-silva-frontend)                      │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │ LoadBalancer: 172.19.255.201:80       │ │
│  └─────────────┬──────────────────────────┘ │
│                │                             │
│  ┌─────────────▼──────────────────────────┐ │
│  │ Service: jhon-silva-frontend-service  │ │
│  └─────────────┬──────────────────────────┘ │
│                │                             │
│       ┌────────┴────────┐                   │
│       │                 │                   │
│  ┌────▼─────┐     ┌────▼─────┐             │
│  │ Pod 1    │     │ Pod 2    │             │
│  │ Nginx:80 │     │ Nginx:80 │             │
│  └──────────┘     └──────────┘             │
│                                              │
└─────────────────────────────────────────────┘
                    │
                    │ API calls
                    │
┌───────────────────▼─────────────────────────┐
│         BACKEND NAMESPACE                   │
│  (jhon-silva-backend)                       │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │ LoadBalancer: 172.19.255.200:8080     │ │
│  └─────────────┬──────────────────────────┘ │
│                │                             │
│  ┌─────────────▼──────────────────────────┐ │
│  │ Service: jhon-silva-backend-service   │ │
│  └─────────────┬──────────────────────────┘ │
│                │                             │
│       ┌────────┴────────┐                   │
│       │                 │                   │
│  ┌────▼──────┐    ┌────▼──────┐            │
│  │ Pod 1     │    │ Pod 2     │            │
│  │ Spring:80 │    │ Spring:80 │            │
│  └─────┬─────┘    └─────┬─────┘            │
│        │                │                   │
└────────┼────────────────┼───────────────────┘
         │                │
         └────────┬───────┘
                  │
        ┌─────────▼──────────┐
        │  PostgreSQL Neon   │
        │  (Cloud Database)  │
        └────────────────────┘
```

---

## 🎓 RESUMEN

| Archivo | Función |
|---------|---------|
| **namespace** | Aísla recursos del frontend |
| **secret** | Guarda URL del backend en base64 |
| **service** | Expone pods en puerto 80 |
| **deployment** | Crea 2 pods con Nginx + Angular |

**Diferencias clave con backend**:
- Puerto 80 en vez de 8080
- Menos recursos (más ligero)
- Health check en `/` en vez de `/api/users`
- No tiene variables de entorno (URL compilada)

¡Frontend K8s completamente explicado mano! ☸️✨
