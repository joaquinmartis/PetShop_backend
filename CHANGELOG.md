# Changelog

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [1.0.0] - 2025-11-06

### ✅ Añadido
- Sistema completo de autenticación JWT
- Módulo de gestión de usuarios (registro, login, perfil)
- Módulo de catálogo de productos con categorías
- Sistema de carrito de compras persistente
- Gestión completa de pedidos (cliente y warehouse)
- Control automático de stock
- Sistema de roles (CLIENT, WAREHOUSE)
- Paginación y filtros en productos
- Búsqueda de productos por nombre
- Estados de pedidos (CONFIRMED, READY_TO_SHIP, SHIPPED, DELIVERED, CANCELLED)
- Restauración automática de stock al cancelar pedidos
- Documentación Swagger/OpenAPI completa
- ErrorResponse estandarizado
- Suite completa de testing (100+ tests)
- Documentación de arquitectura C4
- Colección Postman

### 🔒 Seguridad
- Passwords hasheados con BCrypt
- Protección de endpoints con JWT
- Validación de roles por endpoint
- Validación de entrada en todos los DTOs

### 📚 Documentación
- README completo con ejemplos
- Documentación de arquitectura
- Guías de testing
- Reportes de cobertura
- Diagramas C4

### 🧪 Testing
- Tests exhaustivos por módulo
- Tests E2E de flujo completo
- Tests de validación de campos
- Tests de seguridad
- Cobertura: ~95%

### 🔧 Técnico
- Java 21
- Spring Boot 3.5.7
- PostgreSQL 14
- Maven
- JUnit 5

---

## [Unreleased]

### 🚀 Por Venir
- Integración con pasarelas de pago
- Sistema de notificaciones por email
- Dashboard de administración
- Métricas y monitoring
- Caché con Redis
- Containerización con Docker
- CI/CD pipeline

---

## Tipos de cambios
- `Añadido` para funcionalidades nuevas
- `Cambiado` para cambios en funcionalidades existentes
- `Deprecado` para funcionalidades que pronto se eliminarán
- `Eliminado` para funcionalidades eliminadas
- `Corregido` para corrección de bugs
- `Seguridad` en caso de vulnerabilidades

