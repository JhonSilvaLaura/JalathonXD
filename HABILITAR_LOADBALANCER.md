# 🔧 Habilitar LoadBalancer en Docker Desktop con MetalLB

## 📋 ¿Qué es MetalLB?

MetalLB es un balanceador de carga para clusters Kubernetes que no tienen soporte nativo de LoadBalancer (como Docker Desktop, Minikube, Kind).

---

## 🚀 PASO 1: Instalar MetalLB

### 1.1 Aplicar manifiestos de MetalLB

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
```

### 1.2 Esperar a que MetalLB esté listo

```bash
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s
```

---

## 🚀 PASO 2: Configurar rango de IPs

Necesitamos darle a MetalLB un rango de IPs para asignar a los LoadBalancers.

### 2.1 Crear archivo de configuración

Crea el archivo: `c:\Users\USER\Documents\JalatonJuC\metallb-config.yaml`

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.19.255.200-172.19.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
```

### 2.2 Aplicar configuración

```bash
kubectl apply -f c:\Users\USER\Documents\JalatonJuC\metallb-config.yaml
```

---

## 🚀 PASO 3: Verificar que funciona

### 3.1 Ver estado de MetalLB

```bash
kubectl get pods -n metallb-system
```

Deberías ver pods corriendo:
```
NAME                          READY   STATUS    RESTARTS   AGE
controller-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
speaker-xxxxx                 1/1     Running   0          1m
```

### 3.2 Verificar configuración

```bash
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
```

---

## 🚀 PASO 4: Verificar servicios backend

Ahora tu servicio debería obtener una IP externa:

```bash
kubectl get service jhon-silva-backend-service -n jhon-silva-backend
```

**Antes** (con MetalLB):
```
EXTERNAL-IP
<pending>
```

**Después** (con MetalLB funcionando):
```
EXTERNAL-IP
172.19.255.200
```

⏱️ Puede tardar 1-2 minutos en asignar la IP.

---

## 🚀 PASO 5: Obtener IPs y continuar deployment

### Backend

```bash
kubectl get service jhon-silva-backend-service -n jhon-silva-backend
```

Copia la **EXTERNAL-IP** (ej: `172.19.255.200`)

### Probar backend

```bash
curl http://172.19.255.200:8080/api/users
```

### Convertir URL del backend a base64 para el frontend

```bash
# Reemplaza <IP> con la IP que obtuviste
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://172.19.255.200:8080'))"
```

---

## 🚀 PASO 6: Desplegar Frontend

### 6.1 Actualizar secret del frontend

Edita: `c:\Users\USER\Documents\JalatonJuC\demo-front\k8s\jhon-silva-00-secret-fe.yml`

Cambia:
```yaml
API_URL: aHR0cDovLzxFWFRFUk5BTC1JUC1CQUNLRU5EPjo4MDgw
```

Por el base64 que generaste en el paso anterior.

### 6.2 Aplicar manifiestos del frontend

```bash
cd c:\Users\USER\Documents\JalatonJuC\demo-front
kubectl apply -f k8s/jhon-silva-00-namespace-fe.yml
kubectl apply -f k8s/jhon-silva-00-secret-fe.yml
kubectl apply -f k8s/jhon-silva-00-service-fe.yml
kubectl apply -f k8s/jhon-silva-00-deployment-fe.yml
```

### 6.3 Obtener IP del frontend

```bash
kubectl get service jhon-silva-frontend-service -n jhon-silva-frontend
```

Copia la **EXTERNAL-IP** (ej: `172.19.255.201`)

### 6.4 Abrir en navegador

```
http://172.19.255.201
```

---

## ✅ VERIFICACIÓN FINAL

### Ver todos los servicios con IPs externas

```bash
kubectl get services --all-namespaces | grep LoadBalancer
```

Deberías ver:
```
jhon-silva-backend     jhon-silva-backend-service     LoadBalancer   10.x.x.x   172.19.255.200   8080:xxxxx/TCP
jhon-silva-frontend    jhon-silva-frontend-service    LoadBalancer   10.x.x.x   172.19.255.201   80:xxxxx/TCP
```

---

## 🔧 TROUBLESHOOTING

### Si MetalLB no asigna IPs

1. **Verificar rango de IPs**:
   - El rango debe estar en la misma red de Docker Desktop
   - Por defecto Docker Desktop usa `172.x.x.x`

2. **Ver logs de MetalLB**:
```bash
kubectl logs -n metallb-system -l app=metallb
```

3. **Reiniciar MetalLB**:
```bash
kubectl rollout restart deployment controller -n metallb-system
kubectl rollout restart daemonset speaker -n metallb-system
```

### Cambiar rango de IPs si no funciona

Si `172.19.255.x` no funciona, prueba con:
```yaml
addresses:
- 192.168.65.200-192.168.65.250
```

O verifica tu red de Docker con:
```bash
docker network inspect bridge
```

---

## 📝 RESUMEN DE COMANDOS COMPLETOS

```bash
# 1. Instalar MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s

# 2. Aplicar configuración (después de crear el archivo)
kubectl apply -f c:\Users\USER\Documents\JalatonJuC\metallb-config.yaml

# 3. Verificar backend obtiene IP
kubectl get service jhon-silva-backend-service -n jhon-silva-backend

# 4. Probar backend
curl http://<IP-BACKEND>:8080/api/users

# 5. Convertir URL a base64
powershell -Command "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('http://<IP-BACKEND>:8080'))"

# 6. Editar secret frontend con el base64 generado
# 7. Desplegar frontend
cd c:\Users\USER\Documents\JalatonJuC\demo-front
kubectl apply -f k8s/

# 8. Obtener IP del frontend
kubectl get service jhon-silva-frontend-service -n jhon-silva-frontend

# 9. Abrir navegador
# http://<IP-FRONTEND>
```

---

## 🎉 ¡LISTO!

Con MetalLB instalado, tus servicios LoadBalancer obtendrán IPs externas reales y funcionará como en un cluster de producción! 🚀✨
