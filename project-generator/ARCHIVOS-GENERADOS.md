# Archivos Generados Automaticamente

## Backend Generator (generar-proyecto.ps1)

El generador de backend ahora crea **TODOS** estos archivos automaticamente:

### 1. Estructura Base
```
proyecto/
├── src/
│   ├── main/
│   │   ├── java/[paquete]/
│   │   │   ├── [Aplicacion]Application.java
│   │   │   ├── model/
│   │   │   │   └── [Entidad].java
│   │   │   ├── repository/
│   │   │   │   └── [Entidad]Repository.java
│   │   │   ├── service/
│   │   │   │   ├── [Entidad]Service.java
│   │   │   │   └── impl/
│   │   │   │       └── [Entidad]ServiceImpl.java
│   │   │   └── rest/
│   │   │       └── [Entidad]Rest.java
│   │   └── resources/
│   │       ├── application.yaml
│   │       └── schema.sql
│   └── test/
│       └── java/[paquete]/
└── ...
```

### 2. Archivos Docker
- **Dockerfile** - Multi-stage build con Java 21 Alpine
- **docker-compose.yml** - Backend + PostgreSQL con healthchecks
- **.dockerignore** - Excluir archivos innecesarios

### 3. Archivos Git
- **.gitignore** - Ignora target/, .idea/, .env, etc.
- **.gitattributes** - Line endings para mvnw y .cmd

### 4. Kubernetes (k8s/)
- **[namespace]-namespace.yml** - Namespace dedicado
- **[namespace]-secret.yml** - Secrets en base64 (DB credentials)
- **[namespace]-deployment.yml** - Deployment con 2 replicas, probes, resources
- **[namespace]-service.yml** - Service tipo LoadBalancer con NodePort

### 5. Documentacion
- **README.md** - Guia completa con:
  - Descripcion del proyecto
  - Tecnologias usadas
  - Entidades y endpoints
  - Instrucciones de desarrollo local
  - Instrucciones Docker Compose
  - Instrucciones Kubernetes
  - Estructura del proyecto
- **HELP.md** - Referencias de Spring Boot, guias, links utiles

### 6. Configuracion
- **.env.example** - Plantilla de variables de entorno
- **pom.xml** - Configuracion Maven con todas las dependencias

### 7. Caracteristicas Especiales

#### Dockerfile Optimizado
- Multi-stage build (reduce tamano de imagen)
- Java 21 con Alpine Linux
- Usuario no-root (spring:spring)
- Cache de dependencias Maven
- Puerto flexible via ENV

#### docker-compose.yml Inteligente
- Opcion 1: Neon PostgreSQL (Cloud) - solo backend
- Opcion 2: PostgreSQL Local - backend + postgres container
- Opcion 3: H2 In-Memory - solo backend
- Healthchecks para todos los servicios
- Volumenes persistentes (si usa PostgreSQL local)
- Network bridge dedicada

#### Kubernetes Production-Ready
- Secrets en base64 automaticos (si eliges Neon)
- Deployment con:
  - 2 replicas
  - Rolling updates
  - Resource limits (256Mi-512Mi RAM, 250m-500m CPU)
  - Liveness & Readiness probes
  - Variables de entorno desde secrets
- Service tipo LoadBalancer con NodePort calculado automaticamente

#### Schema.sql Avanzado
- DROP TABLE IF EXISTS (seguro para re-deploy)
- Indices automaticos en columna status
- Datos de prueba opcionales (si el usuario lo activa)
- Columnas en snake_case (created_at, updated_at)
- Conversion automatica de tipos: textoLargo → TEXT, timestamp → TIMESTAMP

---

## Frontend Generator (generar-crud-angular.ps1)

### Archivos Generados

```
proyecto-angular/
├── src/
│   ├── app/
│   │   ├── core/
│   │   │   ├── interface/
│   │   │   │   └── [entidad].ts
│   │   │   └── service/
│   │   │       └── [entidad]-service.ts
│   │   ├── feature/
│   │   │   └── [entidad]/
│   │   │       ├── [entidad].ts (component)
│   │   │       ├── [entidad].html
│   │   │       └── [entidad].scss
│   │   ├── app.ts
│   │   ├── app.html
│   │   ├── app.scss
│   │   ├── app.config.ts
│   │   └── app.routes.ts
│   ├── environments/
│   │   ├── environment.ts
│   │   └── environment.development.ts
│   └── styles.scss (con Font Awesome)
├── angular.json
├── package.json
└── ...
```

### Caracteristicas

#### Deteccion Automatica de Status
- **Si status es Boolean**: Genera condiciones `item.status !== false` y `item.status === false`
- **Si status es String**: Genera condiciones `item.status !== 'DELETED'` y `item.status === 'DELETED'`

#### Soft Delete Completo
- 3 metodos en service: `deleteById()`, `restoreById()`, `delete()`
- Badges de colores: verde (ACTIVE), amarillo (INACTIVE), rojo (DELETED)
- Botones condicionales segun status

#### Angular 21 Style
- Standalone components
- Signals para estado reactivo
- `inject()` para dependency injection
- FormsModule (template-driven)
- Sin sufijos en nombres de archivo
- Tipos con mayuscula inicial (String, Number, Boolean)

---

## Resumen de Mejoras

### ✅ Backend (Spring Boot)
1. **Dockerfile** multi-stage con Java 21 Alpine
2. **docker-compose.yml** con 3 opciones de base de datos
3. **Kubernetes** production-ready (secrets, deployment, service, namespace)
4. **.gitignore**, **.dockerignore**, **.gitattributes**
5. **.env.example** con ejemplos de Neon/Supabase/ElephantSQL
6. **README.md** completo con todas las instrucciones
7. **HELP.md** con referencias de Spring Boot
8. **Schema.sql** con indices y snake_case

### ✅ Frontend (Angular 21)
1. Deteccion automatica de tipo de campo **status** (Boolean vs String)
2. Soft delete con 3 metodos
3. Status badges con colores
4. Botones condicionales segun estado
5. Mantenimiento del orden de campos del usuario

---

## Como Usar

### Backend
```bash
cd project-generator
.\GENERAR-BACKEND.bat
```

El script preguntara:
1. Nombre del proyecto
2. Paquete base Java
3. Puerto de la API
4. **Base de datos (Neon/Local/H2)**
5. Credenciales (si es Neon)
6. Namespace de Kubernetes
7. Usuario de Docker Hub
8. Opciones: CORS, datos de prueba
9. Entidades y campos

### Frontend
```bash
cd project-generator
.\GENERAR-FRONTEND.bat
```

El script preguntara:
1. Nombre del proyecto
2. Nombre de la entidad
3. Backend URL
4. Endpoint API
5. Campos (nombre:tipo)

---

## Notas Importantes

- **Todos los archivos se generan en UTF-8 sin BOM** (evita errores de compilacion)
- **Sin emojis ni caracteres Unicode** (compatible con PowerShell 5.1)
- **Secrets de Kubernetes en base64** (si eliges Neon, se generan automaticamente)
- **NodePort calculado automaticamente** (30000 + ultimos 4 digitos del puerto)
- **Healthchecks en Docker Compose** (usa el primer endpoint generado)

---

Generado: 2026-07-02
Version: 3.0
