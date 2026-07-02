# 🚀 Setup de Base de Datos Neon

## ⚠️ IMPORTANTE: Ejecuta este script en tu dashboard de Neon

### Paso 1: Ir al Dashboard de Neon
1. Ve a: https://console.neon.tech
2. Selecciona tu proyecto (debe ser el que tiene el endpoint `ep-rough-violet-adi6ri0k`)
3. Ve a la sección **SQL Editor**

### Paso 2: Ejecutar el Script SQL

Copia y pega este script COMPLETO en el SQL Editor de Neon:

```sql
-- ============================================
-- SETUP COMPLETO DE LA BASE DE DATOS
-- ============================================

-- Eliminar tabla si existe
DROP TABLE IF EXISTS users CASCADE;

-- Crear tabla con 10 campos
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    address VARCHAR(255),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar búsquedas
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

-- Datos de prueba (3 usuarios iniciales)
INSERT INTO users (username, email, first_name, last_name, phone, address, status) VALUES 
('jperez', 'juan.perez@example.com', 'Juan', 'Pérez', '+51-987-654-321', 'Av. Arequipa 123, Lima', 'ACTIVE'),
('mgarcia', 'maria.garcia@example.com', 'María', 'García', '+51-987-654-322', 'Calle Los Olivos 456, Arequipa', 'ACTIVE'),
('plopez', 'pedro.lopez@example.com', 'Pedro', 'López', '+51-987-654-323', 'Jr. Puno 789, Cusco', 'INACTIVE')
ON CONFLICT (username) DO NOTHING;

-- Verificar que se creó correctamente
SELECT 'Tabla creada exitosamente!' as mensaje;
SELECT COUNT(*) as total_usuarios FROM users;
SELECT * FROM users;
```

### Paso 3: Ejecutar

1. Haz clic en **Run** o presiona `Ctrl+Enter`
2. Deberías ver:
   - ✅ Mensaje: "Tabla creada exitosamente!"
   - ✅ Total usuarios: 3
   - ✅ Lista de 3 usuarios

### Paso 4: Verificar

```sql
-- Ver estructura de la tabla
\d users

-- Ver todos los usuarios
SELECT * FROM users;

-- Ver índices
\di

-- Contar usuarios por estado
SELECT status, COUNT(*) FROM users GROUP BY status;
```

---

## ✅ Verificación Completa

Ejecuta esto para asegurarte que todo está bien:

```sql
-- 1. Verificar que existen 10 columnas
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;

-- 2. Verificar datos de prueba
SELECT 
    id, 
    username, 
    email, 
    first_name || ' ' || last_name as nombre_completo,
    status,
    created_at
FROM users;

-- 3. Probar búsqueda (debe retornar Juan Pérez)
SELECT * FROM users WHERE first_name ILIKE '%juan%';

-- 4. Verificar estados
SELECT DISTINCT status FROM users;
```

---

## 🎯 Resultado Esperado

Deberías tener:
- ✅ Tabla `users` con 10 columnas
- ✅ 3 índices (email, username, status)
- ✅ 3 usuarios de prueba
- ✅ 2 usuarios ACTIVE, 1 INACTIVE

---

## 🚨 Troubleshooting

### Error: "relation users already exists"
```sql
-- Elimina la tabla y vuelve a ejecutar
DROP TABLE IF EXISTS users CASCADE;
-- Luego ejecuta el script completo de nuevo
```

### Error: "duplicate key value violates unique constraint"
```sql
-- Ya existen usuarios, elimina los datos
TRUNCATE TABLE users RESTART IDENTITY CASCADE;
-- Luego ejecuta solo los INSERT
```

### Quiero empezar de cero
```sql
DROP TABLE IF EXISTS users CASCADE;
-- Luego ejecuta el script completo desde el inicio
```

---

## ✨ Una vez completado

Tu base de datos en Neon estará lista para recibir conexiones desde:
- ✅ Backend local (`./mvnw spring-boot:run`)
- ✅ Backend en Docker (`docker-compose up`)
- ✅ Postman/curl (pruebas de API)

---

**¡Listo mano! Tu BD en la nube está configurada 🎉**
