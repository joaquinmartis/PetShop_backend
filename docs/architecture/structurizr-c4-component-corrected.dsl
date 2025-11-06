workspace "Virtual Pet E-Commerce - Component View" "Vista de componentes corregida de la API Application" {

    model {
        # Actores
        cliente = person "Cliente" "Usuario que compra productos para mascotas"
        empleadoAlmacen = person "Empleado de Almacén" "Personal de warehouse"

        # Sistema principal
        virtualPetSystem = softwareSystem "Virtual Pet E-Commerce" {

            # Base de datos
            database = container "PostgreSQL Database" "Almacena usuarios, productos, carritos y pedidos" "PostgreSQL 14" "Database"

            # API Application
            apiApplication = container "API Application" "API REST de e-commerce" "Spring Boot 3.5.7" {

                # ==========================================
                # SECURITY COMPONENTS
                # ==========================================

                securityConfig = component "Security Config" "Configuración de Spring Security y JWT" "Spring Security Config" "Security"
                jwtAuthFilter = component "JWT Authentication Filter" "Intercepta requests y valida tokens JWT" "Spring Security Filter" "Security"
                jwtUtil = component "JWT Util" "Genera y valida tokens JWT" "Java Utility Class" "Security"
                userDetailsService = component "Custom User Details Service" "Implementa UserDetailsService para Spring Security" "Spring Security UserDetailsService" "Security"

                # ==========================================
                # USER MANAGEMENT MODULE
                # ==========================================

                userController = component "User Controller" "POST /api/users/register, POST /api/users/login, GET /api/users/profile, PATCH /api/users/profile" "Spring REST Controller" "Controller"
                userService = component "User Service" "register(), login(), getProfile(), getUserById() [API Pública]" "Spring Service" "Service"
                userRepository = component "User Repository" "Acceso a datos de usuarios en user_management.users" "Spring Data JPA Repository" "Repository"
                roleRepository = component "Role Repository" "Acceso a datos de roles en user_management.roles" "Spring Data JPA Repository" "Repository"

                # ==========================================
                # PRODUCT CATALOG MODULE
                # ==========================================

                productController = component "Product Controller" "GET /api/products, GET /api/products/{id}, GET /api/products?inStock=true" "Spring REST Controller" "Controller"
                categoryController = component "Category Controller" "GET /api/categories, GET /api/categories/{id}/products" "Spring REST Controller" "Controller"
                productService = component "Product Service" "getProductById() [API], checkAvailability() [API], reduceStock() [API], restoreStock() [API]" "Spring Service" "Service"
                productRepository = component "Product Repository" "Acceso a datos de productos en product_catalog.products" "Spring Data JPA Repository" "Repository"
                categoryRepository = component "Category Repository" "Acceso a datos de categorías en product_catalog.categories" "Spring Data JPA Repository" "Repository"

                # ==========================================
                # CART MODULE
                # ==========================================

                cartController = component "Cart Controller" "GET /api/cart, POST /api/cart/items, PATCH /api/cart/items/{id}, DELETE /api/cart/items/{id}" "Spring REST Controller" "Controller"
                cartService = component "Cart Service" "addToCart(), updateCartItem(), getCartEntity() [API], clearCartAfterOrder() [API]" "Spring Service" "Service"
                cartRepository = component "Cart Repository" "Acceso a datos de carritos en cart.carts" "Spring Data JPA Repository" "Repository"
                cartItemRepository = component "Cart Item Repository" "Acceso a datos de items en cart.cart_items" "Spring Data JPA Repository" "Repository"

                # ==========================================
                # ORDER MANAGEMENT MODULE
                # ==========================================

                orderController = component "Order Controller" "POST /api/orders, GET /api/orders, PATCH /api/orders/{id}/cancel" "Spring REST Controller" "Controller"
                backofficeOrderController = component "Backoffice Order Controller" "GET /api/backoffice/orders, PATCH /api/backoffice/orders/{id}/ship" "Spring REST Controller" "Controller"
                orderService = component "Order Service" "createOrder(), cancelOrder(), markShipped(), markDelivered()" "Spring Service" "Service"
                orderRepository = component "Order Repository" "Acceso a datos de pedidos en order_management.orders" "Spring Data JPA Repository" "Repository"
                orderStatusHistoryRepository = component "Order Status History Repository" "Acceso a historial en order_management.order_status_history" "Spring Data JPA Repository" "Repository"

                # ==========================================
                # RELACIONES - SECURITY
                # ==========================================

                # JWT Filter usa JWT Util para validar tokens
                jwtAuthFilter -> jwtUtil "Valida tokens JWT usando"

                # JWT Filter usa UserDetailsService para cargar usuarios
                jwtAuthFilter -> userDetailsService "Carga usuario autenticado desde"

                # UserDetailsService consulta usuarios en BD
                userDetailsService -> userRepository "Lee usuarios desde"

                # ==========================================
                # RELACIONES - USER MANAGEMENT
                # ==========================================

                # Controller → Service (capa de presentación a lógica)
                userController -> userService "Delega lógica de negocio a"

                # Service → Repositories (lógica a datos)
                userService -> userRepository "Lee/escribe usuarios en"
                userService -> roleRepository "Consulta roles desde"

                # Service genera tokens JWT
                userService -> jwtUtil "Genera tokens JWT usando"

                # ==========================================
                # RELACIONES - PRODUCT CATALOG
                # ==========================================

                # Controllers → Service
                productController -> productService "Delega lógica a"
                categoryController -> productService "Delega lógica a"

                # Service → Repositories
                productService -> productRepository "Lee/escribe productos en"
                productService -> categoryRepository "Consulta categorías desde"

                # ==========================================
                # RELACIONES - CART (Usa User y Product)
                # ==========================================

                # Controller necesita saber quién es el usuario autenticado
                cartController -> userService "Obtiene userId desde email autenticado"

                # Controller → Service
                cartController -> cartService "Delega lógica a"

                # CartService usa ProductService (API PÚBLICA inter-módulo)
                cartService -> productService "Valida producto existe y tiene stock [API Pública]"

                # Service → Repositories
                cartService -> cartRepository "Lee/escribe carritos en"
                cartService -> cartItemRepository "Gestiona items en"

                # ==========================================
                # RELACIONES - ORDER (Usa User, Cart y Product)
                # ==========================================

                # Controllers necesitan userId
                orderController -> userService "Obtiene userId del cliente autenticado"
                backofficeOrderController -> userService "Obtiene userId del empleado warehouse"

                # Controllers → Service
                orderController -> orderService "Delega lógica a"
                backofficeOrderController -> orderService "Delega lógica a"

                # OrderService es el ORQUESTADOR - usa 3 módulos
                orderService -> userService "Obtiene información completa del cliente [API Pública]"
                orderService -> cartService "Obtiene items del carrito y lo vacía después [API Pública]"
                orderService -> productService "Valida stock, reduce y restaura [API Pública]"

                # Service → Repositories
                orderService -> orderRepository "Lee/escribe pedidos en"
                orderService -> orderStatusHistoryRepository "Registra cambios de estado en"

                # ==========================================
                # RELACIONES CON BASE DE DATOS
                # ==========================================

                userRepository -> database "JDBC/JPA"
                roleRepository -> database "JDBC/JPA"
                productRepository -> database "JDBC/JPA"
                categoryRepository -> database "JDBC/JPA"
                cartRepository -> database "JDBC/JPA"
                cartItemRepository -> database "JDBC/JPA"
                orderRepository -> database "JDBC/JPA"
                orderStatusHistoryRepository -> database "JDBC/JPA"
            }
        }

        # Relaciones externas
        cliente -> userController "Registra, login, perfil"
        cliente -> productController "Lista productos"
        cliente -> categoryController "Lista categorías"
        cliente -> cartController "Gestiona carrito"
        cliente -> orderController "Crea y consulta pedidos"
        empleadoAlmacen -> backofficeOrderController "Gestiona pedidos warehouse"
    }

    views {

        # ==========================================
        # VISTA PRINCIPAL: COMPONENT ALL
        # ==========================================

        component apiApplication "Components-All" {
            include *
            autoLayout lr
            description "Vista completa de componentes de la API - Arquitectura en capas con comunicación inter-módulos"
        }

        # ==========================================
        # VISTAS FILTRADAS POR MÓDULO
        # ==========================================

        component apiApplication "Components-UserManagement" {
            include userController userService userRepository roleRepository
            include jwtAuthFilter jwtUtil userDetailsService securityConfig
            include cliente database
            autoLayout tb
            description "Módulo User Management: Autenticación, registro y perfiles"
        }

        component apiApplication "Components-ProductCatalog" {
            include productController categoryController productService
            include productRepository categoryRepository
            include cliente database
            autoLayout tb
            description "Módulo Product Catalog: Productos y categorías"
        }

        component apiApplication "Components-Cart" {
            include cartController cartService cartRepository cartItemRepository
            include userService productService
            include cliente database
            autoLayout tb
            description "Módulo Cart: Usa User (userId) y Product (validación stock)"
        }

        component apiApplication "Components-OrderManagement" {
            include orderController backofficeOrderController orderService
            include orderRepository orderStatusHistoryRepository
            include userService cartService productService
            include cliente empleadoAlmacen database
            autoLayout tb
            description "Módulo Order: Orquestador que usa User, Cart y Product"
        }

        component apiApplication "Components-Security" {
            include securityConfig jwtAuthFilter jwtUtil userDetailsService
            include userRepository database
            autoLayout tb
            description "Componentes de seguridad: JWT y Spring Security"
        }

        # ==========================================
        # VISTA DE FLUJO: CREAR PEDIDO
        # ==========================================

        component apiApplication "Components-CreateOrderFlow" {
            include cliente orderController orderService
            include userService cartService productService
            include orderRepository cartRepository productRepository
            include database
            autoLayout lr
            description "Flujo completo: Cliente → Order → User + Cart + Product"
        }

        # ==========================================
        # ESTILOS
        # ==========================================

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape cylinder
                background #438dd5
                color #ffffff
            }
            element "Controller" {
                background #85bbf0
                color #000000
                shape roundedbox
            }
            element "Service" {
                background #5d9cec
                color #ffffff
                shape roundedbox
            }
            element "Repository" {
                background #cfe2f3
                color #000000
                shape cylinder
            }
            element "Security" {
                background #f4b942
                color #000000
                shape hexagon
            }
            relationship "Relationship" {
                routing direct
                thickness 2
                color #707070
                fontSize 20
            }
        }
    }
}

