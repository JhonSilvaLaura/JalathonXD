# ☸️ ARCHIVOS KUBERNETES - BACKEND

## 📁 ESTRUCTURA DE ARCHIVOS

```
demo/k8s/
├── jhon-silva-00-namespace-be.yml
├── jhon-silva-00-secret-be.yml
├── jhon-silva-00-service-be.yml
└── jhon-silva-00-deployment-be.yml
```

**4 archivos obligatorios** como pidió el profe.

---

## 1️⃣ NAMESPACE (jhon-silva-00-namespace-be.yml)

### 📄 Contenido Completo:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: jhon-silva-backend
  labels:
    name: jhon-silva-backend
    environment: production
    app: webflux-crud
```

### 🔍 Explicación Línea por Línea:

```yaml
apiVersion: v1
```
- **Qué es**: Versión de la API de Kubernetes
- **v1**: API estable y madura

```yaml
kind: Namespace
```
- **Qué es**: Tipo de recurso
- **Namespace**: Aislamiento lógico de recursos

```yaml
metadata:
  name: jhon-silva-backend
```
- **Qué es**: Nombre único del namespace
- **Se usa en**: Todos los comandos (`-n jhon-silva-backend`)

```yaml
  labels:
    name: jhon-silva-backend
    environment: production
    app: webflux-crud
```
- **Qué son**: Etiquetas para organizar
- **name**: Identificador
- **environment**: Entorno (production, dev, test)
- **app**: Tipo de aplicación

### 🎯 ¿Para qué sirve?

- **Aislamiento**: Separa recursos backend de otros
- **Organización**: Todo el backend en un lugar
- **Seguridad**: Permisos por namespace
- **Cuotas**: Limitar recursos por namespace

### 📝 Comandos:

```bash
# Crear
kubectl apply -f jhon-silva-00-namespace-be.yml

# Ver
kubectl get namespace jhon-silva-backend

# Describir
kubectl describe namespace jhon-silva-backend

# Ver todo en el namespace
kubectl get all -n jhon-silva-backend
```

---

## 2️⃣ SECRET (jhon-silva-00-secret-be.yml)

### 📄 Contenido Completo:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jhon-silva-backend-secrets
  namespace: jhon-silva-backend
type: Opaque
data:
  # Base de datos Neon PostgreSQL (Cloud) - Valores en base64
  DB_URL: cjJkYmM6cG9zdGdyZXNxbDovL2VwLXJvdWdoLXZpb2xldC1hZGk2cmkway1wb29sZXIuYy0yLnVzLWVhc3QtMS5hd3MubmVvbi50ZWNoL2RlbW8/c3NsbW9kZT1yZXF1aXJl
  DB_USERNAME: bmVvbmRiX293bmVy
  DB_PASSWORD: bnBnX3BIVDROSngzZ25TRw==
  SERVER_PORT: ODA4MA==
```

### 🔍 Explicación:

```yaml
kind: Secret
```
- **Qué es**: Almacenamiento de datos sensibles
- **Sensibles**: Passwords, tokens, keys

```yaml
type: Opaque
```
- **Qué es**: Tipo de secret
- **Opaque**: Secret genérico (datos arbitrarios)

```yaml
data:
```
- **data vs stringData**: `data` requiere base64
- **Por qué data**: El profe pidió "hasheado" (base64)

```yaml
  DB_URL: cjJk...
```
- **Valor original**: `r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require`
- **En base64**: `cjJkYmM6cG9zdGdyZXNxbDovL...`

### 📊 Tabla de Valores:

| Clave | Valor Original | Uso |
|-------|----------------|-----|
| DB_URL | `r2dbc:postgresql://...` | Conexión a Neon DB |
| DB_USERNAME | `neondb_owner` | Usuario de la DB |
| DB_PASSWORD | `npg_pHT4NJx3gnSG` | Password de la DB |
| SERVER_PORT | `8080` | Puerto del backend |

### 🔧 Cómo se generaron:

```bash
# DB_URL
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require'))"

# DB_USERNAME
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('neondb_owner'))"

# DB_PASSWORD
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('npg_pHT4NJx3gnSG'))"

# SERVER_PORT
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('8080'))"
```

### 📝 Comandos:

```bash
# Crear
kubectl apply -f jhon-silva-00-secret-be.yml

# Ver (sin mostrar valores)
kubectl get secret jhon-silva-backend-secrets -n jhon-silva-backend

# Ver con valores en base64
kubectl get secret jhon-silva-backend-secrets -n jhon-silva-backend -o yaml

# Decodificar un valor
kubectl get secret jhon-silva-backend-secrets -n jhon-silva-backend -o jsonpath='{.data.DB_USERNAME}' | base64 -d
```

---

## 3️⃣ SERVICE (jhon-silva-00-service-be.yml)

### 📄 Contenido Completo:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: jhon-silva-backend-service
  namespace: jhon-silva-backend
  labels:
    app: jhon-silva-backend
    tier: backend
spec:
  type: LoadBalancer
  selector:
    app: jhon-silva-backend
    tier: backend
  ports:
  - name: http
    protocol: TCP
    port: 8080
    targetPort: 8080
    nodePort: 30080
  sessionAffinity: ClientIP
```

### 🔍 Explicación:

```yaml
kind: Service
```
- **Qué es**: Expone un conjunto de pods
- **Para qué**: Punto de acceso estable

```yaml
spec:
  type: LoadBalancer
```
- **LoadBalancer**: Expone el servicio externamente
- **Alternativas**: ClusterIP, NodePort
- **Requiere**: MetalLB en Docker Desktop

```yaml
  selector:
    app: jhon-silva-backend
    tier: backend
```
- **Qué hace**: Busca pods con estas etiquetas
- **Matchea con**: Labels del Deployment

```yaml
  ports:
  - name: http
    protocol: TCP
    port: 8080
    targetPort: 8080
    nodePort: 30080
```

| Campo | Valor | Significado |
|-------|-------|-------------|
| **name** | http | Nombre del puerto |
| **protocol** | TCP | Protocolo (TCP/UDP) |
| **port** | 8080 | Puerto del Service |
| **targetPort** | 8080 | Puerto del Pod |
| **nodePort** | 30080 | Puerto en el nodo (30000-32767) |

```yaml
  sessionAffinity: ClientIP
```
- **Qué hace**: Sticky sessions
- **ClientIP**: Mismo cliente → mismo pod

### 📊 Flujo de Tráfico:

```
Cliente
  ↓
LoadBalancer IP (172.19.255.200:8080)
  ↓
Service (port 8080)
  ↓
Pod 1 (targetPort 8080) o Pod 2 (targetPort 8080)
  ↓
Spring Boot App
```

### 📝 Comandos:

```bash
# Crear
kubectl apply -f jhon-silva-00-service-be.yml

# Ver
kubectl get service jhon-silva-backend-service -n jhon-silva-backend

# Ver con detalles
kubectl describe service jhon-silva-backend-service -n jhon-silva-backend

# Ver endpoints (pods conectados)
kubectl get endpoints jhon-silva-backend-service -n jhon-silva-backend
```

---

## 4️⃣ DEPLOYMENT (jhon-silva-00-deployment-be.yml)

### 📄 Contenido Completo:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jhon-silva-backend-deployment
  namespace: jhon-silva-backend
  labels:
    app: jhon-silva-backend
    tier: backend
    version: "1.0"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: jhon-silva-backend
      tier: backend
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: jhon-silva-backend
        tier: backend
        version: "1.0"
    spec:
      containers:
      - name: jhon-silva-backend
        image: jhonbrayansilvalaura/jhon-silva-be:1.0
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        env:
        - name: DB_URL
          valueFrom:
            secretKeyRef:
              name: jhon-silva-backend-secrets
              key: DB_URL
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: jhon-silva-backend-secrets
              key: DB_USERNAME
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: jhon-silva-backend-secrets
              key: DB_PASSWORD
        - name: SERVER_PORT
          valueFrom:
            secretKeyRef:
              name: jhon-silva-backend-secrets
              key: SERVER_PORT
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /api/users
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /api/users
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
      restartPolicy: Always
```

### 🔍 Explicación por Secciones:

#### Metadata y Replicas:

```yaml
spec:
  replicas: 2
```
- **Qué hace**: Crea 2 pods idénticos
- **Alta disponibilidad**: Si uno falla, otro sigue
- **Load balancing**: Distribuye tráfico

#### Selector:

```yaml
  selector:
    matchLabels:
      app: jhon-silva-backend
      tier: backend
```
- **Qué hace**: Identifica qué pods pertenecen a este Deployment
- **Debe coincidir**: Con labels del template

#### Estrategia de Actualización:

```yaml
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

| Campo | Valor | Significado |
|-------|-------|-------------|
| **type** | RollingUpdate | Actualización gradual |
| **maxSurge** | 1 | Max 1 pod extra durante update |
| **maxUnavailable** | 0 | Siempre al menos 2 pods running |

#### Contenedor:

```yaml
      containers:
      - name: jhon-silva-backend
        image: jhonbrayansilvalaura/jhon-silva-be:1.0
```
- **image**: Imagen de Docker Hub
- **imagePullPolicy: Always**: Siempre descarga la última

```yaml
        ports:
        - name: http
          containerPort: 8080
```
- **containerPort**: Puerto que escucha Spring Boot

#### Variables de Entorno desde Secret:

```yaml
        env:
        - name: DB_URL
          valueFrom:
            secretKeyRef:
              name: jhon-silva-backend-secrets
              key: DB_URL
```
- **Qué hace**: Lee el secret y lo pasa como variable
- **Kubernetes decodifica**: Automáticamente de base64
- **El pod recibe**: El valor original (no base64)

#### Recursos:

```yaml
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

| Tipo | Memoria | CPU | Significado |
|------|---------|-----|-------------|
| **requests** | 256Mi | 250m | Mínimo garantizado |
| **limits** | 512Mi | 500m | Máximo permitido |

**250m CPU** = 0.25 cores = 25% de un core

#### Health Checks:

##### Liveness Probe:
```yaml
        livenessProbe:
          httpGet:
            path: /api/users
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
```
- **Qué hace**: Verifica si el pod está vivo
- **Si falla**: Kubernetes reinicia el pod
- **initialDelaySeconds**: Espera 60s antes de empezar
- **periodSeconds**: Chequea cada 10s

##### Readiness Probe:
```yaml
        readinessProbe:
          httpGet:
            path: /api/users
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
```
- **Qué hace**: Verifica si está listo para recibir tráfico
- **Si falla**: Quita el pod del Service (no recibe tráfico)
- **No reinicia**: Solo lo marca como "not ready"

### 📝 Comandos:

```bash
# Crear
kubectl apply -f jhon-silva-00-deployment-be.yml

# Ver deployment
kubectl get deployment jhon-silva-backend-deployment -n jhon-silva-backend

# Ver pods
kubectl get pods -n jhon-silva-backend

# Ver logs
kubectl logs -n jhon-silva-backend -l app=jhon-silva-backend

# Escalar
kubectl scale deployment jhon-silva-backend-deployment --replicas=3 -n jhon-silva-backend

# Ver historial de rollout
kubectl rollout history deployment jhon-silva-backend-deployment -n jhon-silva-backend

# Reiniciar
kubectl rollout restart deployment jhon-silva-backend-deployment -n jhon-silva-backend
```

---

## 🎯 ORDEN DE APLICACIÓN

```bash
# 1. Namespace primero
kubectl apply -f jhon-silva-00-namespace-be.yml

# 2. Secret (necesita namespace)
kubectl apply -f jhon-silva-00-secret-be.yml

# 3. Service (puede ir antes o después del deployment)
kubectl apply -f jhon-silva-00-service-be.yml

# 4. Deployment (usa secret y expone puerto del service)
kubectl apply -f jhon-silva-00-deployment-be.yml
```

O todos a la vez:
```bash
kubectl apply -f k8s/
```

---

## 📊 RELACIONES ENTRE ARCHIVOS

```
Namespace (jhon-silva-backend)
    ↓
Secret (jhon-silva-backend-secrets)
    ↓
Deployment (lee Secret)
    ↓
Pods (2 réplicas con env vars desde Secret)
    ↓
Service (selector encuentra Pods)
    ↓
LoadBalancer (MetalLB asigna IP: 172.19.255.200)
```

---

## 🎓 RESUMEN

| Archivo | Tipo | Para qué sirve |
|---------|------|----------------|
| **namespace** | Namespace | Aislamiento lógico |
| **secret** | Secret | Credenciales en base64 |
| **service** | Service | Exponer pods con LoadBalancer |
| **deployment** | Deployment | Crear y gestionar 2 pods |

**Todo conectado**: Namespace → Secret → Deployment → Pods → Service → LoadBalancer

¡Listo mano! Backend K8s completamente explicado. ☸️✨
