# ⚙️ METALLB-CONFIG.YAML - EXPLICACIÓN DETALLADA

## 📋 ¿Qué es MetalLB?

**MetalLB** es un **balanceador de carga** (LoadBalancer) para clusters Kubernetes que **no tienen** soporte nativo de LoadBalancer.

---

## 🚀 INSTALACIÓN DE METALLB - PASO A PASO

### Paso 1: Instalar MetalLB v0.14.3

```bash
# Descargar e instalar los manifests de MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
```

**Qué hace esto:**
- Crea el namespace `metallb-system`
- Instala el Controller (gestiona IPs)
- Instala el Speaker (anuncia IPs)
- Crea los CRDs (Custom Resource Definitions)

### Paso 2: Verificar la instalación

```bash
# Ver si los pods están corriendo
kubectl get pods -n metallb-system
```

**Salida esperada:**
```
NAME                          READY   STATUS    RESTARTS   AGE
controller-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
speaker-xxxxx                 1/1     Running   0          30s
```

**IMPORTANTE:** Espera hasta que ambos pods estén en estado `Running` antes de continuar.

### Paso 3: Esperar a que todo esté listo (opcional pero recomendado)

```bash
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s
```

### Paso 4: Aplicar la configuración (metallb-config.yaml)

```bash
# Aplicar el archivo de configuración
kubectl apply -f c:\Users\USER\Documents\JalatonJuC\metallb-config.yaml
```

**Qué hace esto:**
- Crea el `IPAddressPool` con el rango de IPs
- Crea el `L2Advertisement` para anunciar las IPs

### Paso 5: Verificar la configuración

```bash
# Ver el pool de IPs creado
kubectl get ipaddresspool -n metallb-system

# Ver el anuncio L2 creado
kubectl get l2advertisement -n metallb-system
```

**Salida esperada:**
```
NAME         AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
first-pool   true          false             ["172.19.255.200-172.19.255.250"]

NAME      IPADDRESSPOOLS   IPADDRESSPOOL SELECTORS   INTERFACES
example   ["first-pool"]
```

### ✅ ¡Listo! MetalLB está instalado y configurado

Ahora cuando crees un servicio de tipo `LoadBalancer`, MetalLB le asignará automáticamente una IP del rango `172.19.255.200-250`.

---

## 🤔 ¿CUÁNDO NECESITAS METALLB?

### Clusters SIN LoadBalancer nativo:
- ❌ Docker Desktop
- ❌ Minikube
- ❌ Kind
- ❌ Kubernetes on-premise (sin cloud provider)

### Clusters CON LoadBalancer nativo:
- ✅ AWS EKS (usa AWS ELB/ALB)
- ✅ GCP GKE (usa Google Cloud Load Balancer)
- ✅ Azure AKS (usa Azure Load Balancer)

---

## 📄 ARCHIVO: metallb-config.yaml

### Ubicación:
```
c:\Users\USER\Documents\JalatonJuC\metallb-config.yaml
```

### Contenido Completo:

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

---

## 🔍 EXPLICACIÓN LÍNEA POR LÍNEA

### 1️⃣ IPAddressPool (Pool de IPs)

```yaml
apiVersion: metallb.io/v1beta1
```
- **Qué es**: Versión de la API de MetalLB
- **Por qué**: Define qué formato usar para los recursos

```yaml
kind: IPAddressPool
```
- **Qué es**: Tipo de recurso (pool de direcciones IP)
- **Para qué**: Define un rango de IPs que MetalLB puede asignar

```yaml
metadata:
  name: first-pool
```
- **Qué es**: Nombre del pool
- **Puedes cambiar**: Sí, pero debe ser único

```yaml
  namespace: metallb-system
```
- **Qué es**: Namespace donde vive MetalLB
- **NO cambiar**: Siempre debe ser `metallb-system`

```yaml
spec:
  addresses:
  - 172.19.255.200-172.19.255.250
```
- **Qué es**: Rango de IPs disponibles para asignar
- **En este caso**: 51 IPs (desde .200 hasta .250)
- **Puedes cambiar**: Sí, pero debe estar en la red de Docker

---

### 2️⃣ L2Advertisement (Anuncio de Capa 2)

```yaml
---
```
- **Qué es**: Separador entre recursos YAML
- **Para qué**: Permite múltiples recursos en un archivo

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
```
- **Qué es**: Anuncio L2 (Layer 2)
- **Para qué**: Dice cómo MetalLB debe "anunciar" las IPs en la red

```yaml
metadata:
  name: example
```
- **Qué es**: Nombre del anuncio
- **Puedes cambiar**: Sí, es solo un nombre

```yaml
  namespace: metallb-system
```
- **Qué es**: Namespace de MetalLB
- **NO cambiar**: Debe ser `metallb-system`

```yaml
spec:
  ipAddressPools:
  - first-pool
```
- **Qué es**: Qué pool de IPs usar
- **Debe coincidir**: Con el nombre del IPAddressPool de arriba

---

## 🎯 ¿CÓMO FUNCIONA?

### Paso 1: Crear el pool de IPs
```
IPAddressPool "first-pool"
└── Rango: 172.19.255.200 - 172.19.255.250 (51 IPs disponibles)
```

### Paso 2: Anunciar las IPs (L2Advertisement)
```
L2Advertisement "example"
└── Usa el pool: first-pool
└── Protocolo: Layer 2 (ARP)
```

### Paso 3: Asignar IPs a servicios
```
Cuando creas un servicio LoadBalancer:
1. Kubernetes pide una IP externa
2. MetalLB toma una del pool (ej: 172.19.255.200)
3. La asigna al servicio
4. Anuncia la IP en la red usando ARP
```

---

## 📊 ASIGNACIÓN DE IPS EN TU PROYECTO

| Servicio | IP Asignada | Puerto |
|----------|-------------|--------|
| Backend | 172.19.255.200 | 8080 |
| Frontend | 172.19.255.201 | 80 |
| Disponibles | 172.19.255.202 - .250 | - |

---

## 🔧 COMANDOS RELACIONADOS

### Instalar MetalLB:
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
```

### Aplicar configuración:
```bash
kubectl apply -f c:\Users\USER\Documents\JalatonJuC\metallb-config.yaml
```

### Ver pools de IPs:
```bash
kubectl get ipaddresspool -n metallb-system
```

**Salida esperada:**
```
NAME         AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
first-pool   true          false             ["172.19.255.200-172.19.255.250"]
```

### Ver anuncios L2:
```bash
kubectl get l2advertisement -n metallb-system
```

**Salida esperada:**
```
NAME      IPADDRESSPOOLS   IPADDRESSPOOL SELECTORS   INTERFACES
example   ["first-pool"]
```

### Ver IPs asignadas:
```bash
kubectl get services --all-namespaces | findstr LoadBalancer
```

**Salida esperada:**
```
jhon-silva-backend     jhon-silva-backend-service     LoadBalancer   10.96.240.191   172.19.255.200   8080:30080/TCP
jhon-silva-frontend    jhon-silva-frontend-service    LoadBalancer   10.96.169.81    172.19.255.201   80:30200/TCP
```

---

## 🎨 PERSONALIZAR EL RANGO DE IPS

### Opción 1: Rango más pequeño (10 IPs)
```yaml
spec:
  addresses:
  - 172.19.255.200-172.19.255.210
```

### Opción 2: IPs específicas (no rango)
```yaml
spec:
  addresses:
  - 172.19.255.200/32
  - 172.19.255.201/32
  - 172.19.255.202/32
```

### Opción 3: Rango en otra subred
```yaml
spec:
  addresses:
  - 192.168.65.200-192.168.65.250
```

**⚠️ Importante**: El rango debe estar en la misma red que Docker Desktop.

### Ver la red de Docker:
```bash
docker network inspect bridge | findstr Subnet
```

---

## 🔍 TROUBLESHOOTING

### Problema: Las IPs no se asignan (quedan en <pending>)

**Solución 1**: Verificar que MetalLB esté corriendo
```bash
kubectl get pods -n metallb-system
```

Deberías ver:
```
NAME                          READY   STATUS    RESTARTS   AGE
controller-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
speaker-xxxxx                 1/1     Running   0          5m
```

**Solución 2**: Verificar los logs del controller
```bash
kubectl logs -n metallb-system -l app=metallb,component=controller
```

**Solución 3**: Reiniciar MetalLB
```bash
kubectl rollout restart deployment controller -n metallb-system
kubectl rollout restart daemonset speaker -n metallb-system
```

### Problema: Las IPs no son accesibles desde Windows

**Explicación**: En Docker Desktop, las IPs de MetalLB (172.19.x.x) solo funcionan **dentro del cluster**, no desde Windows.

**Solución**: Usar `kubectl port-forward` o el script `iniciar-servicios.bat`.

---

## 📚 MODOS DE METALLB

### 1. Layer 2 Mode (L2) - El que usamos
- **Cómo funciona**: Usa ARP (Address Resolution Protocol)
- **Ventaja**: Simple, no requiere configuración de red
- **Desventaja**: Solo un nodo responde (no load balancing real)
- **Ideal para**: Desarrollo local, pruebas

### 2. BGP Mode (Border Gateway Protocol)
- **Cómo funciona**: Usa BGP para anunciar rutas
- **Ventaja**: Load balancing real entre nodos
- **Desventaja**: Requiere configuración de routers
- **Ideal para**: Producción on-premise

**Para tu proyecto usamos L2 Mode porque es más simple y funciona en Docker Desktop.**

---

## 🎓 RESUMEN

### ¿Qué hace metallb-config.yaml?
1. Define un **pool de IPs** (172.19.255.200-250)
2. Configura **cómo anunciar** esas IPs (Layer 2)
3. Permite que servicios **LoadBalancer obtengan IPs externas**

### ¿Cuándo lo necesitas?
- ✅ En Docker Desktop, Minikube, Kind
- ❌ NO en AWS, GCP, Azure (ya tienen LoadBalancer)

### Comandos clave:
```bash
# Instalar MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

# Aplicar configuración
kubectl apply -f metallb-config.yaml

# Verificar
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system
kubectl get services --all-namespaces | findstr LoadBalancer
```

### En tu proyecto:
- Backend obtiene: `172.19.255.200`
- Frontend obtiene: `172.19.255.201`
- Ambos funcionan dentro de Kubernetes
- Para acceder desde Windows: Usar `iniciar-servicios.bat`

---

## 📁 ARCHIVO COMPLETO PARA REFERENCIA

```yaml
# Pool de direcciones IP que MetalLB puede asignar
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool                    # Nombre del pool
  namespace: metallb-system           # Namespace de MetalLB
spec:
  addresses:
  - 172.19.255.200-172.19.255.250    # Rango de 51 IPs

---

# Configuración de cómo anunciar las IPs (Layer 2)
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example                       # Nombre del anuncio
  namespace: metallb-system           # Namespace de MetalLB
spec:
  ipAddressPools:
  - first-pool                        # Usa el pool de arriba
```

¡Listo mano! MetalLB explicado completamente. 🔧✨
