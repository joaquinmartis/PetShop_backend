# 🐾 Virtual Pet E-Commerce - Flujo Completo del Sistema

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Flujo Cliente: Compra Completa](#flujo-cliente-compra-completa)
4. [Flujo Warehouse: Gestión de Pedidos](#flujo-warehouse-gestión-de-pedidos)
5. [Estados del Pedido](#estados-del-pedido)
6. [Seguridad y Autenticación](#seguridad-y-autenticación)

---

## Introducción

**Virtual Pet** es un sistema de e-commerce diseñado para la venta de productos para mascotas. El sistema está construido como un **monolito modular** con 4 módulos principales que interactúan entre sí de forma desacoplada.

### Tecnologías
- **Backend**: Spring Boot 3.5.7
- **Base de Datos**: PostgreSQL 14
- **Seguridad**: JWT (JSON Web Tokens)
- **Documentación**: OpenAPI/Swagger

### URL Base
```
http://localhost:8080/api
```

---

## Arquitectura del Sistema

### Módulos Principales

```
┌─────────────────────────────────────────────────────┐
│                   VIRTUAL PET API                   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────┐  ┌──────────────┐               │
│  │     USER     │  │   PRODUCT    │               │
│  │  Management  │  │   Catalog    │               │
│  └──────┬───────┘  └──────┬───────┘               │
│         │                  │                        │
│         │                  │                        │
│  ┌──────▼───────┐  ┌──────▼───────┐               │
│  │     CART     │──▶│    ORDER     │               │
│  │  Management  │  │  Management  │               │
│  └──────────────┘  └──────────────┘               │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Interacciones entre Módulos

- **User → Cart**: Proporciona el `userId` para identificar el carrito
- **User → Order**: Proporciona datos del cliente (nombre, email, teléfono)
- **Product → Cart**: Valida stock y obtiene precios actuales
- **Cart → Order**: Transfiere items del carrito al pedido
- **Product → Order**: Valida stock, reduce y restaura stock según el flujo del pedido

---

## Flujo Cliente: Compra Completa

Este flujo muestra cómo un cliente realiza una compra completa desde el registro hasta la creación del pedido.

### Paso 1: Registro de Usuario

**Endpoint:** `POST /api/users/register`

**Request:**
```json
{
  "email": "juan.perez@email.com",
  "password": "miPassword123",
  "firstName": "Juan",
  "lastName": "Pérez",
  "phone": "1234567890",
  "address": "Av. Libertad 1234, Mar del Plata"
}
```

**Response:** `201 Created`
```json
{
  "id": 1,
  "email": "juan.perez@email.com",
  "firstName": "Juan",
  "lastName": "Pérez",
  "phone": "1234567890",
  "address": "Av. Libertad 1234, Mar del Plata",
  "role": "CLIENT",
  "isActive": true,
  "createdAt": "2025-11-06T10:00:00",
  "updatedAt": "2025-11-06T10:00:00"
}
```

---

### Paso 2: Login y Obtención del Token JWT

**Endpoint:** `POST /api/users/login`

**Request:**
```json
{
  "email": "juan.perez@email.com",
  "password": "miPassword123"
}
```

**Response:** `200 OK`
```json
{
  "accessToken": "eyJhbGciOiJIUzUxMiJ9.eyJyb2xlIjoiQ0xJRU5UIiwidXNlcklkIjoxLCJzdWIiOiJqdWFuLnBlcmV6QGVtYWlsLmNvbSIsImlhdCI6MTczMDkxNjAwMCwiZXhwIjoxNzMwOTE5NjAwfQ...",
  "refreshToken": "eyJhbGciOiJIUzUxMiJ9.eyJyb2xlIjoiQ0xJRU5UIiwidXNlcklkIjoxLCJzdWIiOiJqdWFuLnBlcmV6QGVtYWlsLmNvbSIsImlhdCI6MTczMDkxNjAwMCwiZXhwIjoxNzMwOTE5NjAwfQ...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": 1,
    "email": "juan.perez@email.com",
    "firstName": "Juan",
    "lastName": "Pérez",
    "phone": "1234567890",
    "address": "Av. Libertad 1234, Mar del Plata",
    "role": "CLIENT",
    "isActive": true,
    "createdAt": "2025-11-06T10:00:00",
    "updatedAt": "2025-11-06T10:00:00"
  }
}
```

> **⚠️ Importante:** A partir de aquí, todas las peticiones deben incluir el header:
> ```
> Authorization: Bearer {accessToken}
> ```

---

### Paso 3: Explorar el Catálogo de Productos

#### 3.1 Listar Categorías

**Endpoint:** `GET /api/categories`

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "name": "Alimentos para perros",
    "description": "Comida balanceada, snacks y premios para perros",
    "active": true,
    "createdAt": "2025-11-04T11:57:43.087035",
    "updatedAt": "2025-11-04T11:57:43.087035"
  },
  {
    "id": 2,
    "name": "Alimentos para gatos",
    "description": "Comida balanceada, snacks y premios para gatos",
    "active": true,
    "createdAt": "2025-11-04T11:57:43.087035",
    "updatedAt": "2025-11-04T11:57:43.087035"
  }
]
```

#### 3.2 Listar Productos con Paginación

**Endpoint:** `GET /api/products?page=0&size=3`

**Response:** `200 OK`
```json
{
  "content": [
    {
      "id": 1,
      "name": "Alimento Premium para Perros Adultos 15kg",
      "description": "Alimento balanceado premium para perros adultos de todas las razas",
      "price": 25000.00,
      "stock": 45,
      "category": {
        "id": 1,
        "name": "Alimentos para perros",
        "description": "Comida balanceada, snacks y premios para perros",
        "active": true,
        "createdAt": "2025-11-04T11:57:43.087035",
        "updatedAt": "2025-11-04T11:57:43.087035"
      },
      "imageUrl": "/images/products/dog-food-premium.jpg",
      "active": true,
      "createdAt": "2025-11-04T11:57:54.624002",
      "updatedAt": "2025-11-04T16:37:02.98801"
    },
    {
      "id": 3,
      "name": "Alimento para Gatos Adultos 7.5kg",
      "description": "Alimento completo y balanceado para gatos adultos",
      "price": 18000.00,
      "stock": 28,
      "category": {
        "id": 2,
        "name": "Alimentos para gatos",
        "description": "Comida balanceada, snacks y premios para gatos",
        "active": true,
        "createdAt": "2025-11-04T11:57:43.087035",
        "updatedAt": "2025-11-04T11:57:43.087035"
      },
      "imageUrl": "/images/products/cat-food.jpg",
      "active": true,
      "createdAt": "2025-11-04T11:57:54.624002",
      "updatedAt": "2025-11-04T16:33:16.175712"
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 3,
    "sort": {
      "sorted": true,
      "empty": false,
      "unsorted": false
    },
    "offset": 0,
    "paged": true,
    "unpaged": false
  },
  "totalPages": 4,
  "totalElements": 10,
  "size": 3,
  "number": 0,
  "first": true,
  "numberOfElements": 2,
  "empty": false
}
```

#### 3.3 Ver Detalle de un Producto

**Endpoint:** `GET /api/products/1`

**Response:** `200 OK`
```json
{
  "id": 1,
  "name": "Alimento Premium para Perros Adultos 15kg",
  "description": "Alimento balanceado premium para perros adultos de todas las razas. Contiene proteínas de alta calidad, vitaminas y minerales esenciales.",
  "price": 25000.00,
  "stock": 45,
  "category": {
    "id": 1,
    "name": "Alimentos para perros",
    "description": "Comida balanceada, snacks y premios para perros",
    "active": true,
    "createdAt": "2025-11-04T11:57:43.087035",
    "updatedAt": "2025-11-04T11:57:43.087035"
  },
  "imageUrl": "/images/products/dog-food-premium.jpg",
  "active": true,
  "createdAt": "2025-11-04T11:57:54.624002",
  "updatedAt": "2025-11-04T16:37:02.98801"
}
```

---

### Paso 4: Agregar Productos al Carrito

#### 4.1 Ver Carrito Vacío (Primera Vez)

**Endpoint:** `GET /api/cart`  
**Headers:** `Authorization: Bearer {token}`

**Response:** `200 OK`
```json
{
  "id": 1,
  "userId": 1,
  "items": [],
  "totalItems": 0,
  "totalAmount": 0,
  "createdAt": "2025-11-06T10:05:00",
  "updatedAt": "2025-11-06T10:05:00"
}
```

#### 4.2 Agregar Primer Producto

**Endpoint:** `POST /api/cart/items`  
**Headers:** `Authorization: Bearer {token}`

**Request:**
```json
{
  "productId": 1,
  "quantity": 2
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "userId": 1,
  "items": [
    {
      "id": 1,
      "productId": 1,
      "productName": "Alimento Premium para Perros Adultos 15kg",
      "quantity": 2,
      "unitPrice": 25000.00,
      "subtotal": 50000.00,
      "imageUrl": "/images/products/dog-food-premium.jpg",
      "addedAt": "2025-11-06T10:06:00",
      "updatedAt": "2025-11-06T10:06:00"
    }
  ],
  "totalItems": 2,
  "totalAmount": 50000.00,
  "createdAt": "2025-11-06T10:05:00",
  "updatedAt": "2025-11-06T10:06:00"
}
```

> **💡 Nota:** El `subtotal` se calcula automáticamente: `unitPrice × quantity`

#### 4.3 Agregar Segundo Producto

**Endpoint:** `POST /api/cart/items`  
**Headers:** `Authorization: Bearer {token}`

**Request:**
```json
{
  "productId": 3,
  "quantity": 1
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "userId": 1,
  "items": [
    {
      "id": 1,
      "productId": 1,
      "productName": "Alimento Premium para Perros Adultos 15kg",
      "quantity": 2,
      "unitPrice": 25000.00,
      "subtotal": 50000.00,
      "imageUrl": "/images/products/dog-food-premium.jpg",
      "addedAt": "2025-11-06T10:06:00",
      "updatedAt": "2025-11-06T10:06:00"
    },
    {
      "id": 2,
      "productId": 3,
      "productName": "Alimento para Gatos Adultos 7.5kg",
      "quantity": 1,
      "unitPrice": 18000.00,
      "subtotal": 18000.00,
      "imageUrl": "/images/products/cat-food.jpg",
      "addedAt": "2025-11-06T10:07:00",
      "updatedAt": "2025-11-06T10:07:00"
    }
  ],
  "totalItems": 3,
  "totalAmount": 68000.00,
  "createdAt": "2025-11-06T10:05:00",
  "updatedAt": "2025-11-06T10:07:00"
}
```

#### 4.4 Actualizar Cantidad de un Producto

**Endpoint:** `PATCH /api/cart/items/1`  
**Headers:** `Authorization: Bearer {token}`

**Request:**
```json
{
  "quantity": 3
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "userId": 1,
  "items": [
    {
      "id": 1,
      "productId": 1,
      "productName": "Alimento Premium para Perros Adultos 15kg",
      "quantity": 3,
      "unitPrice": 25000.00,
      "subtotal": 75000.00,
      "imageUrl": "/images/products/dog-food-premium.jpg",
      "addedAt": "2025-11-06T10:06:00",
      "updatedAt": "2025-11-06T10:08:00"
    },
    {
      "id": 2,
      "productId": 3,
      "productName": "Alimento para Gatos Adultos 7.5kg",
      "quantity": 1,
      "unitPrice": 18000.00,
      "subtotal": 18000.00,
      "imageUrl": "/images/products/cat-food.jpg",
      "addedAt": "2025-11-06T10:07:00",
      "updatedAt": "2025-11-06T10:07:00"
    }
  ],
  "totalItems": 4,
  "totalAmount": 93000.00,
  "createdAt": "2025-11-06T10:05:00",
  "updatedAt": "2025-11-06T10:08:00"
}
```

---

### Paso 5: Crear el Pedido

**Endpoint:** `POST /api/orders`  
**Headers:** `Authorization: Bearer {token}`

**Request:**
```json
{
  "shippingAddress": "Av. Libertad 1234, Mar del Plata",
  "notes": "Entregar en horario de oficina (9-18hs)"
}
```

**Response:** `201 Created`
```json
{
  "id": 1,
  "userId": 1,
  "status": "CONFIRMED",
  "total": 93000.00,
  "shippingMethod": null,
  "shippingId": null,
  "shippingAddress": "Av. Libertad 1234, Mar del Plata",
  "customerName": "Juan Pérez",
  "customerEmail": "juan.perez@email.com",
  "customerPhone": "1234567890",
  "notes": "Entregar en horario de oficina (9-18hs)",
  "cancellationReason": null,
  "cancelledAt": null,
  "cancelledBy": null,
  "items": [
    {
      "id": 1,
      "productId": 1,
      "productName": "Alimento Premium para Perros Adultos 15kg",
      "productImage": "/images/products/dog-food-premium.jpg",
      "quantity": 3,
      "unitPrice": 25000.00,
      "subtotal": 75000.00
    },
    {
      "id": 2,
      "productId": 3,
      "productName": "Alimento para Gatos Adultos 7.5kg",
      "productImage": "/images/products/cat-food.jpg",
      "quantity": 1,
      "unitPrice": 18000.00,
      "subtotal": 18000.00
    }
  ],
  "createdAt": "2025-11-06T10:10:00",
  "updatedAt": "2025-11-06T10:10:00"
}
```

> **✅ ¿Qué sucede internamente?**
> 1. Se valida que el carrito no esté vacío
> 2. Se verifica el stock de TODOS los productos
> 3. Se crea el pedido con estado `CONFIRMED` (stock ya validado)
> 4. Se copian los items del carrito al pedido (con snapshots de precio y nombre)
> 5. Se **reduce el stock** de cada producto
> 6. Se **vacía el carrito** automáticamente
> 7. Se registra el cambio de estado en el historial

---

### Paso 6: Consultar Mis Pedidos

**Endpoint:** `GET /api/orders?page=0&size=10`  
**Headers:** `Authorization: Bearer {token}`

**Response:** `200 OK`
```json
{
  "content": [
    {
      "id": 1,
      "userId": 1,
      "status": "CONFIRMED",
      "total": 93000.00,
      "shippingMethod": null,
      "shippingAddress": "Av. Libertad 1234, Mar del Plata",
      "customerName": "Juan Pérez",
      "customerEmail": "juan.perez@email.com",
      "customerPhone": "1234567890",
      "notes": "Entregar en horario de oficina (9-18hs)",
      "items": [
        {
          "id": 1,
          "productId": 1,
          "productName": "Alimento Premium para Perros Adultos 15kg",
          "productImage": "/images/products/dog-food-premium.jpg",
          "quantity": 3,
          "unitPrice": 25000.00,
          "subtotal": 75000.00
        },
        {
          "id": 2,
          "productId": 3,
          "productName": "Alimento para Gatos Adultos 7.5kg",
          "productImage": "/images/products/cat-food.jpg",
          "quantity": 1,
          "unitPrice": 18000.00,
          "subtotal": 18000.00
        }
      ],
      "createdAt": "2025-11-06T10:10:00",
      "updatedAt": "2025-11-06T10:10:00"
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 10,
    "sort": {
      "sorted": true,
      "empty": false,
      "unsorted": false
    },
    "offset": 0,
    "paged": true,
    "unpaged": false
  },
  "totalPages": 1,
  "totalElements": 1,
  "size": 10,
  "number": 0,
  "first": true,
  "numberOfElements": 1
}
```

---

### Paso 7: Ver Detalle de un Pedido

**Endpoint:** `GET /api/orders/1`  
**Headers:** `Authorization: Bearer {token}`

**Response:** `200 OK`
```json
{
  "id": 1,
  "userId": 1,
  "status": "CONFIRMED",
  "total": 93000.00,
  "shippingMethod": null,
  "shippingId": null,
  "shippingAddress": "Av. Libertad 1234, Mar del Plata",
  "customerName": "Juan Pérez",
  "customerEmail": "juan.perez@email.com",
  "customerPhone": "1234567890",
  "notes": "Entregar en horario de oficina (9-18hs)",
  "cancellationReason": null,
  "cancelledAt": null,
  "cancelledBy": null,
  "items": [
    {
      "id": 1,
      "productId": 1,
      "productName": "Alimento Premium para Perros Adultos 15kg",
      "productImage": "/images/products/dog-food-premium.jpg",
      "quantity": 3,
      "unitPrice": 25000.00,
      "subtotal": 75000.00
    },
    {
      "id": 2,
      "productId": 3,
      "productName": "Alimento para Gatos Adultos 7.5kg",
      "productImage": "/images/products/cat-food.jpg",
      "quantity": 1,
      "unitPrice": 18000.00,
      "subtotal": 18000.00
    }
  ],
  "createdAt": "2025-11-06T10:10:00",
  "updatedAt": "2025-11-06T10:10:00"
}
```

---

### Paso 8: Cancelar un Pedido (Opcional)

**Endpoint:** `PATCH /api/orders/1/cancel`  
**Headers:** `Authorization: Bearer {token}`

**Request:**
```json
{
  "reason": "Cambié de opinión, ya no necesito los productos"
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "userId": 1,
  "status": "CANCELLED",
  "total": 93000.00,
  "shippingMethod": null,
  "shippingAddress": "Av. Libertad 1234, Mar del Plata",
  "customerName": "Juan Pérez",
  "customerEmail": "juan.perez@email.com",
  "customerPhone": "1234567890",
  "notes": "Entregar en horario de oficina (9-18hs)",
  "cancellationReason": "Cambié de opinión, ya no necesito los productos",
  "cancelledAt": "2025-11-06T10:15:00",
  "cancelledBy": "CLIENT",
  "items": [
    {
      "id": 1,
      "productId": 1,
      "productName": "Alimento Premium para Perros Adultos 15kg",
      "productImage": "/images/products/dog-food-premium.jpg",
      "quantity": 3,
      "unitPrice": 25000.00,
      "subtotal": 75000.00
    },
    {
      "id": 2,
      "productId": 3,
      "productName": "Alimento para Gatos Adultos 7.5kg",
      "productImage": "/images/products/cat-food.jpg",
      "quantity": 1,
      "unitPrice": 18000.00,
      "subtotal": 18000.00
    }
  ],
  "createdAt": "2025-11-06T10:10:00",
  "updatedAt": "2025-11-06T10:15:00"
}
```

> **✅ ¿Qué sucede al cancelar?**
> - Solo se pueden cancelar pedidos en estado `PENDING` o `CONFIRMED`
> - Se **restaura el stock** de todos los productos
> - Se registra la razón, fecha y quién canceló (CLIENT)
> - El estado cambia a `CANCELLED`

---

## Flujo Warehouse: Gestión de Pedidos

Este flujo muestra cómo un empleado de almacén (rol WAREHOUSE) gestiona los pedidos.

### Paso 1: Login Usuario Warehouse

**Endpoint:** `POST /api/users/login`

**Request:**
```json
{
  "email": "warehouse@test.com",
  "password": "password123"
}
```

**Response:** `200 OK`
```json
{
  "accessToken": "eyJhbGciOiJIUzUxMiJ9.eyJyb2xlIjoiV0FSRUhPVVNFIiwidXNlcklkIjo1LCJzdWIiOiJ3YXJlaG91c2VAdGVzdC5jb20iLCJpYXQiOjE3MzA5MTYwMDAsImV4cCI6MTczMDkxOTYwMH0...",
  "refreshToken": "eyJhbGciOiJIUzUxMiJ9...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": 5,
    "email": "warehouse@test.com",
    "firstName": "Warehouse",
    "lastName": "Manager",
    "phone": "9999999999",
    "address": "Depósito Central",
    "role": "WAREHOUSE",
    "isActive": true,
    "createdAt": "2025-11-04T16:25:42.572161",
    "updatedAt": "2025-11-04T16:25:42.572179"
  }
}
```

---

### Paso 2: Listar Todos los Pedidos

**Endpoint:** `GET /api/backoffice/orders?page=0&size=10`  
**Headers:** `Authorization: Bearer {warehouse_token}`

**Response:** `200 OK`
```json
{
  "content": [
    {
      "id": 2,
      "userId": 3,
      "status": "CONFIRMED",
      "total": 50000.00,
      "shippingMethod": null,
      "shippingAddress": "Calle Principal 456, Buenos Aires",
      "customerName": "María González",
      "customerEmail": "maria.gonzalez@email.com",
      "customerPhone": "1155667788",
      "notes": null,
      "items": [
        {
          "id": 3,
          "productId": 1,
          "productName": "Alimento Premium para Perros Adultos 15kg",
          "productImage": "/images/products/dog-food-premium.jpg",
          "quantity": 2,
          "unitPrice": 25000.00,
          "subtotal": 50000.00
        }
      ],
      "createdAt": "2025-11-06T11:00:00",
      "updatedAt": "2025-11-06T11:00:00"
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 10,
    "sort": {
      "sorted": true,
      "empty": false,
      "unsorted": false
    },
    "offset": 0
  },
  "totalPages": 1,
  "totalElements": 1,
  "size": 10,
  "number": 0,
  "first": true,
  "numberOfElements": 1
}
```

---

### Paso 3: Filtrar Pedidos por Estado

**Endpoint:** `GET /api/backoffice/orders?status=CONFIRMED&page=0&size=10`  
**Headers:** `Authorization: Bearer {warehouse_token}`

**Response:** `200 OK`
```json
{
  "content": [
    {
      "id": 2,
      "userId": 3,
      "status": "CONFIRMED",
      "total": 50000.00,
      "shippingMethod": null,
      "shippingAddress": "Calle Principal 456, Buenos Aires",
      "customerName": "María González",
      "customerEmail": "maria.gonzalez@email.com",
      "customerPhone": "1155667788",
      "items": [
        {
          "id": 3,
          "productId": 1,
          "productName": "Alimento Premium para Perros Adultos 15kg",
          "productImage": "/images/products/dog-food-premium.jpg",
          "quantity": 2,
          "unitPrice": 25000.00,
          "subtotal": 50000.00
        }
      ],
      "createdAt": "2025-11-06T11:00:00",
      "updatedAt": "2025-11-06T11:00:00"
    }
  ],
  "totalElements": 1
}
```

> **💡 Estados disponibles para filtrar:**
> - `CONFIRMED`
> - `READY_TO_SHIP`
> - `SHIPPED`
> - `DELIVERED`
> - `CANCELLED`

---

### Paso 4: Marcar Pedido como Listo para Enviar

**Endpoint:** `PATCH /api/backoffice/orders/2/ready-to-ship`  
**Headers:** `Authorization: Bearer {warehouse_token}`

**Response:** `200 OK`
```json
{
  "id": 2,
  "userId": 3,
  "status": "READY_TO_SHIP",
  "total": 50000.00,
  "shippingMethod": null,
  "shippingAddress": "Calle Principal 456, Buenos Aires",
  "customerName": "María González",
  "customerEmail": "maria.gonzalez@email.com",
  "customerPhone": "1155667788",
  "items": [
    {
      "id": 3,
      "productId": 1,
      "productName": "Alimento Premium para Perros Adultos 15kg",
      "productImage": "/images/products/dog-food-premium.jpg",
      "quantity": 2,
      "unitPrice": 25000.00,
      "subtotal": 50000.00
    }
  ],
  "createdAt": "2025-11-06T11:00:00",
  "updatedAt": "2025-11-06T11:05:00"
}
```

---

### Paso 5: Asignar Método de Envío

**Endpoint:** `PATCH /api/backoffice/orders/2/shipping-method`  
**Headers:** `Authorization: Bearer {warehouse_token}`

**Request:**
```json
{
  "shippingMethod": "COURIER"
}
```

**Response:** `200 OK`
```json
{
  "id": 2,
  "userId": 3,
  "status": "READY_TO_SHIP",
  "total": 50000.00,
  "shippingMethod": "COURIER",
  "shippingAddress": "Calle Principal 456, Buenos Aires",
  "customerName": "María González",
  "customerEmail": "maria.gonzalez@email.com",
  "customerPhone": "1155667788",
  "items": [
    {
      "id": 3,
      "productId": 1,
      "productName": "Alimento Premium para Perros Adultos 15kg",
      "productImage": "/images/products/dog-food-premium.jpg",
      "quantity": 2,
      "unitPrice": 25000.00,
      "subtotal": 50000.00
    }
  ],
  "createdAt": "2025-11-06T11:00:00",
  "updatedAt": "2025-11-06T11:06:00"
}
```

> **💡 Métodos de envío disponibles:**
> - `OWN_TEAM`: Equipo propio de entrega
> - `COURIER`: Servicio de mensajería externo

---

### Paso 6: Despachar Pedido

**Endpoint:** `PATCH /api/backoffice/orders/2/ship`  
**Headers:** `Authorization: Bearer {warehouse_token}`

**Response:** `200 OK`
```json
{
  "id": 2,
  "userId": 3,
  "status": "SHIPPED",
  "total": 50000.00,
  "shippingMethod": "COURIER",
  "shippingAddress": "Calle Principal 456, Buenos Aires",
  "customerName": "María González",
  "customerEmail": "maria.gonzalez@email.com",
  "customerPhone": "1155667788",
  "items": [
    {
      "id": 3,
      "productId": 1,
      "productName": "Alimento Premium para Perros Adultos 15kg",
      "productImage": "/images/products/dog-food-premium.jpg",
      "quantity": 2,
      "unitPrice": 25000.00,
      "subtotal": 50000.00
    }
  ],
  "createdAt": "2025-11-06T11:00:00",
  "updatedAt": "2025-11-06T11:10:00"
}
```

---

### Paso 7: Marcar como Entregado

**Endpoint:** `PATCH /api/backoffice/orders/2/deliver`  
**Headers:** `Authorization: Bearer {warehouse_token}`

**Response:** `200 OK`
```json
{
  "id": 2,
  "userId": 3,
  "status": "DELIVERED",
  "total": 50000.00,
  "shippingMethod": "COURIER",
  "shippingAddress": "Calle Principal 456, Buenos Aires",
  "customerName": "María González",
  "customerEmail": "maria.gonzalez@email.com",
  "customerPhone": "1155667788",
  "items": [
    {
      "id": 3,
      "productId": 1,
      "productName": "Alimento Premium para Perros Adultos 15kg",
      "productImage": "/images/products/dog-food-premium.jpg",
      "quantity": 2,
      "unitPrice": 25000.00,
      "subtotal": 50000.00
    }
  ],
  "createdAt": "2025-11-06T11:00:00",
  "updatedAt": "2025-11-06T11:30:00"
}
```

---

### Paso 8: Rechazar un Pedido (Opcional)

**Endpoint:** `PATCH /api/backoffice/orders/3/reject`  
**Headers:** `Authorization: Bearer {warehouse_token}`

**Request:**
```json
{
  "reason": "Producto fuera de stock en depósito"
}
```

**Response:** `200 OK`
```json
{
  "id": 3,
  "userId": 4,
  "status": "CANCELLED",
  "total": 18000.00,
  "shippingMethod": null,
  "shippingAddress": "Av. Colón 789, Córdoba",
  "customerName": "Pedro Martínez",
  "customerEmail": "pedro.martinez@email.com",
  "customerPhone": "3514556677",
  "cancellationReason": "Producto fuera de stock en depósito",
  "cancelledAt": "2025-11-06T11:35:00",
  "cancelledBy": "WAREHOUSE",
  "items": [
    {
      "id": 5,
      "productId": 3,
      "productName": "Alimento para Gatos Adultos 7.5kg",
      "productImage": "/images/products/cat-food.jpg",
      "quantity": 1,
      "unitPrice": 18000.00,
      "subtotal": 18000.00
    }
  ],
  "createdAt": "2025-11-06T11:20:00",
  "updatedAt": "2025-11-06T11:35:00"
}
```

> **✅ ¿Qué sucede al rechazar?**
> - Solo se pueden rechazar pedidos en estado `PENDING` o `CONFIRMED`
> - Se **restaura el stock** de todos los productos
> - El estado cambia a `CANCELLED`
> - Se registra que fue cancelado por `WAREHOUSE`

---

## Estados del Pedido

### Diagrama de Transiciones de Estado

```
┌─────────────┐
│  CONFIRMED  │  (Estado inicial al crear pedido)
└──────┬──────┘
       │
       │ warehouse: ready-to-ship
       ▼
┌─────────────────┐
│ READY_TO_SHIP   │
└──────┬──────────┘
       │
       │ warehouse: ship
       ▼
┌─────────────┐
│   SHIPPED   │
└──────┬──────┘
       │
       │ warehouse: deliver
       ▼
┌─────────────┐
│  DELIVERED  │  (Estado final exitoso)
└─────────────┘


Cancelaciones:
─────────────

CONFIRMED ──┐
            ├─► CANCELLED (por cliente o warehouse)
READY_TO_SHIP──┘

SHIPPED ────► No se puede cancelar
DELIVERED ──► No se puede cancelar
```

### Descripción de Estados

| Estado | Descripción | ¿Quién puede cambiar? | Acciones permitidas |
|--------|-------------|----------------------|---------------------|
| **CONFIRMED** | Pedido confirmado, stock validado y reducido | Sistema (automático) | Cliente: cancelar<br>Warehouse: ready-to-ship, reject |
| **READY_TO_SHIP** | Pedido preparado para despacho | Warehouse | Warehouse: ship, shipping-method |
| **SHIPPED** | Pedido despachado en camino | Warehouse | Warehouse: deliver |
| **DELIVERED** | Pedido entregado al cliente | Warehouse | Ninguna |
| **CANCELLED** | Pedido cancelado | Cliente o Warehouse | Ninguna |

---

## Seguridad y Autenticación

### JWT (JSON Web Tokens)

El sistema utiliza JWT para autenticación. Cada token contiene:

```json
{
  "role": "CLIENT",
  "userId": 1,
  "sub": "juan.perez@email.com",
  "iat": 1730916000,
  "exp": 1730919600
}
```

### Roles y Permisos

| Rol | Endpoints Accesibles |
|-----|---------------------|
| **CLIENT** | - `/api/users/*` (propios)<br>- `/api/products/*` (lectura)<br>- `/api/categories/*` (lectura)<br>- `/api/cart/*` (propios)<br>- `/api/orders/*` (propios) |
| **WAREHOUSE** | - `/api/backoffice/orders/*` (todos los pedidos)<br>- Acceso de lectura a productos |

### Headers Requeridos

Para todos los endpoints protegidos:

```http
Authorization: Bearer eyJhbGciOiJIUzUxMiJ9.eyJyb2xlIjoiQ0xJRU5UIiwidXNlcklkIjoxLCJzdWIiOiJqdWFuLnBlcmV6QGVtYWlsLmNvbSIsImlhdCI6MTczMDkxNjAwMCwiZXhwIjoxNzMwOTE5NjAwfQ...
```

### Códigos de Respuesta HTTP

| Código | Descripción |
|--------|-------------|
| **200** | OK - Operación exitosa |
| **201** | Created - Recurso creado |
| **400** | Bad Request - Datos inválidos, validaciones fallidas |
| **401** | Unauthorized - Token inválido o expirado |
| **403** | Forbidden - Sin permisos para acceder al recurso |
| **404** | Not Found - Recurso no encontrado |
| **409** | Conflict - Conflicto de negocio (ej: stock insuficiente) |
| **500** | Internal Server Error - Error del servidor |

### Ejemplo de Error Response

```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "Stock insuficiente. Disponible: 5",
  "path": "/api/cart/items",
  "timestamp": "2025-11-06T10:15:30",
  "field": null
}
```

---

## Casos de Uso Especiales

### 1. Stock Insuficiente al Crear Pedido

**Request:** `POST /api/orders`

**Response:** `400 Bad Request`
```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "Stock insuficiente para los siguientes productos:\n- Alimento Premium para Perros: solicitaste 10, disponible 5\n",
  "path": "/api/orders",
  "timestamp": "2025-11-06T10:20:00",
  "field": null
}
```

### 2. Carrito Vacío al Crear Pedido

**Request:** `POST /api/orders`

**Response:** `400 Bad Request`
```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "El carrito está vacío",
  "path": "/api/orders",
  "timestamp": "2025-11-06T10:25:00",
  "field": null
}
```

### 3. Intentar Cancelar Pedido Ya Despachado

**Request:** `PATCH /api/orders/1/cancel`

**Response:** `400 Bad Request`
```json
{
  "status": 400,
  "error": "Bad Request",
  "message": "No puedes cancelar un pedido que ya fue despachado o entregado",
  "path": "/api/orders/1/cancel",
  "timestamp": "2025-11-06T10:30:00",
  "field": null
}
```

### 4. Acceso a Pedido de Otro Usuario

**Request:** `GET /api/orders/99` (pedido de otro cliente)

**Response:** `404 Not Found`
```json
{
  "status": 404,
  "error": "Not Found",
  "message": "Pedido no encontrado",
  "path": "/api/orders/99",
  "timestamp": "2025-11-06T10:35:00",
  "field": null
}
```

> **🔒 Seguridad:** Los clientes solo pueden ver sus propios pedidos. Si intentan acceder a un pedido que no les pertenece, el sistema retorna 404 (como si no existiera).

---

## Resumen del Flujo Completo

### Interacción entre Módulos

```
┌──────────────────────────────────────────────────────────┐
│                    FLUJO COMPLETO                        │
└──────────────────────────────────────────────────────────┘

1️⃣  USER: Register → Login → Get JWT Token
              │
              ▼
2️⃣  PRODUCT: Browse Products → View Details
              │
              ▼
3️⃣  CART: Add Products → Update Quantities
              │
              │ (valida stock con PRODUCT)
              ▼
4️⃣  ORDER: Create Order
              │
              ├─► PRODUCT: Validate Stock
              ├─► PRODUCT: Reduce Stock
              ├─► USER: Get Customer Info
              └─► CART: Clear Cart
              │
              ▼
5️⃣  WAREHOUSE: Manage Order States
              │
              ├─► Ready to Ship
              ├─► Ship
              └─► Deliver
```

### Validaciones Automáticas

| Operación | Validaciones |
|-----------|--------------|
| **Agregar al carrito** | - Producto existe y está activo<br>- Stock disponible |
| **Crear pedido** | - Carrito no vacío<br>- Stock disponible para TODOS los productos<br>- Usuario autenticado |
| **Cancelar pedido** | - Estado permite cancelación (PENDING/CONFIRMED)<br>- Usuario es dueño del pedido O es WAREHOUSE |
| **Cambiar estado** | - Transición de estado válida<br>- Usuario tiene rol WAREHOUSE |

---

## 📚 Documentación Adicional

### Swagger UI

Accede a la documentación interactiva:

```
http://localhost:8080/swagger-ui.html
```

### OpenAPI JSON

```
http://localhost:8080/v3/api-docs
```

---

## 🎯 Conclusión

Este documento describe el flujo completo del sistema Virtual Pet, mostrando cómo los 4 módulos principales (User, Product, Cart, Order) interactúan entre sí para proporcionar una experiencia de compra completa.

### Características Principales

✅ **Autenticación JWT** - Seguridad basada en tokens  
✅ **Roles y Permisos** - CLIENT y WAREHOUSE con diferentes accesos  
✅ **Validación de Stock** - En tiempo real al agregar al carrito y crear pedidos  
✅ **Gestión de Estados** - Flujo completo desde confirmación hasta entrega  
✅ **Cancelaciones** - Con restauración automática de stock  
✅ **Snapshots** - Los pedidos guardan precios y nombres al momento de la compra  
✅ **Paginación** - En listados de productos y pedidos  
✅ **Filtros** - Por categoría, stock, estado, etc.  

---

**Desarrollado con ❤️ para Virtual Pet** 🐾

_Última actualización: 6 de Noviembre de 2025_

