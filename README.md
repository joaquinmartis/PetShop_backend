# 🐾 VirtualPet - E-commerce Backend

Sistema backend para tienda de productos para mascotas, desarrollado con arquitectura de monolito modular.

## 📋 Tabla de Contenidos

- [Tecnologías](#-tecnologías)
- [Arquitectura](#-arquitectura)
- [Estructura de Módulos](#-estructura-de-módulos)
- [Instalación y Configuración](#-instalación-y-configuración)
- [API Endpoints](#-api-endpoints)
- [Base de Datos](#-base-de-datos)
- [Seguridad](#-seguridad)

## 🛠 Tecnologías

- **Java 17**
- **Spring Boot 3.5.7**
- **Spring Security** (JWT Authentication)
- **Spring Data JPA**
- **PostgreSQL 14+**
- **Maven**
- **Brevo API** (Email notifications)
- **Telegram Bot API** (Telegram notifications)

## 🏗 Arquitectura

### Monolito Modular

El sistema está organizado como un **monolito modular** donde cada módulo es independiente y responsable de su propio dominio de negocio. Los módulos se comunican entre sí **únicamente a través de sus servicios**, nunca accediendo directamente a las tablas de otros módulos.

```
┌─────────────────────────────────────────────────────────┐
│                    VirtualPet Backend                    │
│                    (Monolito Modular)                    │
├─────────────┬─────────────┬─────────────┬──────────────┤
│   User      │   Product   │    Order    │   Cart       │
│   Module    │   Module    │    Module   │   Module     │
│             │             │             │              │
│   Notification Module                                   │
└─────────────────────────────────────────────────────────┘
```

### Arquitectura en Capas

Cada módulo sigue el patrón de **arquitectura en 3 capas**:

```
┌──────────────────┐
│   Controller     │  ← Expone endpoints REST, maneja requests/responses
├──────────────────┤
│    Service       │  ← Lógica de negocio, validaciones, orquestación
├──────────────────┤
│   Repository     │  ← Acceso a datos (JPA/Hibernate)
├──────────────────┤
│    Entity        │  ← Mapeo a tablas de BD
└──────────────────┘
```

**Principios clave:**
- ✅ **Controller**: Solo maneja HTTP (requests, responses, status codes)
- ✅ **Service**: Toda la lógica de negocio y validaciones
- ✅ **Repository**: Solo queries a base de datos
- ✅ **Aislamiento**: Un módulo NUNCA accede directamente a repositories de otros módulos

## 📦 Estructura de Módulos

### 1️⃣ User Module
**Schema BD**: `user_management`

Gestiona usuarios, autenticación y roles.

**Entidades**: `User`, `Role`

**Endpoints principales**:
- `POST /api/auth/register` - Registro de usuario
- `POST /api/auth/login` - Login (devuelve JWT)
- `GET /api/users/me` - Perfil del usuario actual
- `PUT /api/users/me` - Actualizar perfil

### 2️⃣ Product Module
**Schema BD**: `product_catalog`

Gestiona productos y categorías.

**Entidades**: `Product`, `Category`

**Endpoints principales**:
- `GET /api/products` - Listar productos (paginado, filtros)
- `GET /api/products/{id}` - Detalle de producto
- `GET /api/categories` - Listar categorías
- `POST /api/products` - Crear producto (Empleado BackOffice)

### 3️⃣ Cart Module
**Schema BD**: `shopping_cart`

Gestiona el carrito de compras.

**Entidades**: `Cart`, `CartItem`

**Endpoints principales**:
- `GET /api/cart` - Ver mi carrito
- `POST /api/cart/items` - Agregar producto al carrito
- `PUT /api/cart/items/{id}` - Actualizar cantidad
- `DELETE /api/cart/items/{id}` - Eliminar del carrito
- `DELETE /api/cart/clear` - Vaciar carrito

### 4️⃣ Order Module
**Schema BD**: `order_management`

Gestiona pedidos y su ciclo de vida.

**Entidades**: `Order`, `OrderItem`, `OrderStatus`

**Endpoints principales**:
- `POST /api/orders` - Crear orden desde carrito
- `GET /api/orders` - Listar mis órdenes
- `GET /api/orders/{id}` - Detalle de orden
- `PATCH /api/orders/{id}/status` - Cambiar estado (Empleado BackOffice)

**Estados de orden**: `PENDING` → `CONFIRMED` → `SHIPPED` → `DELIVERED` / `CANCELLED`

### 5️⃣ Notification Module
**Schema BD**: `notification_management`

Gestiona notificaciones multicanal al cliente.

**Entidades**: `NotificationPreference`, `NotificationLog`

**Endpoints principales**:
- `GET /api/notifications/preferences/status` - Ver si tiene preferencias
- `GET /api/notifications/preferences` - Ver mis preferencias
- `PUT /api/notifications/preferences` - Configurar canales
- `GET /api/orders/{orderId}/notifications` - Logs de notificaciones de una orden
- `GET /api/orders/{orderId}/whatsapp-link` - Obtener link de WhatsApp

**Canales soportados**: Email, WhatsApp, SMS (simulado), Telegram

**Trigger**: Se envía notificación automáticamente cuando una orden pasa a estado `SHIPPED`.

## 🚀 Instalación y Configuración

### Prerrequisitos

- Java 17+
- PostgreSQL 14+
- Maven 3.6+

### 1. Clonar repositorio

```bash
git clone <repository-url>
cd PetShop_backend
```

### 2. Configurar Base de Datos

Ejecutar los scripts SQL en orden:

```bash
psql -U postgres -d virtualpet -f scripts/setup/init-database.sql
psql -U postgres -d virtualpet -f scripts/setup/notification-schema.sql
psql -U postgres -d virtualpet -f scripts/setup/grant-notification-permissions.sql
```

### 3. Configurar Variables de Entorno

Crear archivo `application.properties` en `src/main/resources/`:

```properties
# Base de datos
spring.datasource.url=jdbc:postgresql://localhost:5432/virtualpet
spring.datasource.username=virtualpet_user
spring.datasource.password=virtualpet123

# JWT
jwt.secret=tu_secret_key_aqui
jwt.expiration=86400000

# Email (Brevo)
spring.mail.host=smtp-relay.brevo.com
spring.mail.port=587
spring.mail.username=tu_email@dominio.com
spring.mail.password=tu_smtp_key
brevo.api.key=tu_api_key

# Telegram
telegram.bot.token=tu_bot_token
```

### 4. Ejecutar

```bash
mvn clean install
mvn spring-boot:run
```

La aplicación estará disponible en: `http://localhost:8080`

## 📡 API Endpoints

### 🔓 Públicos (sin autenticación)

```
POST   /api/auth/register          - Registrar usuario
POST   /api/auth/login             - Login
GET    /api/products               - Listar productos
GET    /api/products/{id}          - Detalle producto
GET    /api/categories             - Listar categorías
```

### 🔐 Autenticados (requieren JWT)

```
GET    /api/users/me               - Mi perfil
PUT    /api/users/me               - Actualizar perfil
GET    /api/cart                   - Mi carrito
POST   /api/cart/items             - Agregar al carrito
PUT    /api/cart/items/{id}        - Actualizar cantidad
DELETE /api/cart/items/{id}        - Eliminar del carrito
DELETE /api/cart/clear             - Vaciar carrito
POST   /api/orders                 - Crear orden
GET    /api/orders                 - Mis órdenes
GET    /api/orders/{id}            - Detalle de orden
GET    /api/notifications/preferences - Mis preferencias
PUT    /api/notifications/preferences - Configurar notificaciones
```

### 👑 Empleado BackOffice

```
POST   /api/products               - Crear producto
DELETE /api/products/{id}          - Eliminar producto
POST   /api/categories             - Crear categoría
PUT    /api/categories/{id}        - Actualizar categoría
PATCH  /api/orders/{id}/status     - Cambiar estado de orden
GET    /api/orders/{orderId}/notifications - Ver notificaciones enviadas
GET    /api/orders/{orderId}/whatsapp-link - Link de WhatsApp
```

## 🗄 Base de Datos

### Schemas PostgreSQL

El sistema utiliza **schemas separados** para cada módulo:

```
virtualpet (database)
├── user_management
│   ├── users
│   └── roles
├── product_catalog
│   ├── products
│   └── categories
├── shopping_cart
│   ├── carts
│   └── cart_items
├── order_management
│   ├── orders
│   └── order_items
└── notification_management
    ├── notification_preferences
    └── notification_logs
```

**Principio clave**: Un módulo **NUNCA** tiene foreign keys a tablas de otro módulo. La integridad referencial entre módulos se maneja a nivel de aplicación en los servicios.

## 🔐 Seguridad

### Autenticación JWT

- El usuario hace login y recibe un **JWT token**
- El token se envía en cada request como **cookie HTTP-only**
- El token contiene: `userId`, `email`, `role`
- Expiración configurable (default: 24 horas)

### Autorización

El sistema implementa control de acceso basado en roles:

- **USER**: Usuarios normales (comprar, ver sus órdenes)
- **BACKOFFICE**: Empleados BackOffice (gestionar productos, cambiar estados de órdenes)

### CORS

Configurado para aceptar requests desde el frontend. Modificar en `SecurityConfig.java`:

```java
.allowedOrigins("http://localhost:5173") // Frontend local
```

## 📧 Notificaciones

### Configuración de Canales

Los usuarios pueden elegir cómo recibir notificaciones:

- ✅ **Email**: Envío real vía Brevo API
- ✅ **WhatsApp**: Genera link de WhatsApp Web
- ✅ **SMS**: Simulado (log en BD)
- ✅ **Telegram**: Envío real vía Telegram Bot API

### Flujo de Notificación

1. Usuario configura sus preferencias de notificación
2. Cuando una orden pasa a estado `SHIPPED`, el sistema:
   - Lee las preferencias del usuario
   - Envía notificación por cada canal activo
   - Registra resultado en `notification_logs`

## 📝 Documentación API

La documentación interactiva de la API está disponible mediante **Swagger/OpenAPI**:

```
http://localhost:8080/swagger-ui.html
```

## 🧪 Testing

```bash
# Ejecutar todos los tests
mvn test

# Ejecutar solo tests de un módulo
mvn test -Dtest=NotificationServiceTest
```

## 📄 Licencia

Este proyecto es parte de un trabajo académico.

---

**Desarrollado con ❤️ para VirtualPet**

