-- Script SQL para crear usuario de prueba
-- Este usuario se usará para probar el módulo Cart

-- Insertar usuario de prueba (si no existe)
INSERT INTO user_management.users (
    email,
    password_hash,
    first_name,
    last_name,
    phone,
    address,
    role_id,
    is_active,
    created_at,
    updated_at
)
SELECT
    'cliente@test.com',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIKUn6V3yK', -- password: password123
    'Cliente',
    'Test',
    '2234567890',
    'Calle Falsa 123, Mar del Plata',
    (SELECT id FROM user_management.roles WHERE name = 'CLIENT'),
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1 FROM user_management.users WHERE email = 'cliente@test.com'
);

-- Verificar que se creó correctamente
SELECT
    id,
    email,
    first_name,
    last_name,
    (SELECT name FROM user_management.roles WHERE id = role_id) as role
FROM user_management.users
WHERE email = 'cliente@test.com';

