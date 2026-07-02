# 📁 ESTRUCTURA DE ARCHIVOS DEL PROYECTO

## 🎯 ÁRBOL COMPLETO DEL PROYECTO

```
JalatonJuC/
├── demo/ (Backend - Spring Boot WebFlux)
├── demo-front/ (Frontend - Angular 21)
├── documentacion/ (Documentación completa)
├── metallb-config.yaml (Configuración LoadBalancer)
├── iniciar-servicios.bat (Script automático)
└── *.md (Guías varias)
```

---

## 📦 BACKEND (demo/)

### Estructura Completa:

```
demo/
├── src/
│   ├── main/
│   │   ├── java/com/example/demo/
│   │   │   ├── DemoApplication.java
│   │   │   ├── model/
│   │   │   │   └── User.java
│   │   │   ├── repository/
│   │   │   │   └── UserRepository.java
│   │   │   ├── service/
│   │   │   │   ├── UserService.java
│   │   │   │   └── impl/
│   │   │   │       └── UserServiceImpl.java
│   │   │   └── rest/
│   │   │       └── UserController.java
│   │   └── resources/
│   │       ├── application.yaml
│   │       └── schema.sql
│   └── test/
│       └── java/com/example/demo/
│           └── DemoApplicationTests.java
├── k8s/
│   ├── jhon-silva-00-namespace-be.yml
│   ├── jhon-silva-00-secret-be.yml
│   ├── jhon-silva-00-service-be.yml
│   └── jhon-silva-00-deployment-be.yml
├── target/ (compilado, ignorar)
├── Dockerfile
├── pom.xml
├── .env
└── .gitignore
```

### 📄 Archivos Java Principales:

#### 1. DemoApplication.java
```
Ubicación: src/main/java/com/example/demo/DemoApplication.java
Líneas: ~15
```
**Qué hace**:
- Punto de entrada de Spring Boot
- Inicia la aplicación WebFlux
- `@SpringBootApplication` principal

**Contenido clave**:
```java
@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

---

#### 2. User.java (Model)
```
Ubicación: src/main/java/com/example/demo/model/User.java
Líneas: ~150
```
**Qué hace**:
- Define el modelo de datos User
- Mapea a la tabla `users` en PostgreSQL
- 10 campos + getters/setters

**Campos**:
```java
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String username;
    private String email;
    private String firstName;
    private String lastName;
    private String phone;
    private String address;
    private String status;  // ACTIVE, INACTIVE, SUSPENDED
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

---

#### 3. UserRepository.java
```
Ubicación: src/main/java/com/example/demo/repository/UserRepository.java
Líneas: ~15
```
**Qué hace**:
- Interface R2DBC Repository (reactivo)
- Métodos de consulta a PostgreSQL
- Extends ReactiveCrudRepository

**Métodos**:
```java
public interface UserRepository extends ReactiveCrudRepository<User, Long> {
    Mono<User> findByUsername(String username);
    Mono<User> findByEmail(String email);
    Flux<User> findByStatus(String status);
    Flux<User> findByFirstNameContainingIgnoreCaseOrLastNameContainingIgnoreCase(
        String firstName, String lastName);
}
```

---

#### 4. UserService.java (Interface)
```
Ubicación: src/main/java/com/example/demo/service/UserService.java
Líneas: ~25
```
**Qué hace**:
- Define el contrato del servicio
- Métodos reactivos (Mono/Flux)

**Métodos**:
```java
public interface UserService {
    Flux<User> getAllUsers();
    Mono<User> getUserById(Long id);
    Mono<User> createUser(User user);
    Mono<User> updateUser(Long id, User user);
    Mono<Void> deleteUser(Long id);
    Mono<User> activateUser(Long id);
    Mono<User> deactivateUser(Long id);
    Mono<User> suspendUser(Long id);
    // ... más métodos
}
```

---

#### 5. UserServiceImpl.java
```
Ubicación: src/main/java/com/example/demo/service/impl/UserServiceImpl.java
Líneas: ~120
```
**Qué hace**:
- Implementa la lógica de negocio
- Usa UserRepository
- Patrón Service/Impl

**Ejemplo de método**:
```java
@Override
public Mono<User> activateUser(Long id) {
    return userRepository.findById(id)
        .flatMap(user -> {
            user.setStatus("ACTIVE");
            user.setUpdatedAt(LocalDateTime.now());
            return userRepository.save(user);
        });
}
```

---

#### 6. UserController.java (REST API)
```
Ubicación: src/main/java/com/example/demo/rest/UserController.java
Líneas: ~80
```
**Qué hace**:
- Expone endpoints REST
- Usa UserService
- CRUD completo + estado

**Endpoints**:
```java
@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {
    @GetMapping
    Flux<User> getAllUsers();
    
    @GetMapping("/{id}")
    Mono<User> getUserById(@PathVariable Long id);
    
    @PostMapping
    Mono<User> createUser(@RequestBody User user);
    
    @PutMapping("/{id}")
    Mono<User> updateUser(@PathVariable Long id, @RequestBody User user);
    
    @DeleteMapping("/{id}")
    Mono<Void> deleteUser(@PathVariable Long id);
    
    @PatchMapping("/{id}/activate")
    Mono<User> activateUser(@PathVariable Long id);
    
    @PatchMapping("/{id}/deactivate")
    Mono<User> deactivateUser(@PathVariable Long id);
    
    @PatchMapping("/{id}/suspend")
    Mono<User> suspendUser(@PathVariable Long id);
}
```

---

### 📄 Archivos de Configuración:

#### application.yaml
```
Ubicación: src/main/resources/application.yaml
Líneas: ~20
```
**Qué hace**:
- Configura Spring Boot
- Conexión R2DBC a PostgreSQL
- Puerto del servidor

**Contenido clave**:
```yaml
spring:
  r2dbc:
    url: ${DB_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
server:
  port: ${SERVER_PORT:8080}
```

---

#### schema.sql
```
Ubicación: src/main/resources/schema.sql
Líneas: ~30
```
**Qué hace**:
- Crea la tabla `users`
- Inserta datos de prueba
- Se ejecuta al iniciar (si la tabla no existe)

**Contenido clave**:
```sql
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(255),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (username, email, first_name, last_name, phone, address, status)
VALUES 
    ('jperez', 'juan.perez@example.com', 'Juan', 'Pérez', '+51-987-654-321', 'Av. Arequipa 123, Lima', 'ACTIVE'),
    ('mgarcia', 'maria.garcia@example.com', 'María', 'García', '+51-987-654-322', 'Calle Los Olivos 456, Arequipa', 'ACTIVE'),
    ('plopez', 'pedro.lopez@example.com', 'Pedro', 'López', '+51-987-654-323', 'Jr. Puno 789, Cusco', 'INACTIVE')
ON CONFLICT (username) DO NOTHING;
```

---

#### pom.xml
```
Ubicación: demo/pom.xml
Líneas: ~100
```
**Qué hace**:
- Configuración Maven
- Dependencias del proyecto
- Build configuration

**Dependencias principales**:
```xml
<dependencies>
    <!-- Spring Boot WebFlux (Reactive) -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webflux</artifactId>
    </dependency>
    
    <!-- R2DBC PostgreSQL (Reactive Database) -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-r2dbc</artifactId>
    </dependency>
    
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>r2dbc-postgresql</artifactId>
    </dependency>
</dependencies>
```

---

#### Dockerfile
```
Ubicación: demo/Dockerfile
Líneas: ~25
```
**Qué hace**:
- Build multi-stage
- Stage 1: Compilar con Maven
- Stage 2: Ejecutar con JRE
- Imagen final: 102MB

**Contenido clave**:
```dockerfile
# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
COPY --from=build /app/target/*.jar app.jar
ENV SERVER_PORT=8080
EXPOSE ${SERVER_PORT}
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

---

### 📂 Carpeta k8s/:

```
k8s/
├── jhon-silva-00-namespace-be.yml    (~10 líneas)
├── jhon-silva-00-secret-be.yml       (~15 líneas)
├── jhon-silva-00-service-be.yml      (~20 líneas)
└── jhon-silva-00-deployment-be.yml   (~70 líneas)
```

**Total**: ~115 líneas de YAML para desplegar el backend en Kubernetes.

---

## 📦 FRONTEND (demo-front/)

### Estructura Completa:

```
demo-front/
├── src/
│   ├── app/
│   │   ├── core/
│   │   │   ├── interfaces/
│   │   │   │   └── user.interface.ts
│   │   │   └── services/
│   │   │       └── user.service.ts
│   │   ├── features/
│   │   │   └── user-management/
│   │   │       └── components/
│   │   │           ├── user-list.component.ts
│   │   │           ├── user-list.component.html
│   │   │           └── user-list.component.scss
│   │   ├── layout/ (preparado para componentes)
│   │   ├── shared/ (preparado para componentes)
│   │   ├── app.ts
│   │   ├── app.html
│   │   ├── app.scss
│   │   ├── app.config.ts
│   │   └── app.routes.ts
│   ├── environments/
│   │   ├── environment.ts
│   │   └── environment.development.ts
│   ├── index.html
│   ├── main.ts
│   └── styles.scss
├── k8s/
│   ├── jhon-silva-00-namespace-fe.yml
│   ├── jhon-silva-00-secret-fe.yml
│   ├── jhon-silva-00-service-fe.yml
│   └── jhon-silva-00-deployment-fe.yml
├── .angular/ (cache, ignorar)
├── dist/ (compilado, ignorar)
├── node_modules/ (dependencias, ignorar)
├── Dockerfile
├── nginx.conf
├── package.json
├── angular.json
├── tsconfig.json
└── .gitignore
```

### 📄 Archivos TypeScript Principales:

#### 1. user.interface.ts
```
Ubicación: src/app/core/interfaces/user.interface.ts
Líneas: ~15
```
**Qué hace**:
- Define la interface User
- Tipado TypeScript

**Contenido**:
```typescript
export interface User {
  id?: number;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  phone: string;
  address: string;
  status?: string;
  createdAt?: string;
  updatedAt?: string;
}
```

---

#### 2. user.service.ts
```
Ubicación: src/app/core/services/user.service.ts
Líneas: ~55
```
**Qué hace**:
- Servicio HTTP para comunicarse con el backend
- Métodos para CRUD + estado

**Métodos principales**:
```typescript
@Injectable({
  providedIn: 'root'
})
export class UserService {
  getAllUsers(): Observable<User[]>
  getUserById(id: number): Observable<User>
  createUser(user: User): Observable<User>
  updateUser(id: number, user: User): Observable<User>
  deleteUser(id: number): Observable<void>
  activateUser(id: number): Observable<User>
  deactivateUser(id: number): Observable<User>
  suspendUser(id: number): Observable<User>
  searchUsers(name: string): Observable<User[]>
}
```

---

#### 3. user-list.component.ts
```
Ubicación: src/app/features/user-management/components/user-list.component.ts
Líneas: ~120
```
**Qué hace**:
- Componente principal de la UI
- Gestiona estado con signals
- CRUD completo

**Métodos principales**:
```typescript
@Component({
  selector: 'app-user-list',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './user-list.component.html',
  styleUrls: ['./user-list.component.scss']
})
export class UserListComponent implements OnInit {
  users = signal<User[]>([]);
  selectedUser = signal<User | null>(null);
  
  loadUsers()
  searchUsers()
  createUser()
  updateUser()
  deleteUser(id: number)
  changeStatus(id: number, action: 'activate' | 'deactivate' | 'suspend')
  getStatusIcon(status?: string): string
}
```

---

#### 4. user-list.component.html
```
Ubicación: src/app/features/user-management/components/user-list.component.html
Líneas: ~150
```
**Qué hace**:
- Template HTML del componente
- Tabla de usuarios
- Formularios crear/editar
- Botones condicionales

**Características**:
- Font Awesome icons
- Botones condicionales por estado:
  - ACTIVE: Muestra "Desactivar" y "Suspender"
  - INACTIVE/SUSPENDED: Muestra solo "Activar"

---

### 📄 Archivos de Configuración:

#### package.json
```
Ubicación: demo-front/package.json
Líneas: ~50
```
**Qué hace**:
- Dependencias npm
- Scripts de build

**Dependencias principales**:
```json
{
  "dependencies": {
    "@angular/animations": "^21.0.0",
    "@angular/common": "^21.0.0",
    "@angular/core": "^21.0.0",
    "@angular/forms": "^21.0.0",
    "@fortawesome/fontawesome-free": "^6.7.2"
  }
}
```

---

#### nginx.conf
```
Ubicación: demo-front/nginx.conf
Líneas: ~20
```
**Qué hace**:
- Configuración Nginx para SPA
- Gzip compression
- Cache de assets

**Contenido clave**:
```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache para assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

#### Dockerfile
```
Ubicación: demo-front/Dockerfile
Líneas: ~25
```
**Qué hace**:
- Build multi-stage
- Stage 1: Compilar Angular
- Stage 2: Servir con Nginx
- Imagen final: 26.4MB

**Contenido clave**:
```dockerfile
# Stage 1: Build
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --production=false
COPY . .
RUN npm run build -- --configuration production

# Stage 2: Runtime
FROM nginx:alpine
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*
COPY --from=build /app/dist/demo-front/browser ./
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

### 📂 Carpeta k8s/:

```
k8s/
├── jhon-silva-00-namespace-fe.yml    (~10 líneas)
├── jhon-silva-00-secret-fe.yml       (~10 líneas)
├── jhon-silva-00-service-fe.yml      (~20 líneas)
└── jhon-silva-00-deployment-fe.yml   (~50 líneas)
```

**Total**: ~90 líneas de YAML para desplegar el frontend en Kubernetes.

---

## 📊 ESTADÍSTICAS DEL PROYECTO

### Backend:

| Tipo | Cantidad | Líneas aprox |
|------|----------|--------------|
| Archivos Java | 6 | ~500 |
| Archivos YAML (config) | 2 | ~50 |
| Archivos K8s | 4 | ~115 |
| Dockerfile | 1 | ~25 |
| **Total** | **13** | **~690** |

### Frontend:

| Tipo | Cantidad | Líneas aprox |
|------|----------|--------------|
| Archivos TypeScript | 3 | ~190 |
| Archivos HTML | 1 | ~150 |
| Archivos SCSS | 2 | ~100 |
| Archivos K8s | 4 | ~90 |
| Dockerfile | 1 | ~25 |
| nginx.conf | 1 | ~20 |
| **Total** | **12** | **~575** |

### Documentación:

| Archivo | Líneas aprox |
|---------|--------------|
| Base64 y Secrets | ~350 |
| MetalLB Config | ~400 |
| Iniciar Servicios | ~450 |
| K8s Backend | ~800 |
| K8s Frontend | ~700 |
| Guía Ejecución | ~500 |
| Estructura Archivos | ~600 |
| **Total** | **~3800** |

---

## 🎓 RESUMEN

### Total de archivos importantes:
- **Backend**: 13 archivos
- **Frontend**: 12 archivos
- **Configuración**: 2 archivos (metallb-config.yaml, iniciar-servicios.bat)
- **Documentación**: 7 archivos MD

### Líneas de código:
- **Backend**: ~690 líneas
- **Frontend**: ~575 líneas
- **Documentación**: ~3800 líneas

**Todo organizado y documentado mano!** 📁✨
