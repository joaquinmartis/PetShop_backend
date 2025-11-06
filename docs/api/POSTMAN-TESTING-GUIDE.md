# 🧪 Guía de Testing con Postman - Virtual Pet API

## 📋 Pasos para Probar la API

### 1. **Recompilar y Reiniciar la Aplicación**

```bash
cd /home/optimus/Desktop/VirtualPet
mvn clean install -DskipTests
mvn spring-boot:run
```

### 2. **Verificar que la API esté corriendo**

Abre tu navegador y accede a:
- **Swagger UI**: http://localhost:8080/swagger-ui.html
- **OpenAPI JSON**: http://localhost:8080/v3/api-docs

Si ves el JSON de OpenAPI, ¡la API está funcionando! 🎉

---

## 📦 Importar Colección en Postman

### Opción 1: Importar desde archivo JSON

1. Abre **Postman**
2. Click en **Import** (esquina superior izquierda)
3. Selecciona el archivo: `VirtualPet-Postman-Collection.json`
4. Click en **Import**

### Opción 2: Importar desde OpenAPI (Recomendado)

1. Abre **Postman**
2. Click en **Import**
3. Selecciona **Link**
4. Pega: `http://localhost:8080/v3/api-docs`
5. Click en **Continue** → **Import**

---

## 🚀 Flujo de Pruebas Recomendado

### **Paso 1: Registrar un Usuario**
```
POST http://localhost:8080/api/users/register

Body (JSON):
{
  "email": "test@example.com",
  "password": "password123",
  "firstName": "Test",
  "lastName": "User",
  "phone": "1234567890",
  "address": "123 Test Street"
}
```
✅ **Esperado**: Status 201 Created

---

### **Paso 2: Login**
```
POST http://localhost:8080/api/users/login

Body (JSON):
{
  "email": "test@example.com",
  "password": "password123"
}
```
✅ **Esperado**: Status 200 + Token JWT

**⚠️ IMPORTANTE**: Copia el `accessToken` de la respuesta. Lo necesitarás para los siguientes requests.

---

### **Paso 3: Listar Productos (Público)**
```
GET http://localhost:8080/api/products?page=0&size=10
```
✅ **Esperado**: Status 200 + Lista de productos

No requiere autenticación ✓

---

### **Paso 4: Ver Perfil (Protegido)**
```
GET http://localhost:8080/api/users/profile

Headers:
Authorization: Bearer {TU_TOKEN_AQUI}
```
✅ **Esperado**: Status 200 + Datos del usuario

---

### **Paso 5: Agregar Producto al Carrito**
```
POST http://localhost:8080/api/cart/items

Headers:
Authorization: Bearer {TU_TOKEN_AQUI}

Body (JSON):
{
  "productId": 1,
  "quantity": 2
}
```
✅ **Esperado**: Status 200 + Carrito actualizado

---

### **Paso 6: Ver Carrito**
```
GET http://localhost:8080/api/cart

Headers:
Authorization: Bearer {TU_TOKEN_AQUI}
```
✅ **Esperado**: Status 200 + Contenido del carrito

---

### **Paso 7: Crear Pedido**
```
POST http://localhost:8080/api/orders

Headers:
Authorization: Bearer {TU_TOKEN_AQUI}

Body (JSON):
{
  "shippingAddress": "123 Test Street, Mar del Plata",
  "shippingMethod": "STANDARD",
  "paymentMethod": "CREDIT_CARD"
}
```
✅ **Esperado**: Status 201 + Pedido creado

---

### **Paso 8: Ver Mis Pedidos**
```
GET http://localhost:8080/api/orders

Headers:
Authorization: Bearer {TU_TOKEN_AQUI}
```
✅ **Esperado**: Status 200 + Lista de pedidos

---

## 🔐 Testing de Seguridad

### Test 1: Acceder sin Token (debe fallar)
```
GET http://localhost:8080/api/users/profile
```
❌ **Esperado**: Status 401 o 403

---

### Test 2: Token Inválido (debe fallar)
```
GET http://localhost:8080/api/users/profile

Headers:
Authorization: Bearer token_invalido_123
```
❌ **Esperado**: Status 401

---

### Test 3: Registro con Email Duplicado (debe fallar)
```
POST http://localhost:8080/api/users/register

Body (JSON):
{
  "email": "test@example.com",  // Email ya registrado
  "password": "password123",
  "firstName": "Test",
  "lastName": "User",
  "phone": "1234567890",
  "address": "123 Test Street"
}
```
❌ **Esperado**: Status 409 Conflict

---

## 🏢 Testing de Backoffice (WAREHOUSE)

Para probar los endpoints de backoffice, necesitas un usuario con rol WAREHOUSE:

### 1. Crear usuario WAREHOUSE en la DB:
```sql
PGPASSWORD=virtualpet123 psql -U virtualpet_user -d virtualpet -h localhost -f create-warehouse-user.sql
```

### 2. Login con usuario WAREHOUSE:
```
POST http://localhost:8080/api/users/login

Body (JSON):
{
  "email": "warehouse@test.com",
  "password": "warehouse123"
}
```

### 3. Ver Todos los Pedidos (Admin):
```
GET http://localhost:8080/api/backoffice/orders

Headers:
Authorization: Bearer {TOKEN_WAREHOUSE}
```
✅ **Esperado**: Status 200 + Todos los pedidos

---

## 📊 Variables de Entorno en Postman

La colección incluye variables automáticas:

- `{{baseUrl}}`: http://localhost:8080/api
- `{{token}}`: Se guarda automáticamente al hacer login
- `{{userId}}`: Se guarda automáticamente al registrarse
- `{{orderId}}`: Se guarda automáticamente al crear un pedido

---

## 🐛 Solución de Problemas

### Error: "Failed to load API definition" en Swagger
**Solución**: 
1. Detener la aplicación
2. Recompilar: `mvn clean install -DskipTests`
3. Reiniciar: `mvn spring-boot:run`
4. Intentar de nuevo: http://localhost:8080/swagger-ui.html

---

### Error: 401 Unauthorized
**Causa**: Token JWT inválido o expirado (expira en 1 hora)

**Solución**: Hacer login nuevamente y obtener un nuevo token

---

### Error: 403 Forbidden
**Causa**: El usuario no tiene permisos para acceder al recurso

**Solución**: 
- Para endpoints de backoffice, usar un usuario con rol WAREHOUSE
- Para endpoints de cliente, usar un usuario con rol CLIENT

---

### Error: 500 Internal Server Error en /v3/api-docs
**Solución aplicada**: 
- ✅ Actualizada versión de SpringDoc a 2.7.0
- ✅ Configurado escaneo solo de módulos (no config)
- ✅ Agregado GroupedOpenApi para mejor control

---

## 📝 Códigos de Respuesta Esperados

| Código | Significado | Cuándo se usa |
|--------|-------------|---------------|
| 200 | OK | Operación exitosa (GET, PATCH, DELETE) |
| 201 | Created | Recurso creado exitosamente (POST) |
| 400 | Bad Request | Datos de entrada inválidos |
| 401 | Unauthorized | Token inválido o ausente |
| 403 | Forbidden | Sin permisos para el recurso |
| 404 | Not Found | Recurso no encontrado |
| 409 | Conflict | Conflicto (ej: email duplicado) |
| 500 | Internal Server Error | Error del servidor |

---

## ✅ Checklist de Pruebas

- [ ] Registrar usuario CLIENT
- [ ] Login con usuario CLIENT
- [ ] Ver perfil autenticado
- [ ] Actualizar perfil
- [ ] Listar productos (público)
- [ ] Listar categorías (público)
- [ ] Agregar productos al carrito
- [ ] Ver carrito
- [ ] Actualizar cantidad en carrito
- [ ] Crear pedido
- [ ] Ver mis pedidos
- [ ] Cancelar pedido
- [ ] Login con usuario WAREHOUSE
- [ ] Ver todos los pedidos (admin)
- [ ] Marcar pedido como listo para enviar
- [ ] Marcar pedido como despachado
- [ ] Marcar pedido como entregado
- [ ] Rechazar pedido

---

## 🎯 Tests de Seguridad

- [ ] Intentar acceder a /profile sin token (debe fallar)
- [ ] Intentar acceder con token inválido (debe fallar)
- [ ] Intentar acceder a /backoffice sin rol WAREHOUSE (debe fallar)
- [ ] Registrar email duplicado (debe fallar con 409)
- [ ] Login con contraseña incorrecta (debe fallar con 401)
- [ ] Agregar producto sin stock (debe fallar)
- [ ] Cancelar pedido ya despachado (debe fallar)

---

## 📞 Soporte

Si encuentras algún error, verifica:
1. La aplicación esté corriendo en puerto 8080
2. PostgreSQL esté corriendo y accesible
3. El token JWT no haya expirado (expira en 1 hora)
4. Los datos de ejemplo en la DB existan

---

**¡Buena suerte con las pruebas! 🚀**

