# 🐾 Virtual Pet E-Commerce API

![Java](https://img.shields.io/badge/Java-21-orange)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5.7-brightgreen)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

API REST de e-commerce para productos de mascotas, construida con arquitectura modular y buenas prácticas de desarrollo.

---

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Tecnologías](#-tecnologías)
- [Arquitectura](#-arquitectura)
- [Instalación](#-instalación)
- [Configuración](#-configuración)
- [Uso](#-uso)
- [API Endpoints](#-api-endpoints)
- [Testing](#-testing)
- [Documentación](#-documentación)
- [Estructura del Proyecto](#-estructura-del-proyecto)

---

## ✨ Características

- ✅ **Autenticación JWT** - Sistema seguro de autenticación y autorización
- ✅ **Roles de Usuario** - CLIENT y WAREHOUSE con permisos diferenciados
- ✅ **Gestión de Productos** - Catálogo completo con categorías y búsqueda
- ✅ **Carrito de Compras** - Sistema de carrito persistente
- ✅ **Gestión de Pedidos** - Flujo completo desde creación hasta entrega
- ✅ **Control de Stock** - Gestión automática de inventario
- ✅ **Paginación y Filtros** - Consultas optimizadas con filtros avanzados
- ✅ **Documentación Swagger** - API documentada con OpenAPI 3.0
- ✅ **Manejo de Errores** - Respuestas de error estandarizadas
- ✅ **Tests Automatizados** - Suite completa de testing (100+ tests)

---

## 🚀 Tecnologías

### Backend
- **Java 21** - Lenguaje de programación
- **Spring Boot 3.5.7** - Framework principal
- **Spring Data JPA** - Persistencia de datos
- **Spring Security** - Seguridad y autenticación
- **JWT (jsonwebtoken)** - Tokens de autenticación

### Base de Datos
- **PostgreSQL 14** - Base de datos relacional
- **Flyway/Liquibase** - Migraciones de BD (opcional)

### Documentación
- **Springdoc OpenAPI** - Documentación Swagger
- **Postman Collection** - Colección de endpoints

### Testing
- **JUnit 5** - Framework de testing
- **Bash Scripts** - Tests de integración E2E

---

## 🏗️ Arquitectura

### Patrón: Monolito Modular

El proyecto está organizado en **4 módulos independientes**:

```
├── modules/
│   ├── user/          # Gestión de usuarios y autenticación
│   ├── product/       # Catálogo de productos y categorías
│   ├── cart/          # Carrito de compras
│   └── order/         # Gestión de pedidos (cliente y warehouse)
```

### Capas por Módulo
- **Controller** - Endpoints REST
- **Service** - Lógica de negocio
- **Repository** - Acceso a datos
- **DTO** - Objetos de transferencia
- **Entity** - Entidades JPA

### Base de Datos
Cada módulo tiene su propio **schema en PostgreSQL**:
- `user_management` - Usuarios y roles
- `product_catalog` - Productos y categorías
- `cart` - Carritos y items
- `order_management` - Pedidos e historial

---

## 📦 Instalación

### Prerequisitos
- Java 21 o superior
- PostgreSQL 14 o superior
- Maven 3.8+

### 1. Clonar el repositorio
```bash
git clone https://github.com/tu-usuario/virtual-pet.git
cd virtual-pet
```

### 2. Configurar base de datos
```bash
# Crear base de datos
createdb virtualpet

# Crear usuario
psql -U postgres
CREATE USER virtualpet_user WITH PASSWORD 'virtualpet123';
GRANT ALL PRIVILEGES ON DATABASE virtualpet TO virtualpet_user;
```

### 3. Ejecutar scripts de inicialización
```bash
psql -U virtualpet_user -d virtualpet -f scripts/setup/create-test-user.sql
psql -U virtualpet_user -d virtualpet -f scripts/setup/create-warehouse-user.sql
```

### 4. Compilar el proyecto
```bash
mvn clean install
```

### 5. Ejecutar la aplicación
```bash
mvn spring-boot:run
```

La aplicación estará disponible en: `http://localhost:8080`

---

## ⚙️ Configuración

### 🔐 Variables de Entorno (RECOMENDADO)

**⚠️ IMPORTANTE:** Por seguridad, NO uses credenciales hardcodeadas. Usa variables de entorno.

#### Desarrollo Local

1. **Copiar archivo de ejemplo:**
```bash
cp .env.example .env
```

2. **Editar `.env` con tus credenciales:**
```bash
DB_USERNAME=virtualpet_user
DB_PASSWORD=virtualpet123
JWT_SECRET=miClaveSecretaSuperSeguraDeAlMenos256BitsParaFirmarTokensJWT123456789
JWT_EXPIRATION=3600000
```

3. **Cargar variables:**
```bash
export $(cat .env | xargs)
```

#### Producción

**NUNCA uses las credenciales de desarrollo en producción.**

Genera un JWT secret seguro:
```bash
openssl rand -base64 64
```

Configura las variables según tu plataforma:
- **Heroku:** `heroku config:set JWT_SECRET=...`
- **AWS:** AWS Systems Manager Parameter Store
- **Docker:** Variables en `docker-compose.yml`
- **Kubernetes:** ConfigMaps y Secrets

📚 **Ver guía completa:** [CONFIGURATION.md](CONFIGURATION.md)

### application.properties

El archivo `application.properties` usa variables de entorno con valores por defecto:

```properties
# Base de datos
spring.datasource.url=jdbc:postgresql://localhost:5432/virtualpet
spring.datasource.username=${DB_USERNAME:virtualpet_user}
spring.datasource.password=${DB_PASSWORD:changeme}

# JWT
jwt.secret=${JWT_SECRET:CHANGE_THIS_SECRET_IN_PRODUCTION}
jwt.expiration=${JWT_EXPIRATION:3600000}

# JWT
jwt.secret=tu-clave-secreta-segura-de-al-menos-256-bits
jwt.expiration=3600000

# Server
server.port=8080
```

### Variables de Entorno (Producción)
```bash
export DB_URL=jdbc:postgresql://localhost:5432/virtualpet
export DB_USERNAME=virtualpet_user
export DB_PASSWORD=virtualpet123
export JWT_SECRET=tu-clave-secreta-muy-segura
```

---

## 💻 Uso

### Iniciar servidor
```bash
mvn spring-boot:run
```

### Acceder a Swagger UI
```
http://localhost:8080/swagger-ui.html
```

### Flujo básico de uso

#### 1. Registrar usuario
```bash
curl -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "cliente@example.com",
    "password": "password123",
    "firstName": "Juan",
    "lastName": "Pérez",
    "phone": "1234567890",
    "address": "Calle 123"
  }'
```

#### 2. Login
```bash
curl -X POST http://localhost:8080/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "cliente@example.com",
    "password": "password123"
  }'
```

#### 3. Listar productos
```bash
curl http://localhost:8080/api/products
```

#### 4. Agregar al carrito
```bash
curl -X POST http://localhost:8080/api/cart/items \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": 1,
    "quantity": 2
  }'
```

#### 5. Crear pedido
```bash
curl -X POST http://localhost:8080/api/orders \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "shippingAddress": "Av. Libertador 1234"
  }'
```

---

## 📡 API Endpoints

### 🔐 User Management
| Método | Endpoint | Descripción | Auth |
|--------|----------|-------------|------|
| POST | `/api/users/register` | Registrar usuario | No |
| POST | `/api/users/login` | Iniciar sesión | No |
| GET | `/api/users/profile` | Obtener perfil | JWT |
| PATCH | `/api/users/profile` | Actualizar perfil | JWT |

### 📦 Product Catalog
| Método | Endpoint | Descripción | Auth |
|--------|----------|-------------|------|
| GET | `/api/products` | Listar productos | No |
| GET | `/api/products/{id}` | Detalle de producto | No |
| GET | `/api/categories` | Listar categorías | No |
| GET | `/api/categories/{id}` | Detalle de categoría | No |
| GET | `/api/categories/{id}/products` | Productos por categoría | No |

### 🛒 Cart
| Método | Endpoint | Descripción | Auth |
|--------|----------|-------------|------|
| GET | `/api/cart` | Ver carrito | JWT |
| POST | `/api/cart/items` | Agregar producto | JWT |
| PATCH | `/api/cart/items/{productId}` | Actualizar cantidad | JWT |
| DELETE | `/api/cart/items/{productId}` | Eliminar producto | JWT |
| DELETE | `/api/cart/clear` | Vaciar carrito | JWT |

### 📋 Orders (Cliente)
| Método | Endpoint | Descripción | Auth |
|--------|----------|-------------|------|
| POST | `/api/orders` | Crear pedido | JWT |
| GET | `/api/orders` | Mis pedidos | JWT |
| GET | `/api/orders/{id}` | Detalle de pedido | JWT |
| PATCH | `/api/orders/{id}/cancel` | Cancelar pedido | JWT |

### 🏢 Orders (Backoffice - WAREHOUSE)
| Método | Endpoint | Descripción | Auth |
|--------|----------|-------------|------|
| GET | `/api/backoffice/orders` | Listar todos | JWT + WAREHOUSE |
| GET | `/api/backoffice/orders/{id}` | Detalle | JWT + WAREHOUSE |
| PATCH | `/api/backoffice/orders/{id}/ready-to-ship` | Marcar listo | JWT + WAREHOUSE |
| PATCH | `/api/backoffice/orders/{id}/shipping-method` | Asignar método | JWT + WAREHOUSE |
| PATCH | `/api/backoffice/orders/{id}/ship` | Despachar | JWT + WAREHOUSE |
| PATCH | `/api/backoffice/orders/{id}/deliver` | Entregar | JWT + WAREHOUSE |
| PATCH | `/api/backoffice/orders/{id}/reject` | Rechazar | JWT + WAREHOUSE |

Ver documentación completa en: [docs/api/](docs/api/)

---

## 🧪 Testing

### Tests Unitarios
```bash
mvn test
```

### Tests de Integración (E2E)
```bash
# Todos los tests
./scripts/setup/run-all-tests.sh

# Por módulo
cd docs/testing
./test-user-exhaustive.sh
./test-product-exhaustive.sh
./test-cart-exhaustive.sh
./test-order-client-exhaustive.sh
./test-order-backoffice-exhaustive.sh
```

### Cobertura de Tests
- **User Module**: 100% ✅
- **Product Catalog**: 95% ✅
- **Cart**: 100% ✅
- **Order Client**: 100% ✅
- **Order Backoffice**: 100% ✅
- **E2E Flows**: 100% ✅

**Total: ~98% de cobertura funcional**

Ver reportes en: [docs/reports/](docs/reports/)

---

## 📚 Documentación

### Documentación de API
- [Swagger UI](http://localhost:8080/swagger-ui.html)
- [OpenAPI JSON](http://localhost:8080/v3/api-docs)
- [Postman Collection](docs/api/VirtualPet-Postman-Collection.json)
- [Endpoints Documentation](docs/api/)

### Arquitectura
- [Modelo C4](docs/architecture/README-ARQUITECTURA-C4.md)
- [Diagramas DSL](docs/architecture/)

### Guías
- [Guía de Testing](docs/testing/TESTING-GUIDE-COMPLETE.md)
- [Flujo del Sistema](docs/api/FLUJO-COMPLETO-SISTEMA.md)
- [Resultados de Tests](docs/reports/)

---

## 📁 Estructura del Proyecto

```
VirtualPet/
├── src/
│   ├── main/
│   │   ├── java/com/virtualpet/ecommerce/
│   │   │   ├── VirtualPetApplication.java
│   │   │   ├── config/              # Configuración
│   │   │   ├── modules/             # Módulos de negocio
│   │   │   │   ├── user/
│   │   │   │   ├── product/
│   │   │   │   ├── cart/
│   │   │   │   └── order/
│   │   │   └── security/            # Seguridad JWT
│   │   └── resources/
│   │       └── application.properties
│   └── test/                        # Tests unitarios
├── docs/
│   ├── api/                         # Documentación API
│   ├── architecture/                # Arquitectura C4
│   ├── testing/                     # Scripts de tests
│   └── reports/                     # Reportes
├── scripts/
│   └── setup/                       # Scripts de configuración
├── target/                          # Build output
├── pom.xml                          # Maven dependencies
└── README.md                        # Este archivo
```

---

## 🔒 Seguridad

- ✅ Autenticación JWT
- ✅ Passwords hasheados con BCrypt
- ✅ Validación de tokens en cada request
- ✅ Control de acceso por roles (CLIENT, WAREHOUSE)
- ✅ Protección CSRF
- ✅ Validación de entrada en todos los endpoints

---

## 🚀 Deployment

### Producción con Docker (futuro)
```bash
docker build -t virtual-pet-api .
docker run -p 8080:8080 virtual-pet-api
```

### Variables de entorno requeridas
- `DB_URL` - URL de PostgreSQL
- `DB_USERNAME` - Usuario de BD
- `DB_PASSWORD` - Password de BD
- `JWT_SECRET` - Clave secreta JWT (mínimo 256 bits)

---

## 📈 Estado del Proyecto

✅ **PRODUCCIÓN READY**

- Funcionalidad: **98%** completada
- Tests: **100+** automatizados
- Cobertura: **~95%** de funcionalidad core
- Documentación: **Completa**

---

## 👥 Contribución

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 📞 Contacto

- **Proyecto**: Virtual Pet E-Commerce API
- **Versión**: 1.0.0
- **Última actualización**: Noviembre 2025

---

## 🙏 Agradecimientos

- Spring Boot team
- PostgreSQL community
- Todos los contribuidores del proyecto

---

**¡Hecho con ❤️ y ☕ para amantes de las mascotas!** 🐾

