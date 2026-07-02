# 📚 Documentación Completa del Proyecto

## Sistema CRUD Reactivo con Spring WebFlux + Angular + Kubernetes

**Autor**: Jhon Brayan Silva Laura  
**Fecha**: Julio 2026  
**Versión**: 1.0

---

## 🎯 Descripción del Proyecto

Este proyecto es una aplicación CRUD completa y reactiva para gestión de usuarios, implementada con:

- **Backend**: Spring Boot 3 + WebFlux (Reactivo) + R2DBC + PostgreSQL
- **Frontend**: Angular 21 + Standalone Components + Font Awesome
- **Base de Datos**: PostgreSQL en Neon Cloud (Serverless)
- **Contenedores**: Docker + Docker Hub
- **Orquestación**: Kubernetes + MetalLB LoadBalancer

### ✨ Características Principales

✅ **100% Reactivo**: Usa Mono/Flux para operaciones no bloqueantes  
✅ **Escalable**: 2 réplicas por defecto con LoadBalancer  
✅ **Seguro**: Secrets hasheados en base64  
✅ **Profesional**: Arquitectura limpia con Service/Impl pattern  
✅ **Moderno**: Angular standalone components  
✅ **Optimizado**: Imágenes Docker multi-stage (~100MB backend, ~26MB frontend)  
✅ **Cloud-Ready**: Base de datos PostgreSQL serverless en Neon  

---

## 📖 Índice de Documentación

### 📘 Guías Fundamentales

| # | Documento | Descripción |
|---|-----------|-------------|
| **01** | [Base64 y Secrets](./01-BASE64-Y-SECRETS.md) | Cómo hashear valores con base64 para Kubernetes |
| **02** | [MetalLB Config Explicado](./02-METALLB-CONFIG-EXPLICADO.md) | Configuración detallada de MetalLB para LoadBalancer |
| **03** | [Script Iniciar Servicios](./03-INICIAR-SERVICIOS-BAT.md) | Explicación del script de port-forward automático |

### 📗 Arquitectura Kubernetes

| # | Documento | Descripción |
|---|-----------|-------------|
| **04** | [Archivos Kubernetes Backend](./04-ARCHIVOS-KUBERNETES-BACKEND.md) | Explicación de los 4 archivos K8s del backend |
| **05** | [Archivos Kubernetes Frontend](./05-ARCHIVOS-KUBERNETES-FRONTEND.md) | Explicación de los 4 archivos K8s del frontend |

### 📕 Ejecución y Estructura

| # | Documento | Descripción |
|---|-----------|-------------|
| **06** | [Guía Completa de Ejecución](./06-GUIA-COMPLETA-EJECUCION.md) | Paso a paso para desplegar el proyecto completo |
| **07** | [Estructura de Archivos](./07-ESTRUCTURA-ARCHIVOS-PROYECTO.md) | Organización de archivos del backend y frontend |

### 📙 Soporte y Referencia

| # | Documento | Descripción |
|---|-----------|-------------|
| **08** | [Troubleshooting](./08-TROUBLESHOOTING-PROBLEMAS-COMUNES.md) | Soluciones a problemas comunes |
| **09** | [FAQ - Preguntas Frecuentes](./09-FAQ-PREGUNTAS-FRECUENTES.md) | Respuestas a dudas frecuentes |
| **10** | [Resumen de Comandos](./10-RESUMEN-COMANDOS.md) | Todos los comandos organizados por categoría |

---

## 🚀 Quick Start - Inicio Rápido

### Prerrequisitos

```bash
✅ Docker Desktop instalado y corriendo
✅ Kubernetes habilitado en Docker Desktop
✅ kubectl instalado
✅ Cuenta en Docker Hub (jhonbrayansilvalaura)
```

### Despliegue en 5 Pasos

```bash
# 1. Instalar MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl apply -f metallb-config.yaml

# 2. Desplegar Backend
cd demo
kubectl apply -f k8s/

# 3. Desplegar Frontend
cd ../demo-front
kubectl apply -f k8s/

# 4. Verificar
kubectl get pods --all-namespaces
kubectl get services --all-namespaces

# 5. Acceder (Windows)
.\iniciar-servicios.bat
```

### Accesos

- **Backend API**: `http://localhost:8080/api/users`
- **Frontend UI**: `http://localhost:4200`
- **Backend LoadBalancer**: `172.19.255.200:8080` (solo dentro del cluster)
- **Frontend LoadBalancer**: `172.19.255.201:80` (solo dentro del cluster)

---

## 🏗️ Arquitectura del Sistema

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────┐
│                    USUARIO (Navegador)                   │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────▼───────────┐
         │   Port-Forward        │
         │   localhost:4200      │
         └───────────┬───────────┘
                     │
┌────────────────────▼─────────────────────────────────────┐
│                   KUBERNETES CLUSTER                      │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │  MetalLB LoadBalancer                            │    │
│  │  IP Pool: 172.19.255.200-172.19.255.250         │    │
│  └────┬─────────────────────────────┬───────────────┘    │
│       │                             │                     │
│  ┌────▼────────────┐          ┌────▼────────────┐       │
│  │   FRONTEND      │          │    BACKEND      │       │
│  │   Namespace     │          │    Namespace    │       │
│  │                 │          │                 │       │
│  │  Service (LB)   │          │  Service (LB)   │       │
│  │  172.19.255.201 │──HTTP──▶ │  172.19.255.200 │       │
│  │  Port: 80       │          │  Port: 8080     │       │
│  │                 │          │                 │       │
│  │  Deployment     │          │  Deployment     │       │
│  │  ├─ Pod 1       │          │  ├─ Pod 1       │       │
│  │  └─ Pod 2       │          │  └─ Pod 2       │       │
│  │  (Nginx+Angular)│          │  (Spring WebFlux)│      │
│  └─────────────────┘          └────────┬────────┘       │
│                                         │                 │
└─────────────────────────────────────────┼─────────────────┘
                                          │
                                          │ R2DBC
                                          │ (Reactivo)
                                          │
                              ┌───────────▼──────────┐
                              │   Neon PostgreSQL    │
                              │   (Cloud Database)   │
                              │   Serverless         │
                              └──────────────────────┘
```

### Stack Tecnológico

#### Backend
- **Framework**: Spring Boot 3.4.1
- **Paradigma**: Reactivo (WebFlux)
- **Base de Datos**: R2DBC PostgreSQL
- **Java**: 21 (Eclipse Temurin)
- **Patrón**: Service/Impl
- **Contenedor**: Docker (Alpine Linux)

#### Frontend
- **Framework**: Angular 21
- **Arquitectura**: Standalone Components
- **HTTP Client**: HttpClient (Reactivo)
- **Estilos**: SCSS + Font Awesome
- **Servidor Web**: Nginx
- **Contenedor**: Docker (Alpine Linux)

#### Infraestructura
- **Orquestación**: Kubernetes
- **LoadBalancer**: MetalLB v0.14.3
- **Registry**: Docker Hub
- **Base de Datos**: Neon PostgreSQL (Cloud)

---

## 📦 Recursos del Proyecto

### Imágenes Docker

```bash
# Backend
docker pull jhonbrayansilvalaura/jhon-silva-be:1.0
# Tamaño: ~102MB

# Frontend
docker pull jhonbrayansilvalaura/jhon-silva-fe:1.0
# Tamaño: ~26.4MB
```

### Archivos Kubernetes

**Backend** (`demo/k8s/`):
- `jhon-silva-00-namespace-be.yml` - Namespace
- `jhon-silva-00-secret-be.yml` - Secrets (DB credentials)
- `jhon-silva-00-service-be.yml` - LoadBalancer Service
- `jhon-silva-00-deployment-be.yml` - Deployment (2 replicas)

**Frontend** (`demo-front/k8s/`):
- `jhon-silva-00-namespace-fe.yml` - Namespace
- `jhon-silva-00-secret-fe.yml` - Secrets (API URL)
- `jhon-silva-00-service-fe.yml` - LoadBalancer Service
- `jhon-silva-00-deployment-fe.yml` - Deployment (2 replicas)

### Configuración

- `metallb-config.yaml` - Configuración de MetalLB
- `iniciar-servicios.bat` - Script de port-forward automático

---

## 🎓 Para Aprender

### Si eres nuevo en...

#### 🔰 Kubernetes
1. Lee: [06-GUIA-COMPLETA-EJECUCION.md](./06-GUIA-COMPLETA-EJECUCION.md)
2. Luego: [04-ARCHIVOS-KUBERNETES-BACKEND.md](./04-ARCHIVOS-KUBERNETES-BACKEND.md)
3. Practica con: [10-RESUMEN-COMANDOS.md](./10-RESUMEN-COMANDOS.md)

#### 🔰 Docker
1. Lee la sección de Docker en: [10-RESUMEN-COMANDOS.md](./10-RESUMEN-COMANDOS.md)
2. Revisa los `Dockerfile` en `demo/` y `demo-front/`

#### 🔰 Spring WebFlux
1. Revisa la estructura en: [07-ESTRUCTURA-ARCHIVOS-PROYECTO.md](./07-ESTRUCTURA-ARCHIVOS-PROYECTO.md)
2. Estudia los archivos:
   - `UserController.java` - Endpoints REST
   - `UserService.java` - Interface
   - `UserServiceImpl.java` - Lógica reactiva

#### 🔰 Angular
1. Revisa la estructura en: [07-ESTRUCTURA-ARCHIVOS-PROYECTO.md](./07-ESTRUCTURA-ARCHIVOS-PROYECTO.md)
2. Estudia los archivos:
   - `user-list.component.ts` - Componente standalone
   - `user.service.ts` - Servicio HTTP
   - `user.interface.ts` - Modelo TypeScript

---

## 🔧 Flujo de Trabajo Recomendado

### Desarrollo Local

```bash
# 1. Hacer cambios en el código
# Editar archivos en demo/ o demo-front/

# 2. Reconstruir imagen
cd demo
docker build -t jhonbrayansilvalaura/jhon-silva-be:1.1 .

# 3. Subir a Docker Hub
docker push jhonbrayansilvalaura/jhon-silva-be:1.1

# 4. Actualizar Kubernetes
# Editar k8s/jhon-silva-00-deployment-be.yml
# Cambiar: image: jhonbrayansilvalaura/jhon-silva-be:1.1

kubectl apply -f k8s/jhon-silva-00-deployment-be.yml

# 5. Verificar
kubectl rollout status deployment -n jhon-silva-backend jhon-silva-backend-deployment
```

### Testing

```bash
# Backend
cd demo
mvn test

# Frontend
cd demo-front
npm test

# E2E
npm run e2e
```

---

## 🐛 Resolución de Problemas

### ¿Algo no funciona?

1. **Verifica el estado**:
```bash
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
```

2. **Revisa los logs**:
```bash
kubectl logs -n jhon-silva-backend -l app=jhon-silva-backend
kubectl logs -n jhon-silva-frontend -l app=jhon-silva-frontend
```

3. **Consulta la documentación**:
   - [08-TROUBLESHOOTING-PROBLEMAS-COMUNES.md](./08-TROUBLESHOOTING-PROBLEMAS-COMUNES.md)
   - [09-FAQ-PREGUNTAS-FRECUENTES.md](./09-FAQ-PREGUNTAS-FRECUENTES.md)

---

## 📊 Modelo de Datos

### Entidad User

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | SERIAL | ID autoincremental (PK) |
| `username` | VARCHAR(255) | Nombre de usuario (único) |
| `email` | VARCHAR(255) | Email (único) |
| `first_name` | VARCHAR(255) | Primer nombre |
| `last_name` | VARCHAR(255) | Apellido |
| `phone` | VARCHAR(50) | Teléfono |
| `address` | TEXT | Dirección |
| `status` | VARCHAR(50) | Estado: ACTIVE, INACTIVE, SUSPENDED |
| `created_at` | TIMESTAMP | Fecha de creación |
| `updated_at` | TIMESTAMP | Fecha de actualización |

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/users` | Listar todos los usuarios |
| GET | `/api/users/{id}` | Obtener usuario por ID |
| POST | `/api/users` | Crear nuevo usuario |
| PUT | `/api/users/{id}` | Actualizar usuario |
| DELETE | `/api/users/{id}` | Eliminar usuario |
| PUT | `/api/users/{id}/activate` | Activar usuario |
| PUT | `/api/users/{id}/deactivate` | Desactivar usuario |
| PUT | `/api/users/{id}/suspend` | Suspender usuario |

---

## 🌟 Características Avanzadas

### ✅ Implementado

- [x] CRUD completo reactivo (Mono/Flux)
- [x] Gestión de estados (ACTIVE, INACTIVE, SUSPENDED)
- [x] Base de datos cloud (Neon PostgreSQL)
- [x] Contenedores Docker optimizados
- [x] Kubernetes con LoadBalancer
- [x] 2 réplicas por alta disponibilidad
- [x] Secrets en base64
- [x] Port-forward automático
- [x] Frontend con standalone components
- [x] Font Awesome icons

### 🎯 Posibles Mejoras Futuras

- [ ] Autenticación JWT + Spring Security
- [ ] Paginación en los endpoints
- [ ] Filtros de búsqueda
- [ ] Validaciones con Bean Validation
- [ ] Tests unitarios (JUnit + Mockito)
- [ ] Tests E2E (Cypress)
- [ ] Documentación API con Swagger/OpenAPI
- [ ] CI/CD con GitHub Actions
- [ ] Monitoreo con Prometheus + Grafana
- [ ] Logging centralizado con ELK Stack
- [ ] Cache con Redis
- [ ] Rate limiting
- [ ] Horizontal Pod Autoscaler (HPA)

---

## 📝 Notas Importantes

### ⚠️ Docker Desktop en Windows

Las IPs del LoadBalancer (172.19.255.x) **solo funcionan dentro del cluster**. Para acceder desde Windows:

- ✅ Usa `iniciar-servicios.bat` (port-forward automático)
- ✅ Usa NodePort: `http://localhost:30080`
- ✅ Usa port-forward manual: `kubectl port-forward ...`

### 🔐 Seguridad

- Los secrets están en base64 (codificación, NO encriptación)
- En producción, usa soluciones como:
  - AWS Secrets Manager
  - HashiCorp Vault
  - Kubernetes External Secrets
- Nunca commits secrets al repositorio Git

### 🌐 Base de Datos

- **Neon** tiene un plan gratuito limitado
- Para producción, considera:
  - AWS RDS
  - Google Cloud SQL
  - Azure Database for PostgreSQL

---

## 📞 Contacto y Recursos

### Documentación Oficial

- **Kubernetes**: https://kubernetes.io/docs/
- **Spring WebFlux**: https://docs.spring.io/spring-framework/reference/web/webflux.html
- **Angular**: https://angular.dev/
- **MetalLB**: https://metallb.universe.tf/
- **Neon**: https://neon.tech/docs/introduction

### Autor

**Jhon Brayan Silva Laura**  
Docker Hub: [@jhonbrayansilvalaura](https://hub.docker.com/u/jhonbrayansilvalaura)

---

## 📄 Licencia

Este proyecto fue creado con fines educativos.

---

## 🎉 ¡Listo para Empezar!

1. Lee la [Guía Completa de Ejecución](./06-GUIA-COMPLETA-EJECUCION.md)
2. Ejecuta el despliegue siguiendo los pasos
3. Consulta el [FAQ](./09-FAQ-PREGUNTAS-FRECUENTES.md) si tienes dudas
4. Usa el [Resumen de Comandos](./10-RESUMEN-COMANDOS.md) como referencia

**¡Éxito con tu proyecto! 🚀**

---

<p align="center">
  <sub>Documentación generada el 2 de Julio de 2026</sub>
</p>
