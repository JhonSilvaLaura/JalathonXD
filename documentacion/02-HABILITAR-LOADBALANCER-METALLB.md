# ⚖️ GUÍA: Habilitar LoadBalancer con MetalLB en Docker Desktop

## 📋 ¿Qué es MetalLB?

**MetalLB** es un **balanceador de carga de red** para clusters Kubernetes que no tienen soporte nativo de LoadBalancer (como Docker Desktop, Minikube, o Kind).

### 🎯 Problema que resuelve:

En clouds como AWS, GCP, o Azure, cuando creas un servicio tipo `LoadBalancer`, automáticamente te asignan una IP pública.

En **Docker Desktop**, cuando creas un LoadBalancer, queda en estado `<pending>` porque no hay un proveedor de IPs.

**MetalLB soluciona esto** asignando IPs de un pool que tú defines.

---

## 🚀 PASO 1: Instalar MetalLB

### Comando de instalación:

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
```

### ¿Qué hace este comando?

1. **Crea el namespace** `metallb-system`
2. **Instala CRDs** (Custom Resource Definitions):
   - `IPAddressPool` - Define rangos de IPs
   - `L2Advertisement` - Anuncia IPs en la red local
   - `BGPPeer`, `BGPAdvertisement` - Para configuración avanzada
3. **Despliega componentes**:
   - **Controller**: Asigna IPs a los servicios
   - **Speaker** (DaemonSet): Anuncia las IPs en la red

---

### Esperar a que MetalLB esté listo:

```bash
kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s
```

### Verificar pods:

```bash
kubectl get pods -n metallb-system
```

**Deberías ver**:
```
NAME                          READY   STATUS    RESTARTS   AGE
controller-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
speaker-xxxxx                 1/1     Running   0          1m
speaker-xxxxx                 1/1     Running   0          1m
...
```

- **Controller**: 1 pod (asigna IPs)
- **Speaker**: N pods (uno por nodo, anuncia IPs)

---

## 🚀 PASO 2: Configurar Pool de IPs

MetalLB necesita saber **qué IPs puede asignar**. Esto se define en un `IPAddressPool`.

### Archivo: `metallb-config.yaml`

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

### 📝 Explicación línea por línea:

#### **IPAddressPool**:

```yaml
apiVersion: metallb.io/v1beta1  # API version de MetalLB
kind: IPAddressPool              # Tipo de recurso: pool de IPs
metadata:
  name: first-pool               # Nombre del pool
  namespace: metallb-system      # Debe estar en metallb-system
spec:
  addresses:
  - 172.19.255.200-172.19.255.250  # Rango de 51 IPs disponibles
```

**¿De dónde salen estas IPs?**

- Docker Desktop usa la red `172.19.0.0/16` por defecto
- Elegimos un rango alto (`255.200-250`) para evitar conflictos
- Puedes usar otro rango si prefieres

**¿Cómo elegir el rango?**

```bash
# Ver la red de Docker
docker network inspect bridge

# Busca "Subnet": "172.19.0.0/16"
# Elige IPs dentro de ese rango
```

---

#### **L2Advertisement**:

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement           # Tipo: anuncio de capa 2 (ARP)
metadata:
  name: example                 # Nombre del anuncio
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool                  # Pool que se anuncia
```

**¿Qué hace L2Advertisement?**

- Usa **ARP** (Address Resolution Protocol) para anunciar las IPs
- Responde a peticiones ARP diciendo "la IP X está aquí"
- Funciona en redes locales (Layer 2)

**Alternativa: BGP** (para redes complejas):
- Si tu red soporta BGP, puedes usar `BGPAdvertisement`
- Para Docker Desktop, L2 es suficiente

---

### Aplicar la configuración:

```bash
kubectl apply -f metallb-config.yaml
```

### Verificar que se creó:

```bash
# Ver el pool
kubectl get ipaddresspool -n metallb-system

# Ver el advertisement
kubectl get l2advertisement -n metallb-system
```

**Salida esperada**:
```
NAME         AGE
first-pool   10s

NAME      AGE
example   10s
```

---

## 🚀 PASO 3: Verificar que Funciona

### Antes de MetalLB:

```bash
kubectl get service jhon-silva-backend-service -n jhon-silva-backend
```

**Salida**:
```
NAME                         TYPE           EXTERNAL-IP   PORT(S)
jhon-silva-backend-service   LoadBalancer   <pending>     8080:30607/TCP
```

### Después de MetalLB:

```bash
kubectl get service jhon-silva-backend-service -n jhon-silva-backend
```

**Salida**:
```
NAME                         TYPE           EXTERNAL-IP      PORT(S)
jhon-silva-backend-service   LoadBalancer   172.19.255.200   8080:30607/TCP
```

✅ **¡Ahora tiene IP externa!**

---

## 🔍 ¿CÓMO FUNCIONA METALLB?

### Flujo de asignación de IP:

```
1. Usuario crea servicio LoadBalancer
   └─> kubectl apply -f service.yml

2. Kubernetes marca el servicio como LoadBalancer
   └─> EXTERNAL-IP: <pending>

3. MetalLB Controller detecta el servicio nuevo
   └─> "Necesito asignar una IP"

4. MetalLB consulta el IPAddressPool
   └─> "Tengo IPs disponibles: 172.19.255.200-250"

5. MetalLB asigna la primera IP libre
   └─> 172.19.255.200

6. MetalLB actualiza el servicio
   └─> EXTERNAL-IP: 172.19.255.200

7. MetalLB Speaker anuncia la IP en la red
   └─> ARP: "172.19.255.200 está en este nodo"

8. Tráfico llega a la IP
   └─> MetalLB redirige al servicio
   └─> Kubernetes redirige a los pods
```

---

## 📊 COMPONENTES DE METALLB

### 1. Controller (Deployment)

**Función**:
- Monitorea servicios LoadBalancer
- Asigna IPs del pool
- Actualiza el campo `status.loadBalancer.ingress`

**Ubicación**:
```bash
kubectl get deployment -n metallb-system
```

**Ver logs**:
```bash
kubectl logs -n metallb-system -l app=metallb,component=controller
```

---

### 2. Speaker (DaemonSet)

**Función**:
- Corre en **cada nodo** del cluster
- Anuncia las IPs en la red (ARP/BGP)
- Responde a peticiones de red

**Ubicación**:
```bash
kubectl get daemonset -n metallb-system
```

**Ver logs**:
```bash
kubectl logs -n metallb-system -l app=metallb,component=speaker
```

---

## ⚙️ CONFIGURACIONES AVANZADAS

### Múltiples Pools:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool-backend
  namespace: metallb-system
spec:
  addresses:
  - 172.19.255.200-172.19.255.220
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool-frontend
  namespace: metallb-system
spec:
  addresses:
  - 172.19.255.221-172.19.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: backend-ad
  namespace: metallb-system
spec:
  ipAddressPools:
  - pool-backend
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: frontend-ad
  namespace: metallb-system
spec:
  ipAddressPools:
  - pool-frontend
```

### Seleccionar pool específico:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    metallb.universe.tf/address-pool: pool-backend
spec:
  type: LoadBalancer
  ...
```

---

## 🐛 TROUBLESHOOTING

### Problema: IP asignada pero no accesible

**Causa**: En Docker Desktop, las IPs de MetalLB solo son accesibles desde dentro del cluster.

**Solución**: Usar `kubectl port-forward` o acceder desde otro pod.

```bash
kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080
```

---

### Problema: IP no se asigna (<pending>)

**Diagnóstico**:

```bash
# Ver eventos del servicio
kubectl describe service jhon-silva-backend-service -n jhon-silva-backend

# Ver logs del controller
kubectl logs -n metallb-system -l component=controller

# Verificar que el pool existe
kubectl get ipaddresspool -n metallb-system
```

**Soluciones**:

1. **Pool no configurado**:
   ```bash
   kubectl apply -f metallb-config.yaml
   ```

2. **Pool sin IPs disponibles**:
   - Amplía el rango en `metallb-config.yaml`
   - O elimina servicios que no uses

3. **MetalLB no está corriendo**:
   ```bash
   kubectl get pods -n metallb-system
   ```

---

### Problema: Speaker en CrashLoopBackOff

**Causa común**: Problemas de red o permisos.

**Solución**:

```bash
# Ver logs del speaker
kubectl logs -n metallb-system -l component=speaker

# Reiniciar speaker
kubectl rollout restart daemonset speaker -n metallb-system
```

---

## 📝 COMPARACIÓN: CON Y SIN METALLB

### Sin MetalLB:

| Aspecto | Resultado |
|---------|-----------|
| Crear servicio LoadBalancer | ✅ Se crea |
| EXTERNAL-IP | ❌ `<pending>` |
| Acceso desde fuera | ❌ No funciona |
| Solución | Port-forward manual |

### Con MetalLB:

| Aspecto | Resultado |
|---------|-----------|
| Crear servicio LoadBalancer | ✅ Se crea |
| EXTERNAL-IP | ✅ IP asignada |
| Acceso desde cluster | ✅ Funciona |
| Acceso desde fuera (Docker Desktop) | ⚠️ Requiere port-forward |

---

## 🎯 CASOS DE USO

### ✅ Cuándo usar MetalLB:

1. **Desarrollo local** (Docker Desktop, Minikube, Kind)
2. **Bare metal clusters** (servidores físicos sin cloud)
3. **On-premise Kubernetes**
4. **Pruebas de LoadBalancer** antes de desplegar a cloud

### ❌ Cuándo NO usar MetalLB:

1. **AWS EKS**: Usa ELB nativo
2. **GCP GKE**: Usa Google Cloud Load Balancer
3. **Azure AKS**: Usa Azure Load Balancer
4. **Clusters con LoadBalancer nativo**

---

## 📚 RECURSOS

- [MetalLB Official Docs](https://metallb.universe.tf/)
- [MetalLB Configuration](https://metallb.universe.tf/configuration/)
- [MetalLB GitHub](https://github.com/metallb/metallb)

---

## ✅ CHECKLIST

- [x] MetalLB instalado
- [x] Controller corriendo
- [x] Speaker corriendo en todos los nodos
- [x] IPAddressPool configurado
- [x] L2Advertisement configurado
- [x] Servicios LoadBalancer obtienen IP
- [x] Entender limitaciones en Docker Desktop

---

**¡MetalLB convierte tu cluster local en uno con LoadBalancer!** ⚖️✨
