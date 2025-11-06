# 📚 Documentación Swagger - Virtual Pet E-Commerce API

## ✅ Swagger Implementado Exitosamente

Se ha configurado **SpringDoc OpenAPI 3** (Swagger) en toda la aplicación Virtual Pet.

---

## 🚀 Cómo Acceder a Swagger UI

### 1. Iniciar la Aplicación

```bash
./mvnw spring-boot:run
```

O si está compilada:

```bash
java -jar target/ecommerce-0.0.1-SNAPSHOT.jar
```

### 2. Acceder a Swagger UI

Una vez que la aplicación esté corriendo, abre tu navegador y accede a:

```
http://localhost:8080/swagger-ui.html
```

O también puedes usar:

```
http://localhost:8080/swagger-ui/index.html
```

### 3. Ver la especificación OpenAPI JSON

```
http://localhost:8080/api-docs
```

---

## 🔐 Autenticación con JWT en Swagger

### Pasos para probar endpoints protegidos:

#### 1. **Registrar un usuario** (si no tienes uno)
   - Expandir: **User Management → POST /api/users/register**
   - Click en "Try it out"
   - Ingresar datos:
```json
{
  "email": "test@example.com",
  "password": "password123",
  "firstName": "Test",
  "lastName": "User",
  "phone": "1234567890",
  "address": "Test Address 123"
}
```
   - Click "Execute"

#### 2. **Hacer Login**
   - Expandir: **User Management → POST /api/users/login**
   - Click en "Try it out"
   - Ingresar credenciales:
```json
{
  "email": "test@example.com",
  "password": "password123"
}
```
   - Click "Execute"
   - **Copiar el valor de `accessToken`** de la respuesta

#### 3. **Autorizar en Swagger**
   - Click en el botón **🔓 Authorize** (esquina superior derecha)
   - En el campo "Value", pegar: `Bearer {tu-token-jwt}`
   - Ejemplo: `Bearer eyJhbGciOiJIUzUxMiJ9...`
   - Click "Authorize"
   - Click "Close"

#### 4. **Probar Endpoints Protegidos**
   Ahora puedes probar cualquier endpoint que requiera autenticación:
   - GET /api/users/profile
   - GET /api/cart
   - POST /api/cart/items
   - POST /api/orders
   - etc.

---

## 📋 Endpoints Documentados

### ✅ Módulos Incluidos en Swagger:

| Módulo | Tag en Swagger | Endpoints |
|--------|----------------|-----------|
| **User Management** | User Management | 4 endpoints |
| **Product Catalog** | Product Catalog | 3 endpoints |
| **Categories** | Categories | 3 endpoints |
| **Cart** | Cart | 5 endpoints |
| **Orders (Client)** | Orders - Client | 4 endpoints |
| **Orders (Backoffice)** | Orders - Backoffice | 7 endpoints |

### 🔓 Endpoints Públicos (no requieren autenticación):
- `POST /api/users/register` - Registrar nuevo usuario
- `POST /api/users/login` - Iniciar sesión
- `GET /api/products` - Listar productos
- `GET /api/products/{id}` - Detalle de producto
- `GET /api/categories` - Listar categorías
- `GET /api/categories/{id}` - Detalle de categoría
- `GET /api/categories/{id}/products` - Productos por categoría

### 🔒 Endpoints Protegidos (requieren JWT):
- **User Management:**
  - `GET /api/users/profile` - Ver perfil
  - `PATCH /api/users/profile` - Actualizar perfil

- **Cart:**
  - `GET /api/cart` - Ver carrito
  - `POST /api/cart/items` - Agregar al carrito
  - `PATCH /api/cart/items/{productId}` - Actualizar cantidad
  - `DELETE /api/cart/items/{productId}` - Eliminar producto
  - `DELETE /api/cart/clear` - Vaciar carrito

- **Orders (CLIENT role):**
  - `POST /api/orders` - Crear pedido
  - `GET /api/orders` - Listar mis pedidos
  - `GET /api/orders/{id}` - Detalle de pedido
  - `PATCH /api/orders/{id}/cancel` - Cancelar pedido

- **Backoffice (WAREHOUSE role):**
  - `GET /api/backoffice/orders` - Listar todos los pedidos
  - `GET /api/backoffice/orders/{id}` - Detalle de cualquier pedido
  - `PATCH /api/backoffice/orders/{id}/ready-to-ship` - Marcar listo para envío
  - `PATCH /api/backoffice/orders/{id}/ship` - Marcar como despachado
  - `PATCH /api/backoffice/orders/{id}/deliver` - Marcar como entregado
  - `PATCH /api/backoffice/orders/{id}/shipping-method` - Actualizar método de envío
  - `PATCH /api/backoffice/orders/{id}/reject` - Rechazar pedido

---

## 🛠️ Configuración Implementada

### Dependencia Agregada en `pom.xml`:
```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.3.0</version>
</dependency>
```

### Configuración en `application.properties`:
```properties
# Ruta de la documentación OpenAPI JSON
springdoc.api-docs.path=/api-docs

# Ruta de Swagger UI
springdoc.swagger-ui.path=/swagger-ui.html

# Ordenar endpoints por método HTTP
springdoc.swagger-ui.operations-sorter=method

# Ordenar tags alfabéticamente
springdoc.swagger-ui.tags-sorter=alpha

# Habilitar filtro de búsqueda
springdoc.swagger-ui.filter=true

# Mostrar duración de requests
springdoc.swagger-ui.display-request-duration=true

# Paths a escanear
springdoc.packages-to-scan=com.virtualpet.ecommerce.modules

# Paths a incluir
springdoc.paths-to-match=/api/**
```

### Clase de Configuración: `OpenApiConfig.java`
- Define información general de la API (título, versión, descripción, contacto, licencia)
- Configura el esquema de seguridad JWT (Bearer Authentication)
- Define el servidor local

### Seguridad Actualizada en `SecurityConfig.java`:
Se agregaron las rutas de Swagger a los endpoints públicos:
```java
.requestMatchers("/swagger-ui/**", "/v3/api-docs/**", "/swagger-ui.html", "/api-docs/**").permitAll()
```

---

## 📝 Anotaciones Utilizadas

Todos los controllers fueron documentados con las siguientes anotaciones de OpenAPI:

- `@Tag` - Agrupa endpoints por módulo
- `@Operation` - Describe cada endpoint
- `@ApiResponses` / `@ApiResponse` - Documenta respuestas posibles
- `@Parameter` - Describe parámetros de entrada
- `@SecurityRequirement` - Indica que requiere JWT
- `@Schema` - Define el esquema de DTOs en las respuestas

---

## 🎯 Beneficios

✅ **Documentación Interactiva**: Prueba todos los endpoints directamente desde el navegador  
✅ **Autenticación JWT Integrada**: Configura el token una vez y prueba todos los endpoints protegidos  
✅ **Validación en Tiempo Real**: Ve los esquemas de Request/Response  
✅ **Exportable**: La especificación OpenAPI JSON se puede exportar para uso en Postman u otras herramientas  
✅ **Actualización Automática**: La documentación se actualiza automáticamente con cambios en el código  

---

## 🔄 Flujo de Prueba Completo en Swagger

1. **Registrar usuario** → Obtener credenciales
2. **Login** → Copiar JWT token
3. **Autorizar en Swagger** → Pegar token
4. **Listar productos** → Seleccionar uno
5. **Agregar al carrito** → Verificar carrito
6. **Crear pedido** → Obtener ID del pedido
7. **Ver mis pedidos** → Confirmar creación
8. **Cancelar pedido** (opcional) → Verificar estado

### Para probar Backoffice:
1. Crear usuario WAREHOUSE en BD
2. Login con usuario WAREHOUSE
3. Autorizar con el nuevo token
4. Probar endpoints de `/api/backoffice/orders`

---

## 📌 Notas Importantes

- **Puerto**: La aplicación corre en `http://localhost:8080`
- **Base de Datos**: Debe estar corriendo PostgreSQL con la BD `virtualpet`
- **Tokens JWT**: Expiran en 1 hora (configurable en `application.properties`)
- **CORS**: Configurado para aceptar cualquier origen (cambiar en producción)

---

## 🆘 Solución de Problemas

### Error: "Cannot resolve symbol 'swagger'"
Ejecutar en terminal:
```bash
./mvnw clean install
```

### Swagger UI no carga
Verificar que la aplicación esté corriendo:
```bash
curl http://localhost:8080/actuator/health
```

### Token JWT inválido
- Verificar que el token no haya expirado
- Asegurarse de incluir el prefijo "Bearer " antes del token
- Re-autenticar y obtener un nuevo token

---

## 📖 Recursos Adicionales

- [SpringDoc OpenAPI Documentation](https://springdoc.org/)
- [OpenAPI Specification](https://swagger.io/specification/)
- [JWT.io - Debugger](https://jwt.io/)

---

**¡Documentación Swagger Completa! 🎉**

Ahora puedes explorar y probar todos los endpoints de Virtual Pet E-Commerce de forma interactiva.

