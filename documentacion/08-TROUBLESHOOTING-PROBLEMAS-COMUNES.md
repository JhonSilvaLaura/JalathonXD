# 08 - TROUBLESHOOTING: Problemas Comunes y Soluciones

## 📋 Índice de Problemas

1. [Problemas con LoadBalancer](#1-problemas-con-loadbalancer)
2. [Problemas con Pods](#2-problemas-con-pods)
3. [Problemas de Conexión](#3-problemas-de-conexión)
4. [Problemas con Secrets](#4-problemas-con-secrets)
5. [Problemas con Docker](#5-problemas-con-docker)
6. [Problemas con la Base de Datos](#6-problemas-con-la-base-de-datos)

---

## 1. Problemas con LoadBalancer

### ❌ Problema: EXTERNAL-IP se queda en `<pending>`

```bash
NAME                         TYPE           EXTERNAL-IP   PORT(S)
jhon-silva-backend-service   LoadBalancer   <pending>     8080:30607/TCP
```

**Causa**: MetalLB no está instalado o configurado correctamente.

**Solución**:

```bash
# 1. Verificar si MetalLB está instalado
kubectl get pods -n metallb-system

# 2. Si no está instalado, instalarlo
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

# 3. Aplicar la configuración
kubectl apply -f metallb-config.yaml

# 4. Verificar que los pods estén corriendo
kubectl get pods -n metallb-system
```

---

### ❌ Problema: No puedo acceder a la IP externa (172.19.255.x) desde Windows

```bash
curl http://172.19.255.200:8080/api/users
# Error: Failed to connect to 172.19.255.200
```

**Causa**: En Docker Desktop para Windows, las IPs de LoadBalancer solo funcionan DENTRO del cluster, no son accesibles desde el host (Windows).

**Solución**: Usar port-forward o el script `iniciar-servicios.bat`

**Opción 1 - Script automático**:
```bash
# Ejecutar el script
.\iniciar-servicios.bat
```

**Opción 2 - Port-forward manual**:
```bash
# Terminal 1 - Backend
kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080

# Terminal 2 - Frontend
kubectl port-forward -n jhon-silva-frontend service/jhon-silva-frontend-service 4200:80
```

Luego acceder a:
- Backend: `http://localhost:8080/api/users`
- Frontend: `http://localhost:4200`

---

## 2. Problemas con Pods

### ❌ Problema: Pods en estado `CrashLoopBackOff`

```bash
NAME                                             READY   STATUS             RESTARTS
jhon-silva-backend-deployment-7895c494c7-rsn5d   0/1     CrashLoopBackOff   5
```

**Solución**:

```bash
# 1. Ver logs del pod
kubectl logs -n jhon-silva-backend jhon-silva-backend-deployment-7895c494c7-rsn5d

# 2. Ver detalles del pod
kubectl describe pod -n jhon-silva-backend jhon-silva-backend-deployment-7895c494c7-rsn5d

# 3. Verificar que los secrets estén correctos
kubectl get secret -n jhon-silva-backend jhon-silva-backend-secrets -o yaml

# 4. Verificar las variables de entorno del pod
kubectl exec -n jhon-silva-backend jhon-silva-backend-deployment-7895c494c7-rsn5d -- env
```

**Causas comunes**:
- Secrets mal configurados (base64 incorrecto)
- Credenciales de base de datos incorrectas
- Puerto ya en uso
- Imagen Docker no encontrada

---

### ❌ Problema: Pods en estado `ImagePullBackOff`

```bash
NAME                                             READY   STATUS             RESTARTS
jhon-silva-backend-deployment-7895c494c7-rsn5d   0/1     ImagePullBackOff   0
```

**Causa**: Kubernetes no puede descargar la imagen de Docker Hub.

**Solución**:

```bash
# 1. Verificar que la imagen existe en Docker Hub
# Visitar: https://hub.docker.com/r/jhonbrayansilvalaura/jhon-silva-be

# 2. Si la imagen es privada, crear secret para Docker
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=TU_USUARIO \
  --docker-password=TU_PASSWORD \
  -n jhon-silva-backend

# 3. Agregar imagePullSecrets al deployment
# En el archivo jhon-silva-00-deployment-be.yml:
spec:
  template:
    spec:
      imagePullSecrets:
      - name: dockerhub-secret
      containers:
      - name: backend
        image: jhonbrayansilvalaura/jhon-silva-be:1.0
```

---

### ❌ Problema: Pods en estado `Pending`

```bash
NAME                                             READY   STATUS    RESTARTS
jhon-silva-backend-deployment-7895c494c7-rsn5d   0/1     Pending   0
```

**Causa**: Recursos insuficientes en el cluster.

**Solución**:

```bash
# 1. Ver detalles del pod
kubectl describe pod -n jhon-silva-backend jhon-silva-backend-deployment-7895c494c7-rsn5d

# 2. Reducir los límites de recursos en el deployment
# Editar jhon-silva-00-deployment-be.yml:
resources:
  limits:
    memory: "256Mi"  # Reducir de 512Mi
    cpu: "250m"      # Reducir de 500m
  requests:
    memory: "128Mi"  # Reducir de 256Mi
    cpu: "100m"      # Reducir de 250m

# 3. Aplicar cambios
kubectl apply -f k8s/jhon-silva-00-deployment-be.yml
```

---

## 3. Problemas de Conexión

### ❌ Problema: Frontend no puede conectarse al Backend

**Síntoma**: En el navegador aparece error de conexión o CORS.

**Solución**:

```bash
# 1. Verificar que el backend esté corriendo
kubectl get pods -n jhon-silva-backend

# 2. Verificar que el servicio esté activo
kubectl get service -n jhon-silva-backend

# 3. Verificar la URL del backend en el secret del frontend
kubectl get secret -n jhon-silva-frontend jhon-silva-frontend-secrets -o yaml

# 4. Decodificar el secret para verificar
echo "aHR0cDovL2xvY2FsaG9zdDozMDA4MA==" | base64 -d
# Debe mostrar: http://localhost:30080

# 5. Si usas port-forward, el API_URL debe ser:
# http://localhost:8080

# 6. Si usas NodePort, el API_URL debe ser:
# http://localhost:30080
```

---

### ❌ Problema: Error CORS en el Frontend

**Síntoma**: Error en consola del navegador:
```
Access to XMLHttpRequest at 'http://...' has been blocked by CORS policy
```

**Solución**:

Verificar que el backend tenga configurado CORS. En `DemoApplication.java`:

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(Arrays.asList("*"));
    configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
    configuration.setAllowedHeaders(Arrays.asList("*"));
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
}
```

---

## 4. Problemas con Secrets

### ❌ Problema: Secrets no están hasheados correctamente

**Síntoma**: Pods fallan con error de autenticación en la base de datos.

**Solución**:

```bash
# 1. Hashear correctamente los valores
echo -n "npg_pHT4NJx3gnSG" | base64
# Resultado: bnBnX3BIVDROSngzZ25TRw==

# 2. Verificar que no haya espacios o saltos de línea
# ❌ MAL:
echo "npg_pHT4NJx3gnSG" | base64  # Incluye \n

# ✅ BIEN:
echo -n "npg_pHT4NJx3gnSG" | base64  # No incluye \n

# 3. En PowerShell:
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("npg_pHT4NJx3gnSG"))

# 4. Actualizar el secret
kubectl delete secret -n jhon-silva-backend jhon-silva-backend-secrets
kubectl apply -f k8s/jhon-silva-00-secret-be.yml

# 5. Reiniciar los pods
kubectl rollout restart deployment -n jhon-silva-backend jhon-silva-backend-deployment
```

---

### ❌ Problema: Secret no se aplica al pod

**Solución**:

```bash
# 1. Verificar que el secret existe
kubectl get secret -n jhon-silva-backend

# 2. Verificar que el deployment referencia el secret correcto
kubectl describe deployment -n jhon-silva-backend jhon-silva-backend-deployment

# 3. Reiniciar el deployment después de modificar el secret
kubectl rollout restart deployment -n jhon-silva-backend jhon-silva-backend-deployment
```

---

## 5. Problemas con Docker

### ❌ Problema: Error al construir la imagen Docker

**Síntoma**:
```bash
ERROR: failed to solve: failed to compute cache key
```

**Solución**:

```bash
# 1. Limpiar cache de Docker
docker builder prune -a

# 2. Reconstruir la imagen
cd demo
docker build -t jhonbrayansilvalaura/jhon-silva-be:1.0 .

# 3. Si persiste, verificar el Dockerfile
# Asegurar que todos los archivos existan (pom.xml, src/, etc.)
```

---

### ❌ Problema: Imagen muy grande (>300MB)

**Solución**:

```bash
# 1. Usar multi-stage build (ya implementado en los Dockerfiles)

# 2. Verificar el tamaño de la imagen
docker images | grep jhon-silva

# Backend debe ser ~100MB
# Frontend debe ser ~26MB

# 3. Si es más grande, optimizar el Dockerfile
```

---

## 6. Problemas con la Base de Datos

### ❌ Problema: No puede conectarse a Neon Database

**Síntoma**: Error en logs del pod:
```
io.r2dbc.postgresql.ExceptionFactory$PostgresqlConnectionException
```

**Solución**:

```bash
# 1. Verificar que las credenciales sean correctas
kubectl get secret -n jhon-silva-backend jhon-silva-backend-secrets -o yaml

# 2. Decodificar y verificar cada valor
echo "cjJkYmM6cG9zdGdyZXNxbDovL2VwLXJvdWdoLXZpb2xldC1hZGk2cmkway1wb29sZXIuYy0yLnVzLWVhc3QtMS5hd3MubmVvbi50ZWNoL2RlbW8/c3NsbW9kZT1yZXF1aXJl" | base64 -d

# 3. Verificar que la base de datos esté activa en Neon Console
# https://console.neon.tech/

# 4. Verificar el firewall de Neon
# Asegurar que permita conexiones desde cualquier IP (0.0.0.0/0)

# 5. Probar conexión manualmente
kubectl run -it --rm debug --image=postgres:15 --restart=Never -n jhon-silva-backend -- psql "postgresql://neondb_owner:npg_pHT4NJx3gnSG@ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require"
```

---

### ❌ Problema: Tabla `users` no existe

**Síntoma**: Error 404 o error en logs sobre tabla no encontrada.

**Solución**:

```bash
# 1. Verificar que schema.sql se ejecutó
# El archivo está en: src/main/resources/schema.sql

# 2. Conectarse a la base de datos
psql "postgresql://neondb_owner:npg_pHT4NJx3gnSG@ep-rough-violet-adi6ri0k-pooler.c-2.us-east-1.aws.neon.tech/demo?sslmode=require"

# 3. Ejecutar el schema manualmente
CREATE TABLE IF NOT EXISTS users (
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

# 4. Verificar que la tabla existe
\dt
```

---

## 📝 Comandos Útiles de Diagnóstico

### Ver todo el estado del cluster

```bash
# Ver todos los recursos
kubectl get all --all-namespaces

# Ver eventos recientes
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Ver pods que fallan
kubectl get pods --all-namespaces | grep -v Running
```

### Limpiar y reiniciar todo

```bash
# Eliminar todo del backend
kubectl delete namespace jhon-silva-backend

# Eliminar todo del frontend
kubectl delete namespace jhon-silva-frontend

# Volver a aplicar
cd demo
kubectl apply -f k8s/

cd ../demo-front
kubectl apply -f k8s/
```

### Reiniciar pods sin eliminar

```bash
# Backend
kubectl rollout restart deployment -n jhon-silva-backend jhon-silva-backend-deployment

# Frontend
kubectl rollout restart deployment -n jhon-silva-frontend jhon-silva-frontend-deployment
```

---

## 🆘 Checklist de Diagnóstico

Cuando algo no funcione, revisar en orden:

- [ ] ¿MetalLB está instalado y configurado?
- [ ] ¿Los pods están en estado `Running`?
- [ ] ¿Los services tienen EXTERNAL-IP asignada?
- [ ] ¿Los secrets están correctamente hasheados (base64)?
- [ ] ¿Las credenciales de la base de datos son correctas?
- [ ] ¿El port-forward está activo si intentas acceder desde Windows?
- [ ] ¿La base de datos Neon está activa y accesible?
- [ ] ¿El frontend tiene la URL correcta del backend?
- [ ] ¿Las imágenes Docker existen en Docker Hub?
- [ ] ¿Los logs de los pods muestran algún error?

---

## 📞 Obtener Ayuda

```bash
# Ver logs en tiempo real
kubectl logs -f -n jhon-silva-backend deployment/jhon-silva-backend-deployment

# Entrar al pod para debuggear
kubectl exec -it -n jhon-silva-backend POD_NAME -- /bin/sh

# Ver configuración completa del deployment
kubectl get deployment -n jhon-silva-backend jhon-silva-backend-deployment -o yaml

# Ver variables de entorno del pod
kubectl exec -n jhon-silva-backend POD_NAME -- env
```

---

**¡Estos son los problemas más comunes! Si encuentras otro problema, revisa los logs con `kubectl logs` y busca el error específico.**
