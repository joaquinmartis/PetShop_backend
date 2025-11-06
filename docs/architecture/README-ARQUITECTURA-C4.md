# 📐 Documentación de Arquitectura C4 - Índice Principal

## 🎯 Inicio Rápido

**¿Primera vez aquí?** → Comienza con [`C4-QUICKSTART.md`](C4-QUICKSTART.md)

**¿Quieres ver diagramas ahora?** → 
1. Ve a https://structurizr.com
2. Copia el contenido de [`structurizr-c4-model.dsl`](structurizr-c4-model.dsl)
3. Pégalo en un nuevo workspace

---

## 📚 Archivos de Documentación

### 🚀 Para Empezar

| Archivo | Descripción | Para Quién |
|---------|-------------|------------|
| [`C4-QUICKSTART.md`](C4-QUICKSTART.md) | Guía rápida de 5 minutos | Todos |
| [`ARQUITECTURA-ASCII.md`](ARQUITECTURA-ASCII.md) | Vista rápida en texto | Desarrolladores |
| [`ARQUITECTURA-C4-INDEX.md`](ARQUITECTURA-C4-INDEX.md) | Índice completo y estadísticas | Product Managers, Arquitectos |

### 🏗️ Modelos C4

| Archivo | Formato | Herramienta | Descripción |
|---------|---------|-------------|-------------|
| [`structurizr-c4-model.dsl`](structurizr-c4-model.dsl) | DSL | Structurizr | **Modelo completo** con 12 vistas (Niveles 1-3) |
| [`C4-LEVEL4-CODE-CARTSERVICE.md`](C4-LEVEL4-CODE-CARTSERVICE.md) | PlantUML | VSCode/Online | **Nivel 4: Code** - Diagrama UML de CartService |
| [`c4-plantuml-diagrams.md`](c4-plantuml-diagrams.md) | PlantUML | VSCode/Online | Diagramas alternativos para Markdown |

### 📖 Documentación Detallada

| Archivo | Contenido |
|---------|-----------|
| [`ARQUITECTURA-MODULAR.md`](ARQUITECTURA-MODULAR.md) | Explicación profunda del código, patrones, flujos |
| [`C4-MODEL-README.md`](C4-MODEL-README.md) | Guía de uso de Structurizr, instalación, tips |

---

## 🎨 Vistas Disponibles

### Modelo Structurizr (12 vistas)

#### Nivel 1: System Context
- ✅ `SystemContext` - Visión general del sistema

#### Nivel 2: Container
- ✅ `Containers` - Aplicaciones y base de datos

#### Nivel 3: Component (7 vistas)
- ✅ `Components-All` - Vista completa
- ✅ `Components-UserManagement` - Módulo de usuarios
- ✅ `Components-ProductCatalog` - Módulo de productos
- ✅ `Components-Cart` - Módulo de carrito
- ✅ `Components-OrderManagement` - Módulo de pedidos
- ✅ `Components-Security` - Seguridad y JWT
- ✅ `Components-CreateOrderFlow` - Flujo de crear pedido

#### Nivel 4: Code (UML Detallado)
- ✅ `CartService` - Diagrama UML de clase CartService ([Ver documento](C4-LEVEL4-CODE-CARTSERVICE.md))

#### Nivel Dinámico (3 secuencias)
- ✅ `CreateOrder-Sequence` - Flujo completo de pedido
- ✅ `AddToCart-Sequence` - Agregar producto al carrito
- ✅ `Login-Sequence` - Autenticación JWT

### Diagramas PlantUML (6 diagramas)
- Component Diagram completo
- Component Diagram: Cart Module
- Component Diagram: Order Module
- Sequence: Crear Pedido
- Sequence: Login JWT
- Sequence: Agregar al Carrito

---

## 🗺️ Guía por Rol

### 👨‍💻 Desarrollador

**Tu objetivo:** Entender el código y dónde hacer cambios

1. **Lee primero:** [`ARQUITECTURA-MODULAR.md`](ARQUITECTURA-MODULAR.md)
   - Sección "Relaciones Controller-Service"
   - Ejemplos de código reales

2. **Visualiza:** [`structurizr-c4-model.dsl`](structurizr-c4-model.dsl)
   - Vista `Components-All`
   - Vista del módulo en el que trabajas

3. **Referencia rápida:** [`ARQUITECTURA-ASCII.md`](ARQUITECTURA-ASCII.md)
   - Diagrama de componentes
   - APIs públicas

**Archivos útiles:**
- `structurizr-c4-model.dsl` → Vista `Components-Cart` (ejemplo)
- `ARQUITECTURA-MODULAR.md` → Sección "Caso 1: CartController"
- `c4-plantuml-diagrams.md` → Secuencias paso a paso

---

### 👨‍💼 Arquitecto de Software

**Tu objetivo:** Diseño de alto nivel, decisiones técnicas

1. **Empieza con:** [`ARQUITECTURA-C4-INDEX.md`](ARQUITECTURA-C4-INDEX.md)
   - Resumen ejecutivo
   - Estadísticas del sistema

2. **Visualiza en Structurizr:**
   - `SystemContext` → Límites del sistema
   - `Containers` → Arquitectura de contenedores
   - `Components-All` → Estructura interna

3. **Lee patrones:** [`ARQUITECTURA-MODULAR.md`](ARQUITECTURA-MODULAR.md)
   - Sección "Patrones de Diseño"
   - Sección "Comunicación entre Módulos"

**Archivos útiles:**
- `structurizr-c4-model.dsl` → Todas las vistas
- `ARQUITECTURA-MODULAR.md` → Sección "Conclusión"
- `ARQUITECTURA-C4-INDEX.md` → Sección "Próximos Pasos"

---

### 🧪 QA / Tester

**Tu objetivo:** Identificar flujos críticos para testing

1. **Visualiza secuencias:** [`c4-plantuml-diagrams.md`](c4-plantuml-diagrams.md)
   - Sequence: Crear Pedido (flujo más complejo)
   - Sequence: Agregar al Carrito
   - Sequence: Login JWT

2. **Identifica componentes:** [`ARQUITECTURA-ASCII.md`](ARQUITECTURA-ASCII.md)
   - Flujo de crear pedido paso a paso
   - APIs públicas entre módulos

3. **Lee casos de uso:** [`ARQUITECTURA-MODULAR.md`](ARQUITECTURA-MODULAR.md)
   - Sección "Flujos de Datos"

**Archivos útiles:**
- `c4-plantuml-diagrams.md` → Todos los sequence diagrams
- `ARQUITECTURA-MODULAR.md` → Sección "Flujos de Datos Principales"
- `structurizr-c4-model.dsl` → Vistas dinámicas

---

### 📊 Product Manager

**Tu objetivo:** Entender funcionalidades y scope

1. **Vista general:** [`ARQUITECTURA-ASCII.md`](ARQUITECTURA-ASCII.md)
   - System Context
   - Container Diagram
   - Estadísticas

2. **Módulos por funcionalidad:** [`ARQUITECTURA-C4-INDEX.md`](ARQUITECTURA-C4-INDEX.md)
   - Lista de módulos
   - Endpoints por módulo

3. **Visualización:** `structurizr-c4-model.dsl` en Structurizr
   - `SystemContext` → Qué hace el sistema
   - Vistas de componentes filtradas por módulo

**Archivos útiles:**
- `ARQUITECTURA-ASCII.md` → Estadísticas del sistema
- `ARQUITECTURA-C4-INDEX.md` → Resumen ejecutivo
- `C4-QUICKSTART.md` → Cómo visualizar sin código

---

## 🎓 Recursos de Aprendizaje

### C4 Model
- 📖 [Sitio oficial](https://c4model.com/)
- 📺 [Video introducción](https://www.youtube.com/watch?v=x2-rSnhpw0g)
- 📝 [Cheat Sheet](https://c4model.com/#Notation)

### Structurizr
- 📖 [DSL Language Reference](https://github.com/structurizr/dsl/tree/master/docs)
- 📺 [Tutorial completo](https://www.youtube.com/watch?v=f-KtQEbgYvQ)
- 🌐 [Structurizr.com](https://structurizr.com/)

### PlantUML
- 📖 [Guía oficial](https://plantuml.com/guide)
- 📖 [C4-PlantUML](https://github.com/plantuml-stdlib/C4-PlantUML)
- 🌐 [Editor online](http://www.plantuml.com/plantuml/)

---

## 🔧 Herramientas Recomendadas

### Para Visualización
1. **Structurizr Online** (Recomendado)
   - ✅ Sin instalación
   - ✅ Interactivo
   - ✅ Exporta PNG/SVG
   - 🌐 https://structurizr.com

2. **Structurizr Lite** (Local)
   ```bash
   docker run -it --rm -p 8080:8080 \
     -v $(pwd):/usr/local/structurizr \
     structurizr/lite
   ```

3. **PlantUML en VSCode**
   - Instalar extensión "PlantUML" por jebbs
   - Abrir `.md` y presionar `Alt+D`

### Para Edición
- **VSCode**: Para editar `.dsl` y `.md`
- **IntelliJ IDEA**: Con plugin PlantUML
- **Editor online**: https://structurizr.com (modo DSL)

---

## 📊 Resumen del Sistema

```
┌──────────────────────────────────────────┐
│    VIRTUAL PET E-COMMERCE SYSTEM         │
├──────────────────────────────────────────┤
│  Tipo:        Monolito Modular           │
│  Tecnología:  Spring Boot 3.5.7          │
│  Base de Datos: PostgreSQL 14            │
│  Seguridad:   JWT + Spring Security      │
│  Puerto:      8080                       │
├──────────────────────────────────────────┤
│  📦 Módulos:                4            │
│  🎮 Controllers:            6            │
│  ⚙️  Services:              4            │
│  💾 Repositories:           9            │
│  🔒 Security Components:    4            │
│  📡 API Endpoints:         26            │
│  🗄️  Database Tables:       9            │
├──────────────────────────────────────────┤
│  📐 Vistas C4 (DSL):      12             │
│  📐 Nivel 4 (Code):        1             │
│  📊 Diagramas PlantUML:    6             │
│  📝 Docs Markdown:         8             │
└──────────────────────────────────────────┘
```

### Módulos Implementados
1. **User Management** - Autenticación, registro, perfiles
2. **Product Catalog** - Productos, categorías, búsqueda
3. **Cart** - Carrito de compras
4. **Order Management** - Pedidos, backoffice, estados

### APIs Públicas Inter-Módulos
- `UserService`: 2 métodos públicos
- `ProductService`: 4 métodos públicos
- `CartService`: 2 métodos públicos
- `OrderService`: Orquestador (usa los 3 anteriores)

---

## ✅ Checklist de Documentación

### Para Desarrolladores Nuevos
- [ ] Leer `C4-QUICKSTART.md`
- [ ] Ver `SystemContext` en Structurizr
- [ ] Leer `ARQUITECTURA-MODULAR.md` (secciones 1-4)
- [ ] Explorar vistas de componentes
- [ ] Revisar código fuente comparando con diagramas

### Para Presentaciones
- [ ] Abrir Structurizr con el modelo DSL
- [ ] Exportar diagramas relevantes como PNG
- [ ] Leer `ARQUITECTURA-C4-INDEX.md` para estadísticas
- [ ] Preparar ejemplos de flujos críticos

### Para Documentación Oficial
- [ ] Incluir diagramas en Confluence/Wiki
- [ ] Linkar a `ARQUITECTURA-MODULAR.md` como referencia
- [ ] Mantener `structurizr-c4-model.dsl` actualizado
- [ ] Versionado con el código (Git)

---

## 🚀 Próximos Pasos

### Arquitectura
- [ ] Agregar nivel 4 (Code) para componentes críticos
- [ ] Documentar ADRs (Architecture Decision Records)
- [ ] Agregar diagramas de deployment

### Funcionalidad
- [ ] Agregar módulo de Payment
- [ ] Agregar módulo de Notifications
- [ ] Frontend (React/Angular)
- [ ] Mobile App (React Native/Flutter)

### Evolución
- [ ] Preparar para microservicios
- [ ] Agregar API Gateway
- [ ] Event-driven architecture (opcional)

---

## 📞 Soporte

### Documentación
- **Arquitectura detallada**: `ARQUITECTURA-MODULAR.md`
- **Guía rápida**: `C4-QUICKSTART.md`
- **Índice completo**: `ARQUITECTURA-C4-INDEX.md`

### Herramientas
- **Structurizr**: https://structurizr.com/help
- **C4 Model**: https://c4model.com
- **PlantUML**: https://plantuml.com

### Contacto
- Issues: GitHub Issues del proyecto
- Docs: Carpeta `/docs` del repositorio

---

## 📅 Información del Documento

| Campo | Valor |
|-------|-------|
| **Fecha de creación** | 5 de Noviembre, 2025 |
| **Versión** | 1.1 |
| **Estado** | ✅ Completo |
| **Última actualización** | 5 de Noviembre, 2025 |
| **Modelo C4** | Niveles 1, 2, 3, 4 + Dinámico |
| **Total de archivos** | 8 archivos de documentación |

---

## 🎯 Empezar Ahora

**¿Tienes 5 minutos?**
👉 Lee [`C4-QUICKSTART.md`](C4-QUICKSTART.md)

**¿Quieres ver diagramas ya?**
👉 Abre https://structurizr.com y copia [`structurizr-c4-model.dsl`](structurizr-c4-model.dsl)

**¿Necesitas entender el código?**
👉 Lee [`ARQUITECTURA-MODULAR.md`](ARQUITECTURA-MODULAR.md)

**¿Quieres una vista rápida?**
👉 Abre [`ARQUITECTURA-ASCII.md`](ARQUITECTURA-ASCII.md)

---

**Virtual Pet E-Commerce - Documentación de Arquitectura C4**

