-- ============================================
-- OTORGAR PERMISOS AL SCHEMA notification_management
-- ============================================

-- Conectar a la base de datos virtualpet
\c virtualpet

-- 1. Otorgar permisos de USAGE en el schema (permite acceder al schema)
GRANT USAGE ON SCHEMA notification_management TO postgres;
GRANT USAGE ON SCHEMA notification_management TO PUBLIC;

-- 2. Otorgar permisos sobre TODAS las tablas actuales
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA notification_management TO postgres;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA notification_management TO PUBLIC;

-- 3. Otorgar permisos sobre TODAS las secuencias (para IDs autoincrementales)
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA notification_management TO postgres;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA notification_management TO PUBLIC;

-- 4. Otorgar permisos por defecto para tablas futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA notification_management
GRANT ALL PRIVILEGES ON TABLES TO postgres;

ALTER DEFAULT PRIVILEGES IN SCHEMA notification_management
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO PUBLIC;

-- 5. Otorgar permisos por defecto para secuencias futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA notification_management
GRANT ALL PRIVILEGES ON SEQUENCES TO postgres;

ALTER DEFAULT PRIVILEGES IN SCHEMA notification_management
GRANT USAGE, SELECT ON SEQUENCES TO PUBLIC;

-- 6. Verificar permisos
\dn+ notification_management

-- 7. Verificar permisos de las tablas
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'notification_management';

-- Mostrar mensaje de confirmación
\echo '============================================'
\echo 'PERMISOS OTORGADOS AL SCHEMA notification_management'
\echo '============================================'

