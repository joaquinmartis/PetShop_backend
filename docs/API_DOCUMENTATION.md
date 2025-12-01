# 📚 API Documentation - VirtualPet E-Commerce Backend

**Version:** 1.0.0  
**Base URL:** `https://petshop-cloud.rj.r.appspot.com` (Producción) | `http://localhost:8080` (Desarrollo)  
**Protocolo:** HTTPS/HTTP  
**Formato:** JSON

### 📖 Documentación Interactiva (Swagger UI)

**Producción:**
- 🌐 **Swagger UI:** https://petshop-cloud.rj.r.appspot.com/swagger-ui/index.html
- 📄 **OpenAPI JSON:** https://petshop-cloud.rj.r.appspot.com/v3/api-docs

**Local:**
- 🌐 **Swagger UI:** http://localhost:8080/swagger-ui.html
- 📄 **OpenAPI JSON:** http://localhost:8080/v3/api-docs

---

## 📋 Tabla de Contenidos

1. [Documentación Interactiva (Swagger)](#-documentación-interactiva-swagger)
2. [Autenticación](#-autenticación)
3. [Módulo de Usuarios](#-módulo-de-usuarios)
4. [Módulo de Productos](#%EF%B8%8F-módulo-de-productos)
5. [Módulo de Carrito](#-módulo-de-carrito)
6. [Módulo de Pedidos](#-módulo-de-pedidos)
7. [Módulo de Notificaciones](#-módulo-de-notificaciones)
8. [Códigos de Estado HTTP](#-códigos-de-estado-http)
9. [Modelos de Datos](#-modelos-de-datos)

---

## 📖 Documentación Interactiva (Swagger)

La API cuenta con documentación interactiva completa mediante **Swagger UI** (OpenAPI 3.0), donde puedes explorar y probar todos los endpoints directamente desde el navegador.

### 🌐 Acceder a Swagger UI

#### **Producción (GCP App Engine):**
```
https://petshop-cloud.rj.r.appspot.com/swagger-ui/index.html
```

#### **Desarrollo Local:**
```
http://localhost:8080/swagger-ui.html
```

### 📄 OpenAPI Specification (JSON)

Si necesitas el descriptor OpenAPI en formato JSON para importar en herramientas como **Postman**, **Insomnia** o generar clientes automáticamente:

#### **Producción:**
```
https://petshop-cloud.rj.r.appspot.com/v3/api-docs
```

#### **Desarrollo Local:**
```
http://localhost:8080/v3/api-docs
```

### 🚀 Cómo usar Swagger UI

#### **1. Abrir Swagger UI**
Accede a la URL de Swagger UI en tu navegador.

#### **2. Explorar Endpoints**
Los endpoints están organizados por módulos:
- **User Management** - Gestión de usuarios y autenticación
- **Product Catalog** - Catálogo de productos
- **Categories** - Gestión de categorías
- **Cart** - Carrito de compras
- **Orders - Client** - Pedidos del cliente
- **Orders - Backoffice** - Gestión de pedidos (empleados)
- **Notification Preferences** - Preferencias de notificación
- **Notifications - Backoffice** - Logs de notificaciones

#### **3. Seleccionar Servidor**
En la parte superior, verás un dropdown para seleccionar el servidor:
- **Servidor de producción (GCP App Engine)** - `https://petshop-cloud.rj.r.appspot.com`
- **Servidor de desarrollo local** - `http://localhost:8080`

#### **4. Probar Endpoints Sin Autenticación**
Los endpoints públicos pueden probarse directamente:
- Expandir el endpoint (ej: `GET /api/products`)
- Clic en **"Try it out"**
- Completar los parámetros si los hay
- Clic en **"Execute"**
- Ver la respuesta en tiempo real

#### **5. Autenticarse para Endpoints Protegidos**

Para endpoints que requieren autenticación:

**Paso 1:** Hacer login
- Expandir **User Management**
- Abrir `POST /api/auth/login`
- Clic en **"Try it out"**
- Ingresar credenciales:
  ```json
  {
    "email": "usuario@email.com",
    "password": "contraseña"
  }
  ```
- Clic en **"Execute"**
- Copiar el token JWT de la respuesta o de las cookies del navegador

**Paso 2:** Autorizar con JWT
- Clic en el botón **"Authorize"** 🔒 (esquina superior derecha)
- En el campo "Value", pegar: `Bearer {tu-token-jwt}`
- Clic en **"Authorize"**
- Clic en **"Close"**

**Paso 3:** Probar endpoints protegidos
Ahora todos los requests incluirán automáticamente el token JWT en el header `Authorization`.

#### **6. Ver Modelos de Datos**
Al final de la página de Swagger, encontrarás la sección **"Schemas"** con todos los modelos de datos (DTOs y entidades) documentados.

### 📥 Importar OpenAPI en Postman

1. Abrir Postman
2. Clic en **"Import"**
3. Seleccionar **"Link"**
4. Pegar: `https://petshop-cloud.rj.r.appspot.com/v3/api-docs`
5. Clic en **"Continue"** y luego **"Import"**

Postman creará automáticamente una colección con todos los endpoints de la API.

### 💡 Ventajas de Swagger UI

- ✅ **Documentación siempre actualizada** - Se genera automáticamente del código
- ✅ **Pruebas en vivo** - Ejecutar requests sin herramientas externas
- ✅ **Ejemplos incluidos** - Request y response bodies de ejemplo
- ✅ **Autenticación integrada** - Soporte para JWT Bearer tokens
- ✅ **Exploración interactiva** - Ver todos los endpoints organizados
- ✅ **Sin instalación** - Funciona directamente en el navegador

---

## 🔐 Autenticación

La API utiliza **JWT (JSON Web Tokens)** para la autenticación. El token se envía en las **cookies** con el nombre `authToken`.

### Flujo de Autenticación

1. El cliente hace login en `/api/auth/login`
2. El servidor responde con una cookie `HttpOnly` que contiene el JWT
3. El navegador envía automáticamente la cookie en cada request subsecuente
4. El token expira después de 1 hora (configurable)

### Headers Requeridos

Para endpoints protegidos, el navegador envía automáticamente:
```
Cookie: authToken=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 👤 Módulo de Usuarios

### 1. Registro de Usuario

**Endpoint:** `POST /api/auth/register`  
**Autenticación:** No requerida  
**Descripción:** Crea una nueva cuenta de usuario

#### Request Body
```json
{
  "firstName": "Juan",
  "lastName": "Pérez",
  "email": "juan.perez@email.com",
  "password": "MiPassword123",
  "phone": "+5493515551234",
  "address": "Av. Colón 1234, Córdoba"
}
```

#### Response (201 Created)
```json
{
  "id": 1,
  "firstName": "Juan",
  "lastName": "Pérez",
  "email": "juan.perez@email.com",
  "phone": "+5493515551234",
  "address": "Av. Colón 1234, Córdoba",
  "role": "CUSTOMER",
  "isActive": true,
  "createdAt": "2025-12-01T10:30:00"
}
```

#### Errores Comunes
- `400 Bad Request`: Email ya registrado
- `400 Bad Request`: Datos inválidos

---

### 2. Login

**Endpoint:** `POST /api/auth/login`  
**Autenticación:** No requerida  
**Descripción:** Inicia sesión y recibe un JWT en una cookie HttpOnly

#### Request Body
```json
{
  "email": "juan.perez@email.com",
  "password": "MiPassword123"
}
```

#### Response (200 OK)
```json
{
  "message": "Login exitoso",
  "user": {
    "id": 1,
    "firstName": "Juan",
    "lastName": "Pérez",
    "email": "juan.perez@email.com",
    "role": "CUSTOMER"
  }
}
```

**Cookie enviada:**
```
Set-Cookie: authToken=eyJhbGc...; HttpOnly; Secure; SameSite=None; Max-Age=3600
```

#### Errores Comunes
- `401 Unauthorized`: Credenciales inválidas
- `403 Forbidden`: Usuario desactivado

---

### 3. Obtener Perfil

**Endpoint:** `GET /api/users/me`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Obtiene el perfil del usuario autenticado

#### Response (200 OK)
```json
{
  "id": 1,
  "firstName": "Juan",
  "lastName": "Pérez",
  "email": "juan.perez@email.com",
  "phone": "+5493515551234",
  "address": "Av. Colón 1234, Córdoba",
  "role": "CUSTOMER",
  "isActive": true,
  "createdAt": "2025-12-01T10:30:00"
}
```

---

### 4. Actualizar Perfil

**Endpoint:** `PUT /api/users/me`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Actualiza los datos del perfil del usuario

#### Request Body
```json
{
  "firstName": "Juan Carlos",
  "lastName": "Pérez García",
  "phone": "+5493515559999",
  "address": "Nueva Dirección 456"
}
```

#### Response (200 OK)
```json
{
  "id": 1,
  "firstName": "Juan Carlos",
  "lastName": "Pérez García",
  "email": "juan.perez@email.com",
  "phone": "+5493515559999",
  "address": "Nueva Dirección 456",
  "role": "CUSTOMER",
  "isActive": true
}
```

---

### 5. Logout

**Endpoint:** `POST /api/auth/logout`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Cierra la sesión del usuario

#### Response (200 OK)
```json
{
  "message": "Logout exitoso"
}
```

**Cookie eliminada:**
```
Set-Cookie: authToken=; Max-Age=0
```

---

## 🛍️ Módulo de Productos

### 1. Listar Productos

**Endpoint:** `GET /api/products`  
**Autenticación:** No requerida  
**Descripción:** Lista productos con paginación, ordenamiento y filtros

#### Query Parameters
| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `page` | Integer | No | 0 | Número de página (0-based) |
| `size` | Integer | No | 10 | Tamaño de página |
| `sort` | String | No | `name,asc` | Campo y dirección de ordenamiento |
| `categoryId` | Long | No | - | Filtrar por categoría |
| `inStock` | Boolean | No | - | Solo productos en stock |

#### Ejemplos de Uso
```
GET /api/products?page=0&size=20
GET /api/products?categoryId=1&inStock=true
GET /api/products?sort=price,desc
```

#### Response (200 OK)
```json
{
  "content": [
    {
      "id": 1,
      "name": "Alimento Premium para Perros Adultos 15kg",
      "description": "Alimento balanceado premium para perros adultos...",
      "price": 25000.00,
      "stock": 50,
      "category": {
        "id": 1,
        "name": "Alimentos para perros",
        "description": "Comida balanceada, snacks y premios"
      },
      "imageUrl": "https://example.com/image.jpg",
      "active": true,
      "createdAt": "2025-11-04T11:57:54",
      "updatedAt": "2025-12-01T10:00:00"
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 10,
    "sort": {
      "sorted": true,
      "empty": false,
      "unsorted": false
    }
  },
  "totalPages": 5,
  "totalElements": 47,
  "last": false,
  "first": true,
  "numberOfElements": 10,
  "empty": false
}
```

---

### 2. Obtener Producto por ID

**Endpoint:** `GET /api/products/{id}`  
**Autenticación:** No requerida  
**Descripción:** Obtiene el detalle de un producto específico

#### Response (200 OK)
```json
{
  "id": 1,
  "name": "Alimento Premium para Perros Adultos 15kg",
  "description": "Alimento balanceado premium para perros adultos de todas las razas...",
  "price": 25000.00,
  "stock": 50,
  "category": {
    "id": 1,
    "name": "Alimentos para perros",
    "description": "Comida balanceada, snacks y premios"
  },
  "imageUrl": "https://example.com/image.jpg",
  "active": true,
  "createdAt": "2025-11-04T11:57:54",
  "updatedAt": "2025-12-01T10:00:00"
}
```

#### Errores Comunes
- `404 Not Found`: Producto no encontrado

---

### 3. Crear Producto (BackOffice)

**Endpoint:** `POST /api/products`  
**Autenticación:** Requerida (Rol: WAREHOUSE)  
**Descripción:** Crea un nuevo producto

#### Request Body
```json
{
  "name": "Nuevo Producto",
  "description": "Descripción del producto",
  "price": 15000.00,
  "stock": 100,
  "categoryId": 1,
  "imageUrl": "https://example.com/new-image.jpg",
  "active": true
}
```

#### Response (201 Created)
```json
{
  "id": 15,
  "name": "Nuevo Producto",
  "description": "Descripción del producto",
  "price": 15000.00,
  "stock": 100,
  "category": {
    "id": 1,
    "name": "Alimentos para perros"
  },
  "imageUrl": "https://example.com/new-image.jpg",
  "active": true,
  "createdAt": "2025-12-01T11:00:00"
}
```

---

### 4. Listar Categorías

**Endpoint:** `GET /api/categories`  
**Autenticación:** No requerida  
**Descripción:** Lista todas las categorías activas

#### Response (200 OK)
```json
[
  {
    "id": 1,
    "name": "Alimentos para perros",
    "description": "Comida balanceada, snacks y premios para perros",
    "active": true,
    "createdAt": "2025-11-04T11:57:43",
    "updatedAt": "2025-11-04T11:57:43"
  },
  {
    "id": 2,
    "name": "Alimentos para gatos",
    "description": "Comida balanceada, snacks y premios para gatos",
    "active": true,
    "createdAt": "2025-11-04T11:57:43",
    "updatedAt": "2025-11-04T11:57:43"
  }
]
```

---

## 🛒 Módulo de Carrito

### 1. Obtener Mi Carrito

**Endpoint:** `GET /api/cart`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Obtiene el carrito del usuario autenticado

#### Response (200 OK)
```json
{
  "id": 1,
  "userId": 1,
  "items": [
    {
      "id": 1,
      "product": {
        "id": 5,
        "name": "Alimento en Escamas para Peces Tropicales 100g",
        "price": 2500.00,
        "imageUrl": "https://example.com/image.jpg"
      },
      "quantity": 2,
      "subtotal": 5000.00
    }
  ],
  "totalItems": 2,
  "totalAmount": 5000.00,
  "createdAt": "2025-12-01T10:00:00",
  "updatedAt": "2025-12-01T10:15:00"
}
```

---

### 2. Agregar Producto al Carrito

**Endpoint:** `POST /api/cart/items`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Agrega un producto al carrito

#### Request Body
```json
{
  "productId": 5,
  "quantity": 2
}
```

#### Response (200 OK)
```json
{
  "id": 1,
  "product": {
    "id": 5,
    "name": "Alimento en Escamas para Peces Tropicales 100g",
    "price": 2500.00,
    "imageUrl": "https://example.com/image.jpg"
  },
  "quantity": 2,
  "subtotal": 5000.00
}
```

#### Errores Comunes
- `400 Bad Request`: Producto no disponible o stock insuficiente
- `404 Not Found`: Producto no encontrado

---

### 3. Actualizar Cantidad

**Endpoint:** `PUT /api/cart/items/{itemId}`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Actualiza la cantidad de un item del carrito

#### Request Body
```json
{
  "quantity": 5
}
```

#### Response (200 OK)
```json
{
  "id": 1,
  "product": {
    "id": 5,
    "name": "Alimento en Escamas para Peces Tropicales 100g",
    "price": 2500.00
  },
  "quantity": 5,
  "subtotal": 12500.00
}
```

---

### 4. Eliminar Item del Carrito

**Endpoint:** `DELETE /api/cart/items/{itemId}`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Elimina un item del carrito

#### Response (200 OK)
```json
{
  "message": "Item eliminado del carrito"
}
```

---

### 5. Vaciar Carrito

**Endpoint:** `DELETE /api/cart/clear`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Elimina todos los items del carrito

#### Response (200 OK)
```json
{
  "message": "Carrito vaciado exitosamente"
}
```

---

## 📦 Módulo de Pedidos

### 1. Crear Pedido

**Endpoint:** `POST /api/orders`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Crea un pedido desde el carrito actual

#### Request Body
```json
{
  "shippingAddress": "Av. Colón 1234, Córdoba Capital, Argentina",
  "paymentMethod": "CREDIT_CARD"
}
```

#### Response (201 Created)
```json
{
  "id": 123,
  "userId": 1,
  "items": [
    {
      "productId": 5,
      "productName": "Alimento en Escamas para Peces Tropicales 100g",
      "quantity": 2,
      "unitPrice": 2500.00,
      "subtotal": 5000.00
    }
  ],
  "totalAmount": 5000.00,
  "status": "PENDING",
  "shippingAddress": "Av. Colón 1234, Córdoba Capital, Argentina",
  "paymentMethod": "CREDIT_CARD",
  "createdAt": "2025-12-01T11:00:00"
}
```

#### Errores Comunes
- `400 Bad Request`: Carrito vacío
- `400 Bad Request`: Stock insuficiente para uno o más productos

---

### 2. Listar Mis Pedidos

**Endpoint:** `GET /api/orders`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Lista los pedidos del usuario autenticado

#### Query Parameters
| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `page` | Integer | No | 0 | Número de página |
| `size` | Integer | No | 10 | Tamaño de página |

#### Response (200 OK)
```json
{
  "content": [
    {
      "id": 123,
      "totalAmount": 5000.00,
      "status": "SHIPPED",
      "shippingAddress": "Av. Colón 1234, Córdoba",
      "createdAt": "2025-12-01T11:00:00",
      "itemCount": 2
    }
  ],
  "totalPages": 1,
  "totalElements": 1
}
```

---

### 3. Obtener Detalle de Pedido

**Endpoint:** `GET /api/orders/{orderId}`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Obtiene el detalle completo de un pedido

#### Response (200 OK)
```json
{
  "id": 123,
  "userId": 1,
  "items": [
    {
      "productId": 5,
      "productName": "Alimento en Escamas para Peces Tropicales 100g",
      "quantity": 2,
      "unitPrice": 2500.00,
      "subtotal": 5000.00
    }
  ],
  "totalAmount": 5000.00,
  "status": "SHIPPED",
  "shippingAddress": "Av. Colón 1234, Córdoba Capital, Argentina",
  "paymentMethod": "CREDIT_CARD",
  "statusHistory": [
    {
      "status": "PENDING",
      "timestamp": "2025-12-01T11:00:00"
    },
    {
      "status": "CONFIRMED",
      "timestamp": "2025-12-01T11:05:00"
    },
    {
      "status": "READY_TO_SHIP",
      "timestamp": "2025-12-01T12:00:00"
    },
    {
      "status": "SHIPPED",
      "timestamp": "2025-12-01T14:00:00",
      "changedBy": "warehouse@virtualpet.com"
    }
  ],
  "createdAt": "2025-12-01T11:00:00",
  "updatedAt": "2025-12-01T14:00:00"
}
```

---

### 4. Cancelar Pedido

**Endpoint:** `PATCH /api/orders/{orderId}/cancel`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Cancela un pedido (solo si está en estado PENDING o CONFIRMED)

#### Response (200 OK)
```json
{
  "id": 123,
  "status": "CANCELLED",
  "message": "Pedido cancelado exitosamente"
}
```

#### Errores Comunes
- `400 Bad Request`: El pedido no puede ser cancelado (ya fue enviado)
- `404 Not Found`: Pedido no encontrado

---

### 5. Listar Todos los Pedidos (BackOffice)

**Endpoint:** `GET /api/backoffice/orders`  
**Autenticación:** Requerida (Rol: WAREHOUSE)  
**Descripción:** Lista todos los pedidos del sistema

#### Query Parameters
| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `page` | Integer | No | 0 | Número de página |
| `size` | Integer | No | 20 | Tamaño de página |
| `status` | String | No | - | Filtrar por estado |

#### Response (200 OK)
```json
{
  "content": [
    {
      "id": 123,
      "userId": 1,
      "customerName": "Juan Pérez",
      "totalAmount": 5000.00,
      "status": "READY_TO_SHIP",
      "shippingAddress": "Av. Colón 1234, Córdoba",
      "createdAt": "2025-12-01T11:00:00",
      "notificationCount": 0
    }
  ],
  "totalPages": 5,
  "totalElements": 95
}
```

---

### 6. Marcar Pedido como Enviado (BackOffice)

**Endpoint:** `PATCH /api/backoffice/orders/{orderId}/ship`  
**Autenticación:** Requerida (Rol: WAREHOUSE)  
**Descripción:** Marca un pedido como enviado y **dispara notificaciones al cliente**

#### Response (200 OK)
```json
{
  "id": 123,
  "status": "SHIPPED",
  "message": "Pedido marcado como enviado y notificaciones enviadas al cliente"
}
```

**⚠️ Importante:** Este endpoint **automáticamente envía notificaciones** al cliente si tiene configuradas sus preferencias de notificación.

---

## 🔔 Módulo de Notificaciones

### 1. Verificar Estado de Preferencias

**Endpoint:** `GET /api/notifications/preferences/status`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Verifica si el usuario tiene preferencias de notificación configuradas

#### Response (200 OK)
```json
{
  "exists": true,
  "preferences": {
    "emailEnabled": true,
    "whatsappEnabled": false,
    "smsEnabled": false,
    "telegramEnabled": false
  }
}
```

**Si no existen preferencias:**
```json
{
  "exists": false,
  "message": "No tienes preferencias configuradas. Usa POST /api/notifications/preferences para crearlas."
}
```

---

### 2. Crear Preferencias de Notificación

**Endpoint:** `POST /api/notifications/preferences`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Crea las preferencias de notificación del usuario

#### Request Body (Opcional - todos los campos opcionales)
```json
{
  "emailEnabled": true,
  "whatsappEnabled": true,
  "whatsappNumber": "+5493515551234",
  "smsEnabled": false,
  "smsNumber": "+5493515551234",
  "telegramEnabled": true,
  "telegramChatId": "123456789"
}
```

**Si se envía body vacío `{}`, se crean preferencias con todos los canales desactivados por defecto.**

#### Response (201 Created)
```json
{
  "id": 1,
  "userId": 1,
  "emailEnabled": true,
  "whatsappEnabled": true,
  "whatsappNumber": "+5493515551234",
  "smsEnabled": false,
  "smsNumber": null,
  "telegramEnabled": true,
  "telegramChatId": "123456789",
  "createdAt": "2025-12-01T11:00:00",
  "updatedAt": "2025-12-01T11:00:00"
}
```

#### Errores Comunes
- `409 Conflict`: El usuario ya tiene preferencias configuradas

---

### 3. Obtener Mis Preferencias

**Endpoint:** `GET /api/notifications/preferences`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Obtiene las preferencias de notificación del usuario

#### Response (200 OK)
```json
{
  "id": 1,
  "userId": 1,
  "emailEnabled": true,
  "whatsappEnabled": true,
  "whatsappNumber": "+5493515551234",
  "smsEnabled": false,
  "smsNumber": null,
  "telegramEnabled": true,
  "telegramChatId": "123456789",
  "createdAt": "2025-12-01T11:00:00",
  "updatedAt": "2025-12-01T11:30:00"
}
```

---

### 4. Actualizar Preferencias

**Endpoint:** `PUT /api/notifications/preferences`  
**Autenticación:** Requerida (Cookie)  
**Descripción:** Actualiza las preferencias de notificación (actualiza solo los campos enviados)

#### Request Body
```json
{
  "emailEnabled": false,
  "whatsappEnabled": true,
  "whatsappNumber": "+5493519999999"
}
```

#### Response (200 OK)
```json
{
  "id": 1,
  "userId": 1,
  "emailEnabled": false,
  "whatsappEnabled": true,
  "whatsappNumber": "+5493519999999",
  "smsEnabled": false,
  "telegramEnabled": true,
  "telegramChatId": "123456789",
  "updatedAt": "2025-12-01T12:00:00"
}
```

---

### 5. Consultar Notificaciones de un Pedido (BackOffice)

**Endpoint:** `GET /api/backoffice/notifications/orders/{orderId}`  
**Autenticación:** Requerida (Rol: WAREHOUSE)  
**Descripción:** Consulta las notificaciones enviadas para un pedido específico

#### Response (200 OK)
```json
[
  {
    "id": 1,
    "channel": "EMAIL",
    "status": "SENT",
    "message": "Hola Juan, desde VirtualPet te contamos que en el día de hoy estarás recibiendo...",
    "recipient": "juan.perez@email.com",
    "sentAt": "2025-12-01T14:00:05",
    "errorDetail": null,
    "whatsappLink": null
  },
  {
    "id": 2,
    "channel": "WHATSAPP",
    "status": "SENT",
    "message": "WhatsApp link generado: https://wa.me/+5493515551234?text=...",
    "recipient": "+5493515551234",
    "sentAt": "2025-12-01T14:00:06",
    "errorDetail": null,
    "whatsappLink": "https://wa.me/+5493515551234?text=Hola+Juan..."
  },
  {
    "id": 3,
    "channel": "TELEGRAM",
    "status": "SENT",
    "message": "Hola Juan, desde VirtualPet te contamos que en el día de hoy...",
    "recipient": "123456789",
    "sentAt": "2025-12-01T14:00:07",
    "errorDetail": null,
    "whatsappLink": null
  }
]
```

**Nota:** El campo `whatsappLink` contiene el link de WhatsApp Web que el empleado de backoffice puede usar para contactar directamente al cliente.

---

## 🔢 Códigos de Estado HTTP

| Código | Descripción | Uso Común |
|--------|-------------|-----------|
| `200 OK` | Solicitud exitosa | GET, PUT, PATCH, DELETE exitosos |
| `201 Created` | Recurso creado exitosamente | POST exitoso |
| `400 Bad Request` | Datos inválidos o lógica de negocio violada | Validación fallida, stock insuficiente |
| `401 Unauthorized` | Token JWT inválido o expirado | Usuario no autenticado |
| `403 Forbidden` | Usuario no tiene permisos | Rol insuficiente (ej: cliente intentando acceder a backoffice) |
| `404 Not Found` | Recurso no encontrado | Producto, pedido o usuario no existe |
| `409 Conflict` | Conflicto con el estado actual | Email ya registrado, preferencias ya existen |
| `500 Internal Server Error` | Error del servidor | Error inesperado en el backend |

---

## 📊 Modelos de Datos

### User
```typescript
{
  id: number
  firstName: string
  lastName: string
  email: string
  phone: string
  address: string
  role: "CUSTOMER" | "WAREHOUSE"
  isActive: boolean
  createdAt: string (ISO 8601)
  updatedAt: string (ISO 8601)
}
```

### Product
```typescript
{
  id: number
  name: string
  description: string
  price: number (decimal)
  stock: number
  category: Category
  imageUrl: string
  active: boolean
  createdAt: string (ISO 8601)
  updatedAt: string (ISO 8601)
}
```

### Category
```typescript
{
  id: number
  name: string
  description: string
  active: boolean
  createdAt: string (ISO 8601)
  updatedAt: string (ISO 8601)
}
```

### Cart
```typescript
{
  id: number
  userId: number
  items: CartItem[]
  totalItems: number
  totalAmount: number (decimal)
  createdAt: string (ISO 8601)
  updatedAt: string (ISO 8601)
}
```

### CartItem
```typescript
{
  id: number
  product: Product
  quantity: number
  subtotal: number (decimal)
}
```

### Order
```typescript
{
  id: number
  userId: number
  items: OrderItem[]
  totalAmount: number (decimal)
  status: OrderStatus
  shippingAddress: string
  paymentMethod: "CREDIT_CARD" | "DEBIT_CARD" | "CASH"
  statusHistory: OrderStatusHistory[]
  createdAt: string (ISO 8601)
  updatedAt: string (ISO 8601)
}
```

### OrderStatus
```typescript
"PENDING" | "CONFIRMED" | "READY_TO_SHIP" | "SHIPPED" | "DELIVERED" | "CANCELLED"
```

**Flujo de estados:**
```
PENDING → CONFIRMED → READY_TO_SHIP → SHIPPED → DELIVERED
                                         ↓
                                    CANCELLED
```

### NotificationPreference
```typescript
{
  id: number
  userId: number
  emailEnabled: boolean
  whatsappEnabled: boolean
  whatsappNumber: string | null
  smsEnabled: boolean
  smsNumber: string | null
  telegramEnabled: boolean
  telegramChatId: string | null
  createdAt: string (ISO 8601)
  updatedAt: string (ISO 8601)
}
```

### NotificationLog
```typescript
{
  id: number
  channel: "EMAIL" | "WHATSAPP" | "SMS" | "TELEGRAM"
  status: "SENT" | "FAILED"
  message: string
  recipient: string
  sentAt: string (ISO 8601)
  errorDetail: string | null
  whatsappLink: string | null  // Solo para canal WHATSAPP
}
```

---

## 🌐 CORS

El backend está configurado para aceptar peticiones desde:
- `http://localhost:5173` (Desarrollo - Vite)
- `https://virtualpet-963fb.web.app` (Producción - Firebase)

---

## 🔒 Seguridad

### Autenticación
- JWT en cookies HttpOnly
- Secure flag activado en producción
- SameSite=None para permitir requests cross-origin

### Autorización
- **CUSTOMER**: Puede gestionar su perfil, carrito, pedidos y preferencias
- **WAREHOUSE**: Puede gestionar productos, ver todos los pedidos, cambiar estados de pedidos, consultar notificaciones

### Validaciones
- Todos los inputs son validados
- Protección contra SQL Injection (JPA/Hibernate)
- Protección contra XSS (sanitización de inputs)

---

## 📮 Integraciones Externas

### Brevo Email Service
- **Protocolo:** SMTP/TLS
- **Puerto:** 587
- **Uso:** Envío de notificaciones por email cuando un pedido es despachado

### Telegram Bot API
- **Protocolo:** HTTPS/JSON
- **URL:** `https://api.telegram.org/bot{token}/sendMessage`
- **Uso:** Envío de mensajes automáticos cuando un pedido es despachado

### WhatsApp Web
- **Tipo:** Generación de links (NO API)
- **Formato:** `https://wa.me/{phone}?text={message}`
- **Uso:** El backoffice obtiene links para contactar clientes manualmente

---

## 📝 Notas Importantes

1. **Carrito Automático:** Al registrarse, se crea automáticamente un carrito vacío para el usuario
2. **Preferencias Opt-in:** El usuario debe crear explícitamente sus preferencias de notificación. Si no las tiene, NO recibirá notificaciones
3. **Notificaciones Automáticas:** Se envían automáticamente cuando un pedido pasa a estado `SHIPPED`
4. **Stock:** Se gestiona automáticamente al crear y cancelar pedidos
5. **Paginación:** Todos los endpoints de listado soportan paginación

---

## 📞 Soporte

Para consultas sobre la API:
- **Email:** support@virtualpet.com
- **Documentación interactiva (Swagger UI):** https://petshop-cloud.rj.r.appspot.com/swagger-ui/index.html
- **OpenAPI Specification (JSON):** https://petshop-cloud.rj.r.appspot.com/v3/api-docs

### 📚 Recursos Adicionales

- **Swagger UI Docs:** https://swagger.io/tools/swagger-ui/
- **OpenAPI Specification:** https://swagger.io/specification/
- **Postman Learning Center:** https://learning.postman.com/

---

**Última actualización:** 1 de Diciembre de 2025  
**Versión de la API:** 1.0.0  
**OpenAPI Version:** 3.0.0

