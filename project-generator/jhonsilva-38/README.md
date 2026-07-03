# jhonsilva-38

Proyecto generado con Spring Boot 3 + WebFlux + R2DBC + Docker + Kubernetes

## Tecnologias

- Java 21
- Spring Boot 3.3.4
- Spring WebFlux (Reactive)
- R2DBC (Reactive Database Connectivity)
- PostgreSQL (Neon Cloud)
- Docker & Docker Compose
- Kubernetes (K8s)
- Maven

## Entidades

- Students (Endpoint: /api/studentses)


## Endpoints Disponibles

Cada entidad tiene los siguientes endpoints:

### CRUD Basico
- `GET /api/{entidad}` - Listar todos
- `GET /api/{entidad}?status=ACTIVE` - Filtrar por status
- `GET /api/{entidad}/{id}` - Obtener por ID
- `POST /api/{entidad}` - Crear nuevo
- `PUT /api/{entidad}/{id}` - Actualizar
- `DELETE /api/{entidad}/{id}` - Eliminar

### Gestion de Estado
- `PATCH /api/{entidad}/{id}/activate` - Activar
- `PATCH /api/{entidad}/{id}/deactivate` - Desactivar
- `PATCH /api/{entidad}/{id}/suspend` - Suspender

## Desarrollo Local

### Requisitos
- Java 21
- Maven 3.9+
- Docker & Docker Compose (opcional)

### Ejecutar con Maven
``ash
# Compilar
mvnw clean package

# Ejecutar
mvnw spring-boot:run
``

### Ejecutar con Docker Compose
``ash
# Construir y ejecutar
docker-compose up --build

# Detener
docker-compose down
``

La API estara disponible en: http://localhost:8080

### Endpoints de prueba
* http://localhost:8080/api/studentses


## Despliegue en Kubernetes

### 1. Crear namespace
``ash
kubectl apply -f k8s/jhon-silva-38-namespace.yml
``

### 2. Configurar secrets
Edita `k8s/jhon-silva-38-secret.yml` con tus credenciales en base64:
``ash
# Para encodear en base64
echo -n "tu-valor" | base64
``

Luego aplica:
``ash
kubectl apply -f k8s/jhon-silva-38-secret.yml
``

### 3. Desplegar aplicacion
``ash
kubectl apply -f k8s/jhon-silva-38-deployment.yml
kubectl apply -f k8s/jhon-silva-38-service.yml
``

### 4. Verificar despliegue
``ash
# Ver pods
kubectl get pods -n jhon-silva-38

# Ver servicios
kubectl get svc -n jhon-silva-38

# Ver logs
kubectl logs -n jhon-silva-38 -l app=jhon-silva-38 -f
``

## Compilar imagen Docker

``ash
# Construir imagen
docker build -t jhonbrayansilvalaura/jhonsilva-38:1.0 .

# Subir a Docker Hub
docker push jhonbrayansilvalaura/jhonsilva-38:1.0
``

## Estructura del Proyecto

``
jhonsilva-38/
â”œâ”€â”€ src/
â”‚   â”œâ”€â”€ main/
â”‚   â”‚   â”œâ”€â”€ java/pe/edu/vallegrande/jhonsilva38/
â”‚   â”‚   â”‚   â”œâ”€â”€ model/           # Entidades
â”‚   â”‚   â”‚   â”œâ”€â”€ repository/      # Repositorios R2DBC
â”‚   â”‚   â”‚   â”œâ”€â”€ service/         # Logica de negocio
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ impl/
â”‚   â”‚   â”‚   â””â”€â”€ rest/            # Controladores REST
â”‚   â”‚   â””â”€â”€ resources/
â”‚   â”‚       â”œâ”€â”€ application.yaml
â”‚   â”‚       â””â”€â”€ schema.sql
â”‚   â””â”€â”€ test/
â”œâ”€â”€ k8s/                          # Manifiestos Kubernetes
â”œâ”€â”€ Dockerfile
â”œâ”€â”€ docker-compose.yml
â”œâ”€â”€ pom.xml
â””â”€â”€ README.md
``

## Base de Datos

### Neon PostgreSQL (Cloud)
- URL: dafsdfa
- Database: adfsaf
- SSL Mode: require

Las tablas se crean automaticamente al iniciar la aplicacion.

## Soporte

Generado automaticamente con el generador de proyectos Spring Boot WebFlux.