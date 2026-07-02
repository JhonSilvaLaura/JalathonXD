# 🔐 BASE64 Y SECRETS EN KUBERNETES

## 📋 ¿Qué es Base64?

Base64 es un método de **codificación** (NO cifrado) que convierte datos binarios o texto en una cadena de caracteres ASCII segura para transmitir.

### ⚠️ IMPORTANTE:
- **NO es cifrado**: Cualquiera puede decodificarlo
- **NO es seguro por sí solo**: Es solo para compatibilidad
- **Kubernetes lo requiere**: Los secrets DEBEN estar en base64

---

## 🔨 COMANDOS PARA HASHEAR (Convertir a Base64)

### En Windows (PowerShell):

```bash
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('tu-texto-aqui'))"
```

### Ejemplos prácticos:

#### 1. Convertir URL del backend:
```bash
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://localhost:8080'))"
```
**Resultado**: `aHR0cDovL2xvY2FsaG9zdDo4MDgw`

#### 2. Convertir credencial de base de datos:
```bash
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('neondb_owner'))"
```
**Resultado**: `bmVvbmRiX293bmVy`

#### 3. Convertir password:
```bash
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('npg_pHT4NJx3gnSG'))"
```
**Resultado**: `bnBnX3BIVDROSngzZ25TRw==`

#### 4. Convertir URL completa de Neon DB:
```bash
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require'))"
```
**Resultado**: `cjJkYmM6cG9zdGdyZXNxbDovL2VwLXJvdWdoLXZpb2xldC1hZGk2cmkway1wb29sZXIuYy0yLnVzLWVhc3QtMS5hd3MubmVvbi50ZWNoL2RlbW8/c3NsbW9kZT1yZXF1aXJl`

---

## 🔓 DECODIFICAR BASE64

### Para verificar que está correcto:

```bash
# Windows PowerShell
powershell -Command "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('aHR0cDovL2xvY2FsaG9zdDo4MDgw'))"
```
**Resultado**: `http://localhost:8080`

### Verificar secret en Kubernetes:

```bash
# Ver el secret completo
kubectl get secret jhon-silva-backend-secrets -n jhon-silva-backend -o yaml

# Decodificar un campo específico
kubectl get secret jhon-silva-backend-secrets -n jhon-silva-backend -o jsonpath='{.data.DB_USERNAME}' | powershell -Command "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((Get-Content)))"
```

---

## 📝 ESTRUCTURA DE UN SECRET EN KUBERNETES

### Secret del Backend:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jhon-silva-backend-secrets
  namespace: jhon-silva-backend
type: Opaque
data:
  DB_URL: cjJkYmM6cG9zdGdyZXNxbDovL2VwLXJvdWdoLXZpb2xldC1hZGk2cmkway1wb29sZXIuYy0yLnVzLWVhc3QtMS5hd3MubmVvbi50ZWNoL2RlbW8/c3NsbW9kZT1yZXF1aXJl
  DB_USERNAME: bmVvbmRiX293bmVy
  DB_PASSWORD: bnBnX3BIVDROSngzZ25TRw==
  SERVER_PORT: ODA4MA==
```

### Campos importantes:

| Campo | Descripción |
|-------|-------------|
| `apiVersion: v1` | Versión de la API de Kubernetes |
| `kind: Secret` | Tipo de recurso |
| `metadata.name` | Nombre único del secret |
| `metadata.namespace` | Namespace donde vive el secret |
| `type: Opaque` | Tipo de secret (genérico) |
| `data` | Datos en base64 (NO `stringData`) |

---

## 🔄 DIFERENCIA: `data` vs `stringData`

### `data` (Base64 manual):
```yaml
data:
  DB_USERNAME: bmVvbmRiX293bmVy  # Ya en base64
```

### `stringData` (Kubernetes lo convierte):
```yaml
stringData:
  DB_USERNAME: "neondb_owner"  # Kubernetes lo convierte a base64
```

**Para tu proyecto usamos `data` porque el profesor pidió que estuviera "hasheado" (en base64).**

---

## 🎯 VALORES USADOS EN EL PROYECTO

### Backend Secret (demo/k8s/jhon-silva-00-secret-be.yml):

| Clave | Valor Original | Base64 |
|-------|----------------|--------|
| DB_URL | `r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require` | `cjJkYmM6cG9zdGdyZXNxbDovL2VwLXJvdWdoLXZpb2xldC1hZGk2cmkway1wb29sZXIuYy0yLnVzLWVhc3QtMS5hd3MubmVvbi50ZWNoL2RlbW8/c3NsbW9kZT1yZXF1aXJl` |
| DB_USERNAME | `neondb_owner` | `bmVvbmRiX293bmVy` |
| DB_PASSWORD | `npg_pHT4NJx3gnSG` | `bnBnX3BIVDROSngzZ25TRw==` |
| SERVER_PORT | `8080` | `ODA4MA==` |

### Frontend Secret (demo-front/k8s/jhon-silva-00-secret-fe.yml):

| Clave | Valor Original | Base64 |
|-------|----------------|--------|
| API_URL | `http://localhost:30080` | `aHR0cDovL2xvY2FsaG9zdDozMDA4MA==` |

---

## 🔧 CÓMO LOS USA EL DEPLOYMENT

### En el Deployment del Backend:

```yaml
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
```

Kubernetes **automáticamente decodifica** el base64 y lo pasa como variable de entorno al contenedor.

---

## ✅ VERIFICACIÓN

### 1. Ver si el secret existe:
```bash
kubectl get secrets -n jhon-silva-backend
```

### 2. Ver el contenido (en base64):
```bash
kubectl get secret jhon-silva-backend-secrets -n jhon-silva-backend -o yaml
```

### 3. Decodificar un valor:
```bash
kubectl get secret jhon-silva-backend-secrets -n jhon-silva-backend -o jsonpath='{.data.DB_USERNAME}' | base64 -d
```

### 4. Ver desde un pod (ya decodificado):
```bash
kubectl exec -n jhon-silva-backend <pod-name> -- env | grep DB_
```

---

## 🎓 RESUMEN

### ¿Por qué Base64?
- Kubernetes lo requiere para secrets
- Permite caracteres especiales sin problemas
- Es estándar en la industria

### ¿Es seguro?
- NO es cifrado, solo codificación
- Para producción usa: AWS Secrets Manager, Vault, etc.
- En este proyecto es suficiente para la demo

### Comandos clave:
```bash
# Codificar (Windows)
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('texto'))"

# Decodificar (Windows)
powershell -Command "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('YmFzZTY0'))"

# Aplicar secret
kubectl apply -f jhon-silva-00-secret-be.yml

# Verificar
kubectl get secret <nombre> -n <namespace> -o yaml
```

---

## 📚 REFERENCIA RÁPIDA

### Todos los comandos usados:

```bash
# Backend DB_URL
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require'))"

# Backend DB_USERNAME
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('neondb_owner'))"

# Backend DB_PASSWORD
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('npg_pHT4NJx3gnSG'))"

# Backend SERVER_PORT
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('8080'))"

# Frontend API_URL (localhost con NodePort)
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://localhost:30080'))"

# Frontend API_URL alternativo (localhost con port-forward)
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://localhost:8080'))"
```

¡Listo mano! Este es el primer documento completo sobre Base64 y Secrets. 🔐✨
