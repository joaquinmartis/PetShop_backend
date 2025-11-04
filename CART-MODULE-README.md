# Módulo Cart - Implementación Completa

## ✅ RESUMEN DE IMPLEMENTACIÓN

El módulo **Cart** ha sido implementado exitosamente siguiendo la arquitectura modular del proyecto Virtual Pet.

---

## 📦 ARCHIVOS CREADOS

### 1. **Entidades JPA** (`modules/cart/entity/`)
- ✅ `Cart.java` - Carrito de compra del usuario
- ✅ `CartItem.java` - Items dentro del carrito

**Características:**
- Schema: `cart`
- Relación: `Cart` → `@OneToMany` → `CartItem`
- Relación: `CartItem` → `@ManyToOne` → `Cart`
- Auditoría automática con `@PrePersist` y `@PreUpdate`
- Método helper `getSubtotal()` en CartItem
- Uso de Lombok (`@Data`, `@NoArgsConstructor`, `@AllArgsConstructor`)

---

### 2. **Repositorios** (`modules/cart/repository/`)
- ✅ `CartRepository.java` - Operaciones de carritos
- ✅ `CartItemRepository.java` - Operaciones de items

**Métodos destacados:**
- `findByUserIdWithItems()` - JOIN FETCH para optimizar consultas (evita N+1)
- `deleteByCartIdAndProductId()` - Eliminar item específico
- `deleteAllByCartId()` - Vaciar carrito completo

---

### 3. **DTOs** (`modules/cart/dto/`)
- ✅ `AddToCartRequest.java` - Request para agregar productos
- ✅ `UpdateCartItemRequest.java` - Request para actualizar cantidad
- ✅ `CartItemResponse.java` - Response de item individual
- ✅ `CartResponse.java` - Response del carrito completo con totales

---

### 4. **Servicio** (`modules/cart/service/`)
- ✅ `CartService.java` - Lógica de negocio del carrito

**API Pública (para clientes):**
```java
- getCart(Long userId)
- addToCart(Long userId, AddToCartRequest)
- updateCartItem(Long userId, Long productId, UpdateCartItemRequest)
- removeFromCart(Long userId, Long productId)
- clearCart(Long userId)
```

**API Pública (para Order Management):**
```java
- getCartEntity(Long userId)
- clearCartAfterOrder(Long userId)
```

**Características especiales:**
- ✅ Validación de stock en tiempo real (llama a ProductService)
- ✅ Snapshot de precio y nombre al agregar al carrito
- ✅ Si un producto ya está en el carrito, suma cantidades
- ✅ Calcula totales automáticamente (totalItems, totalAmount)
- ✅ Un carrito por usuario (constraint UNIQUE en BD)

---

### 5. **Controlador** (`modules/cart/controller/`)
- ✅ `CartController.java` - Endpoints REST del carrito

---

## 🔌 ENDPOINTS IMPLEMENTADOS

Todos los endpoints requieren **autenticación JWT** (header `Authorization: Bearer {token}`).

### 1️⃣ **GET /api/cart**
- **Descripción:** Obtener carrito del usuario autenticado
- **Autenticación:** Requerida (JWT)
- **Response:** `CartResponse` con items, totales, etc.

**Ejemplo:**
```bash
curl -X GET http://localhost:8080/api/cart \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response:**
```json
{
  "id": 1,
  "userId": 5,
  "items": [
    {
      "id": 1,
      "productId": 1,
      "productName": "Alimento Premium para Perros Adultos 15kg",
      "quantity": 2,
      "unitPrice": 25000.00,
      "subtotal": 50000.00,
      "imageUrl": "/images/products/dog-food-premium.jpg",
      "addedAt": "2025-11-04T10:30:00",
      "updatedAt": "2025-11-04T10:30:00"
    }
  ],
  "totalItems": 2,
  "totalAmount": 50000.00,
  "createdAt": "2025-11-04T10:00:00",
  "updatedAt": "2025-11-04T10:30:00"
}
```

---

### 2️⃣ **POST /api/cart/items**
- **Descripción:** Agregar producto al carrito
- **Autenticación:** Requerida (JWT)
- **Request Body:** `AddToCartRequest`
- **Response:** `CartResponse` actualizado

**Ejemplo:**
```bash
curl -X POST http://localhost:8080/api/cart/items \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": 1,
    "quantity": 2
  }'
```

**Validaciones:**
- ✅ Verifica que el producto exista (llama a ProductService)
- ✅ Valida stock disponible
- ✅ Si el producto ya está en el carrito, suma cantidades
- ✅ Congela precio y nombre del producto (snapshot)

---

### 3️⃣ **PATCH /api/cart/items/{productId}**
- **Descripción:** Actualizar cantidad de un producto en el carrito
- **Autenticación:** Requerida (JWT)
- **Request Body:** `UpdateCartItemRequest`
- **Response:** `CartResponse` actualizado

**Ejemplo:**
```bash
curl -X PATCH http://localhost:8080/api/cart/items/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 5
  }'
```

**Validaciones:**
- ✅ Verifica stock disponible para la nueva cantidad
- ✅ No permite cantidad menor a 1

---

### 4️⃣ **DELETE /api/cart/items/{productId}**
- **Descripción:** Eliminar un producto del carrito
- **Autenticación:** Requerida (JWT)
- **Response:** `CartResponse` actualizado

**Ejemplo:**
```bash
curl -X DELETE http://localhost:8080/api/cart/items/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### 5️⃣ **DELETE /api/cart/clear**
- **Descripción:** Vaciar carrito completo
- **Autenticación:** Requerida (JWT)
- **Response:** Mensaje de éxito

**Ejemplo:**
```bash
curl -X DELETE http://localhost:8080/api/cart/clear \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response:**
```json
{
  "message": "Carrito vaciado exitosamente"
}
```

---

## 🔐 CONFIGURACIÓN DE SEGURIDAD

Todos los endpoints de cart están **protegidos** y requieren autenticación JWT:

```java
// En SecurityConfig.java
.requestMatchers("/api/cart/**").authenticated()
```

---

## 🗄️ BASE DE DATOS

### Schema: `cart`

#### Tabla: `carts`
```sql
id              BIGSERIAL PRIMARY KEY
user_id         BIGINT NOT NULL UNIQUE
created_at      TIMESTAMP
updated_at      TIMESTAMP
```

#### Tabla: `cart_items`
```sql
id                      BIGSERIAL PRIMARY KEY
cart_id                 BIGINT REFERENCES cart.carts(id) ON DELETE CASCADE
product_id              BIGINT (referencia lógica)
quantity                INTEGER CHECK (quantity > 0)
unit_price_snapshot     DECIMAL(10,2)
product_name_snapshot   VARCHAR(150)
added_at                TIMESTAMP
updated_at              TIMESTAMP
```

**Constraints importantes:**
- ✅ `UNIQUE (user_id)` en carts - Un solo carrito por usuario
- ✅ `UNIQUE (cart_id, product_id)` en cart_items - Un producto por carrito
- ✅ `ON DELETE CASCADE` - Si se borra el carrito, se borran sus items

**NO hay Foreign Keys entre schemas:**
- `cart.carts.user_id` → Referencia **lógica** a `user_management.users.id`
- `cart.cart_items.product_id` → Referencia **lógica** a `product_catalog.products.id`

---

## 🧪 CÓMO PROBAR

### Prerequisitos:
1. Crear usuario de prueba en la base de datos:
```bash
psql -U virtualpet_user -d virtualpet -f create-test-user.sql
```

2. Arrancar la aplicación:
```bash
./mvnw spring-boot:run
```

### Ejecutar script de pruebas:
```bash
./test-cart.sh
```

El script ejecutará automáticamente:
1. ✅ Login y obtención de JWT
2. ✅ Ver carrito vacío
3. ✅ Agregar productos
4. ✅ Agregar más del mismo producto (acumula)
5. ✅ Ver carrito con productos
6. ✅ Actualizar cantidad
7. ✅ Eliminar producto
8. ✅ Intentar agregar con stock insuficiente (debe fallar)
9. ✅ Vaciar carrito
10. ✅ Verificar carrito vacío

---

## 🔄 INTEGRACIÓN CON OTROS MÓDULOS

### Con Product Module
El CartService llama a:
- `productService.getProductById()` - Para obtener precio y validar existencia
- Valida stock en tiempo real antes de agregar/actualizar

### Con User Module
El CartController llama a:
- `userService.getProfile()` - Para obtener el userId del usuario autenticado

### Con Order Management (futuro)
Order Management llamará a:
- `cartService.getCartEntity()` - Para leer items al crear pedido
- `cartService.clearCartAfterOrder()` - Para vaciar carrito después de confirmar pedido

---

## ✅ CARACTERÍSTICAS IMPLEMENTADAS

1. ✅ **Arquitectura modular** respetada al 100%
2. ✅ **Schema separado** `cart`
3. ✅ **Sin Foreign Keys** hacia otros módulos
4. ✅ **Un carrito por usuario**
5. ✅ **Validación de stock** en tiempo real
6. ✅ **Snapshots de precio/nombre** congelados
7. ✅ **Acumulación de cantidades** si el producto ya existe
8. ✅ **Cálculo automático** de totales
9. ✅ **Optimización JOIN FETCH** para evitar N+1
10. ✅ **Endpoints protegidos** con JWT
11. ✅ **Validaciones** con Bean Validation
12. ✅ **Manejo de errores** con ErrorResponse

---

## 📊 FLUJO DE USO TÍPICO

1. **Cliente hace login** → Obtiene JWT
2. **GET /api/cart** → Ve su carrito (vacío o con items previos)
3. **POST /api/cart/items** → Agrega productos
   - Se valida stock
   - Se congela precio
   - Si ya existe, suma cantidad
4. **PATCH /api/cart/items/{id}** → Modifica cantidades
5. **DELETE /api/cart/items/{id}** → Elimina productos no deseados
6. **GET /api/cart** → Ve resumen final con totales
7. **POST /api/orders** *(futuro)* → Crea pedido desde el carrito
8. El carrito se vacía automáticamente al confirmar pedido

---

## 🎯 PRÓXIMO PASO

Implementar el **módulo Order Management** que:
- Leerá el carrito del usuario
- Validará stock completo con ProductService
- Creará el pedido
- Reducirá stock de productos
- Vaciará el carrito

---

## 📝 NOTAS TÉCNICAS

### Snapshots
Los campos `unit_price_snapshot` y `product_name_snapshot` congelan el precio y nombre al momento de agregar al carrito. Esto garantiza que:
- Si el precio cambia después, el carrito mantiene el precio original
- Si el producto se renombra, el carrito muestra el nombre original

### Optimización N+1
Usamos `@Query` con `JOIN FETCH` en:
```java
@Query("SELECT c FROM Cart c LEFT JOIN FETCH c.items WHERE c.userId = :userId")
Optional<Cart> findByUserIdWithItems(@Param("userId") Long userId);
```

Esto carga el carrito y todos sus items en una sola query, evitando el problema N+1.

### Validación de Stock
El stock se valida en dos momentos:
1. Al agregar al carrito (para no permitir agregar más de lo disponible)
2. Al crear el pedido (Order Management validará nuevamente)

No se **reserva** stock al agregar al carrito, solo se valida disponibilidad.

---

**Implementado por:** GitHub Copilot  
**Fecha:** 2025-11-04  
**Estado:** ✅ COMPLETADO - LISTO PARA PRUEBAS

---

## 📋 PROGRESO DEL PROYECTO

```
✅ User Management      [████████████████████] 100%
✅ Product Catalog      [████████████████████] 100%
✅ Cart                 [████████████████████] 100%
⏳ Order Management     [                    ]   0%
⏳ Shipping             [                    ]   0%

TOTAL: 60% COMPLETADO
```

