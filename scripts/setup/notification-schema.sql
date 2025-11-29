-- ============================================
-- SCHEMA DE NOTIFICACIONES - VIRTUALPET
-- ============================================
-- Fecha: 2025-11-27
-- Propósito: Sistema de notificaciones multi-canal para pedidos entregados
-- Arquitectura: Monolito Modular (sin FK a otros módulos)
-- ============================================

-- --------------------------------------------
-- 1. CREAR SCHEMA
-- --------------------------------------------
CREATE SCHEMA IF NOT EXISTS notification_management;

-- --------------------------------------------
-- 2. TABLA: notification_preferences
-- --------------------------------------------
-- Almacena las preferencias de notificación de cada usuario
-- NOTA: No hay FK a user_management.users para mantener independencia modular
-- La integridad se mantiene a nivel de aplicación (service layer)

CREATE TABLE notification_management.notification_preferences (
    id BIGSERIAL PRIMARY KEY,

    -- Identificador del usuario (sin FK por arquitectura modular)
    user_id BIGINT NOT NULL UNIQUE,

    -- Canales de notificación
    email_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    whatsapp_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    whatsapp_number VARCHAR(20),

    telegram_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    telegram_chat_id VARCHAR(100),

    sms_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    sms_number VARCHAR(20),

    -- Auditoría
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para optimizar consultas
CREATE INDEX idx_notification_preferences_user_id
    ON notification_management.notification_preferences(user_id);

-- Comentarios para documentación
COMMENT ON TABLE notification_management.notification_preferences IS
    'Preferencias de notificación por usuario. Sin FK a users por arquitectura modular.';

COMMENT ON COLUMN notification_management.notification_preferences.user_id IS
    'ID del usuario (relación lógica con user_management.users sin FK física)';

COMMENT ON COLUMN notification_management.notification_preferences.email_enabled IS
    'Si el usuario quiere recibir notificaciones por email';

COMMENT ON COLUMN notification_management.notification_preferences.whatsapp_enabled IS
    'Si el usuario quiere recibir notificaciones por WhatsApp';

COMMENT ON COLUMN notification_management.notification_preferences.whatsapp_number IS
    'Número de teléfono para WhatsApp (formato internacional, ej: +5491112345678)';

COMMENT ON COLUMN notification_management.notification_preferences.telegram_enabled IS
    'Si el usuario quiere recibir notificaciones por Telegram';

COMMENT ON COLUMN notification_management.notification_preferences.telegram_chat_id IS
    'Chat ID de Telegram del usuario (obtenido del bot)';

COMMENT ON COLUMN notification_management.notification_preferences.sms_enabled IS
    'Si el usuario quiere recibir notificaciones por SMS';

COMMENT ON COLUMN notification_management.notification_preferences.sms_number IS
    'Número de teléfono para SMS (formato internacional)';

-- --------------------------------------------
-- 3. TABLA: notification_logs
-- --------------------------------------------
-- Almacena el historial de todas las notificaciones enviadas
-- Útil para auditoría, debugging y estadísticas
-- NOTA: Sin FK a users ni orders por arquitectura modular

CREATE TABLE notification_management.notification_logs (
    id BIGSERIAL PRIMARY KEY,

    -- Identificadores (sin FK por arquitectura modular)
    user_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL,

    -- Información de la notificación
    channel VARCHAR(20) NOT NULL,  -- EMAIL, WHATSAPP, TELEGRAM, SMS
    status VARCHAR(20) NOT NULL,   -- SENT, FAILED

    -- Contenido
    message TEXT,
    error_detail TEXT,

    -- Metadatos adicionales (opcional)
    recipient VARCHAR(255),  -- Email, teléfono, chat_id utilizado

    -- Auditoría
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para consultas frecuentes
CREATE INDEX idx_notification_logs_user_id
    ON notification_management.notification_logs(user_id);

CREATE INDEX idx_notification_logs_order_id
    ON notification_management.notification_logs(order_id);

CREATE INDEX idx_notification_logs_channel
    ON notification_management.notification_logs(channel);

CREATE INDEX idx_notification_logs_status
    ON notification_management.notification_logs(status);

CREATE INDEX idx_notification_logs_sent_at
    ON notification_management.notification_logs(sent_at DESC);

-- Comentarios para documentación
COMMENT ON TABLE notification_management.notification_logs IS
    'Historial de notificaciones enviadas. Sin FK por arquitectura modular.';

COMMENT ON COLUMN notification_management.notification_logs.user_id IS
    'ID del usuario (relación lógica con user_management.users sin FK física)';

COMMENT ON COLUMN notification_management.notification_logs.order_id IS
    'ID del pedido (relación lógica con order_management.orders sin FK física)';

COMMENT ON COLUMN notification_management.notification_logs.channel IS
    'Canal de notificación: EMAIL, WHATSAPP, TELEGRAM, SMS';

COMMENT ON COLUMN notification_management.notification_logs.status IS
    'Estado del envío: SENT (exitoso), FAILED (fallido)';

COMMENT ON COLUMN notification_management.notification_logs.message IS
    'Mensaje enviado o link generado';

COMMENT ON COLUMN notification_management.notification_logs.error_detail IS
    'Detalle del error si el envío falló';

COMMENT ON COLUMN notification_management.notification_logs.recipient IS
    'Destinatario específico (email, teléfono, chat_id)';

-- --------------------------------------------
-- 4. TRIGGERS PARA UPDATED_AT
-- --------------------------------------------
-- Actualiza automáticamente la columna updated_at

CREATE OR REPLACE FUNCTION notification_management.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notification_preferences_updated_at
    BEFORE UPDATE ON notification_management.notification_preferences
    FOR EACH ROW
    EXECUTE FUNCTION notification_management.update_updated_at_column();

-- --------------------------------------------
-- 5. DATOS DE PRUEBA (OPCIONAL)
-- --------------------------------------------
-- Descomentar si quieres insertar datos de prueba

/*
-- Ejemplo: Usuario con ID 1 habilita email y WhatsApp
INSERT INTO notification_management.notification_preferences
    (user_id, email_enabled, whatsapp_enabled, whatsapp_number)
VALUES
    (1, TRUE, TRUE, '+5491112345678');

-- Ejemplo: Usuario con ID 2 solo habilita email
INSERT INTO notification_management.notification_preferences
    (user_id, email_enabled)
VALUES
    (2, TRUE);

-- Ejemplo: Usuario con ID 3 habilita todos los canales
INSERT INTO notification_management.notification_preferences
    (user_id, email_enabled, whatsapp_enabled, whatsapp_number,
     telegram_enabled, telegram_chat_id, sms_enabled, sms_number)
VALUES
    (3, TRUE, TRUE, '+5491123456789',
     TRUE, '123456789', TRUE, '+5491123456789');

-- Ejemplo: Log de notificación exitosa
INSERT INTO notification_management.notification_logs
    (user_id, order_id, channel, status, message, recipient)
VALUES
    (1, 100, 'EMAIL', 'SENT',
     'Hola Juan, desde VirtualPet te contamos que en el día de hoy...',
     'cliente@email.com');

-- Ejemplo: Log de notificación fallida
INSERT INTO notification_management.notification_logs
    (user_id, order_id, channel, status, message, error_detail, recipient)
VALUES
    (2, 101, 'SMS', 'FAILED',
     'Hola María, desde VirtualPet...',
     'Proveedor SMS no configurado',
     '+5491198765432');
*/
