-- ============================================
-- CREAR USUARIOS DE PRUEBA
-- ============================================

-- Conectar a la base de datos virtualpet
\c virtualpet

-- Verificar si existen los usuarios
DO $$
BEGIN
    -- Usuario regular: user1
    IF NOT EXISTS (SELECT 1 FROM user_management.users WHERE username = 'user1') THEN
        INSERT INTO user_management.users (username, password, email, first_name, last_name, phone, role, enabled, created_at, updated_at)
        VALUES (
            'user1',
            '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- password123
            'user1@test.com',
            'Juan',
            'Pérez',
            '+543515551234',
            'USER',
            true,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        RAISE NOTICE 'Usuario user1 creado exitosamente';
    ELSE
        RAISE NOTICE 'Usuario user1 ya existe';
    END IF;

    -- Usuario admin: admin
    IF NOT EXISTS (SELECT 1 FROM user_management.users WHERE username = 'admin') THEN
        INSERT INTO user_management.users (username, password, email, first_name, last_name, phone, role, enabled, created_at, updated_at)
        VALUES (
            'admin',
            '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- admin123
            'admin@virtualpet.com',
            'Admin',
            'VirtualPet',
            '+543515559999',
            'ADMIN',
            true,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        RAISE NOTICE 'Usuario admin creado exitosamente';
    ELSE
        RAISE NOTICE 'Usuario admin ya existe';
    END IF;

    -- Usuario adicional para pruebas: user2
    IF NOT EXISTS (SELECT 1 FROM user_management.users WHERE username = 'user2') THEN
        INSERT INTO user_management.users (username, password, email, first_name, last_name, phone, role, enabled, created_at, updated_at)
        VALUES (
            'user2',
            '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- password123
            'user2@test.com',
            'María',
            'González',
            '+543515555678',
            'USER',
            true,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        RAISE NOTICE 'Usuario user2 creado exitosamente';
    ELSE
        RAISE NOTICE 'Usuario user2 ya existe';
    END IF;
END
$$;

-- Verificar productos (necesarios para crear órdenes)
DO $$
BEGIN
    -- Verificar si hay productos
    IF NOT EXISTS (SELECT 1 FROM product_management.products LIMIT 1) THEN
        -- Crear algunos productos de prueba
        INSERT INTO product_management.products (name, description, price, stock, image_url, category, enabled, created_at, updated_at)
        VALUES
            ('Alimento para perros Premium', 'Alimento balanceado premium para perros adultos 15kg', 29.99, 100, 'https://example.com/dog-food.jpg', 'Alimentos', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
            ('Juguete para gatos', 'Ratón de peluche con hierba gatera', 9.99, 50, 'https://example.com/cat-toy.jpg', 'Juguetes', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
            ('Collar antipulgas', 'Collar antipulgas para perros y gatos', 19.99, 75, 'https://example.com/collar.jpg', 'Accesorios', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

        RAISE NOTICE 'Productos de prueba creados';
    ELSE
        RAISE NOTICE 'Ya existen productos en la base de datos';
    END IF;
END
$$;

-- Mostrar usuarios creados
SELECT id, username, email, first_name, last_name, role
FROM user_management.users
WHERE username IN ('user1', 'admin', 'user2')
ORDER BY username;

-- Mostrar productos disponibles
SELECT id, name, price, stock
FROM product_management.products
LIMIT 5;

RAISE NOTICE '============================================';
RAISE NOTICE 'USUARIOS DE PRUEBA CREADOS';
RAISE NOTICE '============================================';
RAISE NOTICE 'user1 / password123 (USER)';
RAISE NOTICE 'admin / admin123 (ADMIN)';
RAISE NOTICE 'user2 / password123 (USER)';
RAISE NOTICE '============================================';

