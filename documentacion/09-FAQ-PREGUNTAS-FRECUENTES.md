# 09 - FAQ: Preguntas Frecuentes

## 📚 Índice

1. [Preguntas sobre Kubernetes](#preguntas-sobre-kubernetes)
2. [Preguntas sobre LoadBalancer y MetalLB](#preguntas-sobre-loadbalancer-y-metallb)
3. [Preguntas sobre Docker](#preguntas-sobre-docker)
4. [Preguntas sobre Base64 y Secrets](#preguntas-sobre-base64-y-secrets)
5. [Preguntas sobre Base de Datos](#preguntas-sobre-base-de-datos)
6. [Preguntas sobre el Proyecto](#preguntas-sobre-el-proyecto)

---

## Preguntas sobre Kubernetes

### ❓ ¿Por qué necesito 4 archivos YAML por proyecto?

**Respuesta**: Cada archivo tiene una función específica en Kubernetes:

1. **Namespace** (`jhon-silva-00-namespace-be.yml`): Crea un espacio aislado para organizar los recursos
2. **Secret** (`jhon-silva-00-secret-be.yml`): Almacena credenciales sensibles de forma segura (hasheadas en base64)
3. **Service** (`jhon-silva-00-service-be.yml`): Expone la aplicación y le asigna una IP externa (LoadBalancer)
4. **Deployment** (`jhon-silva-00-deployment-be.yml`): Define cómo se despliegan los pods (replicas, imagen, recursos)

---

### ❓ ¿Qué son los namespaces y para qué sirven?

**Respuesta**: Los namespaces son como "carpetas virtuales" dentro de Kubernetes. Sirven para:

- **Organizar recursos**: Backend separado del frontend
- **Aislar aplicaciones**: Evitar conflictos de nombres
- **Gestionar permisos**: Controlar quién accede a qué
- **Separar ambientes**: Desarrollo, staging, producción

**Ejemplo**:
```bash
# Backend en su namespace
jhon-silva-backend
  ├── Pods
  ├── Services
  └── Secrets

# Frontend en su namespace
jhon-silva-frontend
  ├── Pods
  ├── Services
  └── Secrets
```

---

### ❓ ¿Cuál es la diferencia entre Deployment y Pod?

**Respuesta**:

- **Pod**: Es la unidad mínima en Kubernetes. Contiene uno o más contenedores. Si un pod muere, no se reinicia automáticamente.

- **Deployment**: Es un controlador que gestiona pods. Define cuántas réplicas quieres, qué imagen usar, y reinicia automáticamente los pods si fallan.

**Analogía**:
- Pod = Un empleado individual
- Deployment = El departamento de RRHH que contrata y reemplaza empleados

```yaml
# Deployment crea y gestiona múltiples Pods
Deployment (jhon-silva-backend-deployment)
  ├── Pod 1 (replica 1)
  └── Pod 2 (replica 2)
```

---

### ❓ ¿Qué son las réplicas y por qué tengo 2?

**Respuesta**: Las réplicas son copias idénticas de tu aplicación corriendo al mismo tiempo.

**Ventajas**:
- **Alta disponibilidad**: Si un pod falla, el otro sigue funcionando
- **Balanceo de carga**: Las peticiones se distribuyen entre los 2 pods
- **Cero downtime**: Puedes actualizar un pod mientras el otro responde

**Configuración**:
```yaml
spec:
  replicas: 2  # 2 copias de la aplicación corriendo
```

---

### ❓ ¿Qué diferencia hay entre ClusterIP, NodePort y LoadBalancer?

**Respuesta**:

| Tipo | Acceso | Cuándo usarlo |
|------|--------|---------------|
| **ClusterIP** | Solo dentro del cluster | Comunicación entre servicios internos |
| **NodePort** | Puerto en cada nodo (30000-32767) | Desarrollo local, acceso directo |
| **LoadBalancer** | IP externa + balanceador | Producción, acceso desde internet |

**En este proyecto**:
- Usamos **LoadBalancer** para tener IPs externas profesionales
- También configuramos **NodePort** como backup (30080, 30200)

---

### ❓ ¿Puedo cambiar el número de réplicas después de desplegar?

**Respuesta**: ¡Sí! Tienes 3 opciones:

**Opción 1 - Editar el archivo y reaplicar**:
```bash
# Editar jhon-silva-00-deployment-be.yml
spec:
  replicas: 3  # Cambiar de 2 a 3

# Aplicar cambios
kubectl apply -f k8s/jhon-silva-00-deployment-be.yml
```

**Opción 2 - Comando directo**:
```bash
kubectl scale deployment jhon-silva-backend-deployment -n jhon-silva-backend --replicas=3
```

**Opción 3 - Autoescalado**:
```bash
kubectl autoscale deployment jhon-silva-backend-deployment -n jhon-silva-backend --min=2 --max=5 --cpu-percent=80
```

---

## Preguntas sobre LoadBalancer y MetalLB

### ❓ ¿Qué es un LoadBalancer y para qué sirve?

**Respuesta**: Un LoadBalancer es un servicio que:

1. **Asigna una IP externa** a tu aplicación
2. **Distribuye el tráfico** entre múltiples pods (réplicas)
3. **Detecta fallos** y deja de enviar tráfico a pods caídos
4. **Facilita el acceso** sin necesidad de conocer IPs de pods

**Analogía**: Es como el recepcionista de un hotel que distribuye a los clientes entre diferentes habitaciones disponibles.

---

### ❓ ¿Por qué necesito MetalLB?

**Respuesta**: En Kubernetes:

- **En la nube (AWS, GCP, Azure)**: Los LoadBalancer funcionan automáticamente porque los proveedores los implementan
- **En local (Docker Desktop, Minikube)**: No hay LoadBalancer nativo, por eso necesitas MetalLB

**MetalLB** es un LoadBalancer software que simula el comportamiento de los LoadBalancers de la nube, pero en tu máquina local.

---

### ❓ ¿Qué hace el archivo metallb-config.yaml?

**Respuesta**: Configura 2 cosas:

1. **IPAddressPool**: Define el rango de IPs que MetalLB puede asignar
```yaml
addresses:
- 172.19.255.200-172.19.255.250  # 51 IPs disponibles
```

2. **L2Advertisement**: Anuncia estas IPs en la red local usando el protocolo Layer 2

**Resultado**:
- Backend recibe: `172.19.255.200`
- Frontend recibe: `172.19.255.201`
- Quedan 49 IPs disponibles para otros servicios

---

### ❓ ¿Por qué no puedo acceder a 172.19.255.200 desde mi navegador?

**Respuesta**: **Docker Desktop en Windows tiene una limitación**: Las IPs de LoadBalancer solo funcionan **dentro del cluster**, no son accesibles desde el host (Windows).

**Soluciones**:

1. **Usar port-forward** (recomendado):
```bash
kubectl port-forward -n jhon-silva-backend service/jhon-silva-backend-service 8080:8080
# Acceder a: http://localhost:8080
```

2. **Usar el script automático**:
```bash
.\iniciar-servicios.bat
```

3. **Usar NodePort**:
```bash
# Acceder directamente al puerto del nodo
http://localhost:30080/api/users
```

---

### ❓ ¿Entonces para qué sirve el LoadBalancer si no puedo acceder desde Windows?

**Respuesta**: 

1. **Funcionalidad real**: En producción (cloud), el LoadBalancer SÍ es accesible desde internet
2. **Práctica profesional**: Aprendes a configurar LoadBalancers como en un entorno real
3. **Comunicación interna**: Los servicios dentro del cluster SÍ pueden usar las IPs del LoadBalancer
4. **Portabilidad**: El mismo código funciona en local (con port-forward) y en cloud (directo)

---

## Preguntas sobre Docker

### ❓ ¿Por qué uso multi-stage builds en los Dockerfiles?

**Respuesta**: Para reducir drásticamente el tamaño de la imagen.

**Sin multi-stage**:
```dockerfile
FROM maven:3.9-eclipse-temurin-21
# Copia TODO: código + maven + dependencias
# Resultado: ~800MB
```

**Con multi-stage**:
```dockerfile
# Stage 1: Build (se descarta)
FROM maven:3.9-eclipse-temurin-21 AS build
RUN mvn clean package

# Stage 2: Runtime (imagen final)
FROM eclipse-temurin:21-jre-alpine
COPY --from=build /app/target/*.jar app.jar
# Resultado: ~100MB (solo JRE + JAR)
```

**Beneficio**: La imagen final solo contiene lo necesario para ejecutar, no para compilar.

---

### ❓ ¿Por qué el backend usa Alpine Linux?

**Respuesta**: 

- **Alpine Linux** es una distribución minimalista de Linux
- **Tamaño**: ~5MB vs ~100MB de Ubuntu
- **Seguridad**: Menos paquetes = menos vulnerabilidades
- **Velocidad**: Descarga y arranque más rápidos

```dockerfile
FROM eclipse-temurin:21-jre-alpine  # ~100MB total
# vs
FROM eclipse-temurin:21-jre         # ~200MB total
```

---

### ❓ ¿Puedo modificar las imágenes después de subirlas a Docker Hub?

**Respuesta**: No puedes modificar una imagen ya subida, pero puedes:

1. **Crear una nueva versión**:
```bash
docker build -t jhonbrayansilvalaura/jhon-silva-be:1.1 .
docker push jhonbrayansilvalaura/jhon-silva-be:1.1
```

2. **Actualizar el tag `latest`**:
```bash
docker tag jhonbrayansilvalaura/jhon-silva-be:1.1 jhonbrayansilvalaura/jhon-silva-be:latest
docker push jhonbrayansilvalaura/jhon-silva-be:latest
```

3. **Actualizar Kubernetes**:
```yaml
# En el deployment
image: jhonbrayansilvalaura/jhon-silva-be:1.1  # Cambiar versión
```

---

## Preguntas sobre Base64 y Secrets

### ❓ ¿Por qué debo hashear (base64) los secrets?

**Respuesta**: No es "hashear", es **codificar en base64**. Kubernetes requiere que los valores en `data` estén en base64 porque:

1. **Formato estándar**: Kubernetes espera este formato
2. **Caracteres especiales**: Base64 evita problemas con caracteres raros
3. **Binario**: Permite almacenar datos no texto (imágenes, certificados)

**IMPORTANTE**: Base64 NO es encriptación, solo codificación. Los secrets deben protegerse con RBAC.

---

### ❓ ¿Cuál es la diferencia entre `data` y `stringData` en Secrets?

**Respuesta**:

```yaml
# Opción 1: data (valores en base64)
apiVersion: v1
kind: Secret
metadata:
  name: mi-secret
data:
  password: bXlwYXNzd29yZA==  # "mypassword" en base64

---

# Opción 2: stringData (valores en texto plano)
apiVersion: v1
kind: Secret
metadata:
  name: mi-secret
stringData:
  password: mypassword  # Kubernetes lo convierte a base64 automáticamente
```

**Tu profe pidió `data`** porque es la forma explícita y profesional de trabajar con secrets.

---

### ❓ ¿Cómo saber si mi base64 está correcto?

**Respuesta**:

```bash
# 1. Codificar
echo -n "mipassword" | base64
# Resultado: bWlwYXNzd29yZA==

# 2. Decodificar para verificar
echo "bWlwYXNzd29yZA==" | base64 -d
# Debe mostrar: mipassword

# 3. En PowerShell
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("mipassword"))
# Decodificar
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("bWlwYXNzd29yZA=="))
```

**Regla de oro**: SIEMPRE usa `-n` en Linux/Mac para evitar incluir el salto de línea.

---

### ❓ ¿Los Secrets son seguros?

**Respuesta**: Base64 NO es seguridad, solo codificación. Para seguridad real:

1. **RBAC**: Controla quién puede ver secrets
```bash
kubectl get secret -n jhon-silva-backend  # Solo usuarios autorizados
```

2. **Encriptación en reposo**: Kubernetes puede encriptar secrets en etcd
3. **External Secrets**: Usar servicios como AWS Secrets Manager, Vault
4. **Nunca commitear secrets**: Usar `.gitignore`

---

## Preguntas sobre Base de Datos

### ❓ ¿Qué es Neon y por qué lo usamos?

**Respuesta**: **Neon** es PostgreSQL serverless en la nube.

**Ventajas**:
- ✅ PostgreSQL completo (no base de datos limitada)
- ✅ Gratis hasta 10 proyectos
- ✅ Sin necesidad de instalar PostgreSQL local
- ✅ Autoscaling automático
- ✅ Backups automáticos
- ✅ Accesible desde cualquier lugar

**Alternativas**: AWS RDS, Google Cloud SQL, Supabase

---

### ❓ ¿Qué es R2DBC y en qué se diferencia de JDBC?

**Respuesta**:

| Característica | JDBC | R2DBC |
|----------------|------|-------|
| **Modelo** | Bloqueante (sync) | No bloqueante (async) |
| **Hilos** | 1 hilo por request | Pocos hilos, muchos requests |
| **Escalabilidad** | Limitada | Alta |
| **Uso** | Spring MVC | Spring WebFlux |

**Analogía**:
- **JDBC**: Un cajero que atiende a 1 cliente a la vez. Con 100 clientes necesitas 100 cajeros.
- **R2DBC**: Un cajero que toma pedidos y entrega cuando están listos. Con 100 clientes bastan 5 cajeros.

---

### ❓ ¿Puedo usar una base de datos local en lugar de Neon?

**Respuesta**: Sí, pero necesitas:

1. **Instalar PostgreSQL**:
```bash
# Windows: Descargar de postgresql.org
# Mac: brew install postgresql
# Linux: apt install postgresql
```

2. **Cambiar la URL en el Secret**:
```yaml
data:
  db-url: cjJkYmM6cG9zdGdyZXNxbDovL2xvY2FsaG9zdDo1NDMyL2RlbW8=
  # Decodificado: r2dbc:postgresql://localhost:5432/demo
```

3. **Exponer PostgreSQL al cluster**:
```bash
# Crear un Service que apunte al host
# O usar host.docker.internal en Docker Desktop
```

---

## Preguntas sobre el Proyecto

### ❓ ¿Por qué usamos Spring WebFlux y no Spring MVC?

**Respuesta**: 

**Spring MVC** (tradicional):
- Bloqueante: 1 hilo por request
- Bueno para: CRUD simple, tráfico bajo
- Escalabilidad: Vertical (más RAM/CPU)

**Spring WebFlux** (reactivo):
- No bloqueante: Pocos hilos, muchos requests
- Bueno para: Alto tráfico, microservicios, streaming
- Escalabilidad: Horizontal (más instancias)

**En este proyecto**: Aprendes tecnología moderna y escalable.

---

### ❓ ¿Qué es el patrón Service/Impl?

**Respuesta**: Es una buena práctica de arquitectura:

```java
// Interface (contrato)
public interface UserService {
    Flux<User> getAllUsers();
}

// Implementación (lógica)
@Service
public class UserServiceImpl implements UserService {
    @Override
    public Flux<User> getAllUsers() {
        return userRepository.findAll();
    }
}
```

**Ventajas**:
- **Testeable**: Puedes crear mocks de la interfaz
- **Flexible**: Múltiples implementaciones (UserServiceImplV2, MockUserService)
- **Clean Code**: Separa el "qué" del "cómo"

---

### ❓ ¿Por qué el frontend usa standalone components?

**Respuesta**: Angular 15+ recomienda componentes standalone porque:

- ✅ No necesitas `NgModule`
- ✅ Menos código boilerplate
- ✅ Importaciones más claras
- ✅ Mejor tree-shaking (bundles más pequeños)
- ✅ Más fácil de entender

```typescript
// Standalone component
@Component({
  selector: 'app-user-list',
  standalone: true,  // ✨ Nueva forma
  imports: [CommonModule, FormsModule],  // Importas lo que necesitas
  templateUrl: './user-list.component.html'
})
export class UserListComponent { }
```

---

### ❓ ¿Por qué 10 campos en el modelo User?

**Respuesta**: Requisito del proyecto para demostrar:

- CRUD completo con múltiples campos
- Validaciones
- Formularios complejos
- Manejo de diferentes tipos de datos (String, Enum, LocalDateTime)
- Campos auditables (createdAt, updatedAt)

---

### ❓ ¿Puedo agregar más funcionalidades al proyecto?

**Respuesta**: ¡Claro! Sugerencias:

1. **Autenticación**: JWT + Spring Security
2. **Paginación**: Agregar `Pageable` a los endpoints
3. **Búsqueda**: Filtros por nombre, email, estado
4. **Validaciones**: Bean Validation en el backend
5. **Testing**: JUnit + Mockito para tests unitarios
6. **Logging**: Agregar logs con SLF4J
7. **Swagger**: Documentar la API con Springdoc
8. **Cache**: Redis para cachear usuarios

---

### ❓ ¿Cómo sé si todo está funcionando correctamente?

**Respuesta**: Checklist rápido:

```bash
# 1. Verificar pods
kubectl get pods --all-namespaces | grep jhon-silva
# Todos deben estar en "Running"

# 2. Verificar servicios
kubectl get services --all-namespaces | grep jhon-silva
# Deben tener EXTERNAL-IP asignada

# 3. Probar backend
curl http://localhost:8080/api/users
# Debe retornar JSON (aunque esté vacío: [])

# 4. Probar frontend
# Abrir http://localhost:4200 en el navegador
# Debe cargar la interfaz de usuarios
```

---

## 🤔 ¿Tienes más preguntas?

Si tu pregunta no está aquí:

1. Revisa el documento **08-TROUBLESHOOTING** para problemas técnicos
2. Revisa los logs: `kubectl logs -n NAMESPACE POD_NAME`
3. Consulta la documentación oficial:
   - Kubernetes: https://kubernetes.io/docs/
   - Spring WebFlux: https://docs.spring.io/spring-framework/reference/web/webflux.html
   - Angular: https://angular.dev/
