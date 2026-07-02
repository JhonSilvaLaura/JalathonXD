# 🔐 GUÍA: Hashear Secrets en Base64 para Kubernetes

## 📋 ¿Qué es Base64?

Base64 es un sistema de **codificación** (NO encriptación) que convierte texto plano en una cadena de caracteres seguros para transmitir por red.

### ⚠️ Importante:
- **Base64 NO es seguro**: Cualquiera puede decodificarlo
- Se usa en Kubernetes para evitar problemas con caracteres especiales
- Para seguridad real, usar herramientas como Vault, Sealed Secrets, etc.

---

## 🔧 COMANDOS PARA HASHEAR (Convertir a Base64)

### En Windows (PowerShell):

```powershell
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('tu-texto-aqui'))"
```

### En Linux/Mac:

```bash
echo -n "tu-texto-aqui" | base64
```

---

## 📝 EJEMPLOS USADOS EN ESTE PROYECTO

### 1. Backend - Database URL

**Texto original**:
```
r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require
```

**Comando**:
```powershell
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require'))"
```

**Resultado en Base64**:
```
cjJkYmM6cG9zdGdyZXNxbDovL2VwLXJvdWdoLXZpb2xldC1hZGk2cmkway1wb29sZXIuYy0yLnVzLWVhc3QtMS5hd3MubmVvbi50ZWNoL2RlbW8/c3NsbW9kZT1yZXF1aXJl
```

---

### 2. Backend - Database Username

**Texto original**:
```
neondb_owner
```

**Comando**:
```powershell
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('neondb_owner'))"
```

**Resultado en Base64**:
```
bmVvbmRiX293bmVy
```

---

### 3. Backend - Database Password

**Texto original**:
```
npg_pHT4NJx3gnSG
```

**Comando**:
```powershell
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('npg_pHT4NJx3gnSG'))"
```

**Resultado en Base64**:
```
bnBnX3BIVDROSngzZ25TRw==
```

---

### 4. Backend - Server Port

**Texto original**:
```
8080
```

**Comando**:
```powershell
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('8080'))"
```

**Resultado en Base64**:
```
ODA4MA==
```

---

### 5. Frontend - API URL (con IP de LoadBalancer)

**Texto original**:
```
http://172.19.255.200:8080
```

**Comando**:
```powershell
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://172.19.255.200:8080'))"
```

**Resultado en Base64**:
```
aHR0cDovLzE3Mi4xOS4yNTUuMjAwOjgwODA=
```

---

### 6. Frontend - API URL (con localhost para port-forward)

**Texto original**:
```
http://localhost:30080
```

**Comando**:
```powershell
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://localhost:30080'))"
```

**Resultado en Base64**:
```
aHR0cDovL2xvY2FsaG9zdDozMDA4MA==
```

---

## 🔓 DECODIFICAR BASE64 (Ver el valor original)

### En Windows (PowerShell):

```powershell
powershell -Command "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('aHR0cDovL2xvY2FsaG9zdDozMDA4MA=='))"
```

### En Linux/Mac:

```bash
echo "aHR0cDovL2xvY2FsaG9zdDozMDA4MA==" | base64 -d
```

### Con kubectl:

```bash
# Ver el secret completo
kubectl get secret jhon-silva-backend-secrets -n jhon-silva-backend -o yaml

# Decodificar un campo específico
kubectl get secret jhon-silva-backend-secrets -n jhon-silva-backend -o jsonpath='{.data.DB_USERNAME}' | base64 -d
```

---

## 📊 RESUMEN DE TODOS LOS VALORES

### Backend Secret (`jhon-silva-00-secret-be.yml`)

| Campo | Valor Original | Valor en Base64 |
|-------|---------------|----------------|
| `DB_URL` | `r2dbc:postgresql://ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require` | `cjJkYmM6cG9zdGdyZXNxbDovL2VwLXJvdWdoLXZpb2xldC1hZGk2cmkway1wb29sZXIuYy0yLnVzLWVhc3QtMS5hd3MubmVvbi50ZWNoL2RlbW8/c3NsbW9kZT1yZXF1aXJl` |
| `DB_USERNAME` | `neondb_owner` | `bmVvbmRiX293bmVy` |
| `DB_PASSWORD` | `npg_pHT4NJx3gnSG` | `bnBnX3BIVDROSngzZ25TRw==` |
| `SERVER_PORT` | `8080` | `ODA4MA==` |

### Frontend Secret (`jhon-silva-00-secret-fe.yml`)

| Campo | Valor Original | Valor en Base64 |
|-------|---------------|----------------|
| `API_URL` | `http://localhost:30080` | `aHR0cDovL2xvY2FsaG9zdDozMDA4MA==` |

---

## 🎯 ¿CUÁNDO HASHEAR?

### ✅ Siempre hashear:

1. **Credenciales de base de datos**
2. **Contraseñas**
3. **Tokens de API**
4. **Certificados**
5. **URLs con parámetros especiales**
6. **Cualquier valor en un Secret de Kubernetes**

### ❌ NO hashear:

1. **ConfigMaps** (valores de configuración públicos)
2. **Labels y Annotations**
3. **Nombres de recursos**
4. **Puertos y números**

---

## 🔧 HERRAMIENTA ÚTIL

### Crear un script para hashear rápido:

**`hashear.bat`** (Windows):
```batch
@echo off
echo Ingresa el texto a hashear:
set /p texto=
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('%texto%'))"
pause
```

**`hashear.sh`** (Linux/Mac):
```bash
#!/bin/bash
echo "Ingresa el texto a hashear:"
read texto
echo -n "$texto" | base64
```

---

## 📝 BUENAS PRÁCTICAS

### ✅ Hacer:

1. **Usar Secrets para datos sensibles**, no ConfigMaps
2. **Documentar qué valor representa** cada campo (en comentarios)
3. **Rotar secrets regularmente** en producción
4. **Usar herramientas de gestión** como Vault en producción
5. **Limitar acceso RBAC** a los Secrets

### ❌ Evitar:

1. **Commitear secrets en git** (incluso en base64)
2. **Loggear valores de secrets**
3. **Exponer secrets en variables de entorno** visibles
4. **Usar base64 como única capa de seguridad**

---

## 🎓 CONCEPTOS CLAVE

### Base64 vs Encriptación

| Característica | Base64 | Encriptación |
|----------------|--------|--------------|
| **Reversible** | ✅ Sí (fácil) | ✅ Sí (con clave) |
| **Seguridad** | ❌ Ninguna | ✅ Alta |
| **Propósito** | Codificar datos | Proteger datos |
| **Ejemplo** | `echo "hola" \| base64` | AES, RSA |

### ⚠️ Conclusión:

**Base64 NO es seguridad**, solo es una **codificación** para que Kubernetes pueda manejar los datos sin problemas de caracteres especiales.

---

## 🔗 REFERENCIAS

- [Kubernetes Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Base64 Encoding](https://en.wikipedia.org/wiki/Base64)
- [Sealed Secrets (Alternativa segura)](https://github.com/bitnami-labs/sealed-secrets)
- [HashiCorp Vault](https://www.vaultproject.io/)

---

## ✅ CHECKLIST

- [x] Entender que base64 NO es encriptación
- [x] Saber convertir texto a base64
- [x] Saber decodificar base64
- [x] Aplicar base64 a todos los secrets
- [x] Documentar valores originales (fuera de git)
- [x] Usar herramientas seguras en producción

---

**¡Base64 es solo el PRIMER paso de seguridad en Kubernetes!** 🔐✨
