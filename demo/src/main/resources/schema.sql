DROP TABLE IF EXISTS users CASCADE;

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

-- Datos de prueba
INSERT INTO users (username, email, first_name, last_name, phone, address, status) VALUES 
('jperez', 'juan.perez@example.com', 'Juan', 'Pérez', '+51-987-654-321', 'Av. Arequipa 123, Lima', 'ACTIVE'),
('mgarcia', 'maria.garcia@example.com', 'María', 'García', '+51-987-654-322', 'Calle Los Olivos 456, Arequipa', 'ACTIVE'),
('plopez', 'pedro.lopez@example.com', 'Pedro', 'López', '+51-987-654-323', 'Jr. Puno 789, Cusco', 'INACTIVE')
ON CONFLICT (username) DO NOTHING;

