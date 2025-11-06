workspace "Virtual Pet E-Commerce" "Arquitectura del sistema de e-commerce para productos de mascotas" {

    model {
        # Actores externos
        cliente = person "Cliente" "Usuario que compra productos para mascotas"
        empleadoAlmacen = person "Empleado de Almacén" "Personal de warehouse que gestiona pedidos y envíos"

        # Sistema externo
        sistemaEmail = softwareSystem "Sistema de Email" "Envía notificaciones por correo" "External System"

        # Sistema principal
        virtualPetSystem = softwareSystem "Virtual Pet E-Commerce" "Permite a los clientes comprar productos para mascotas y gestionar pedidos" {

            # Base de datos
            database = container "PostgreSQL Database" "Almacena usuarios, productos, carritos y pedidos" "PostgreSQL 14" "Database"

            # Aplicación Spring Boot
            apiApplication = container "API Application" "Proporciona funcionalidad de e-commerce vía API REST" "Spring Boot 3.5.7" {

                # ============================================
                # SECURITY COMPONENTS
                # ============================================

                securityConfig = component "Security Config" "Configuración de Spring Security y JWT" "Spring Security" "Security"
                jwtAuthFilter = component "JWT Authentication Filter" "Intercepta requests y valida tokens JWT" "Spring Security Filter" "Security"
                jwtUtil = component "JWT Util" "Genera y valida tokens JWT" "Java Class" "Security"
                userDetailsService = component "Custom User Details Service" "Carga detalles del usuario para autenticación" "Spring Security" "Security"

                # ============================================
                # USER MANAGEMENT MODULE
                # ============================================

                userController = component "User Controller" "Expone endpoints de gestión de usuarios" "Spring REST Controller" "Controller"
                userService = component "User Service" "Lógica de negocio de usuarios y autenticación" "Spring Service" "Service"
                userRepository = component "User Repository" "Acceso a datos de usuarios" "Spring Data JPA Repository" "Repository"
                roleRepository = component "Role Repository" "Acceso a datos de roles" "Spring Data JPA Repository" "Repository"

                # ============================================
                # PRODUCT CATALOG MODULE
                # ============================================

                productController = component "Product Controller" "Expone endpoints de productos" "Spring REST Controller" "Controller"
                categoryController = component "Category Controller" "Expone endpoints de categorías" "Spring REST Controller" "Controller"
                productService = component "Product Service" "Lógica de negocio de productos y stock" "Spring Service" "Service"
                productRepository = component "Product Repository" "Acceso a datos de productos" "Spring Data JPA Repository" "Repository"
                categoryRepository = component "Category Repository" "Acceso a datos de categorías" "Spring Data JPA Repository" "Repository"

                # ============================================
                # CART MODULE
                # ============================================

                cartController = component "Cart Controller" "Expone endpoints del carrito de compras" "Spring REST Controller" "Controller"
                cartService = component "Cart Service" "Lógica de negocio del carrito" "Spring Service" "Service"
                cartRepository = component "Cart Repository" "Acceso a datos de carritos" "Spring Data JPA Repository" "Repository"
                cartItemRepository = component "Cart Item Repository" "Acceso a datos de items del carrito" "Spring Data JPA Repository" "Repository"

                # ============================================
                # ORDER MANAGEMENT MODULE
                # ============================================

                orderController = component "Order Controller" "Expone endpoints de pedidos para clientes" "Spring REST Controller" "Controller"
                backofficeOrderController = component "Backoffice Order Controller" "Expone endpoints de pedidos para warehouse" "Spring REST Controller" "Controller"
                orderService = component "Order Service" "Lógica de negocio de pedidos y estados" "Spring Service" "Service"
                orderRepository = component "Order Repository" "Acceso a datos de pedidos" "Spring Data JPA Repository" "Repository"
                orderStatusHistoryRepository = component "Order Status History Repository" "Acceso a historial de estados" "Spring Data JPA Repository" "Repository"

                # ============================================
                # RELACIONES - SECURITY
                # ============================================

                jwtAuthFilter -> jwtUtil "Usa para validar tokens"
                jwtAuthFilter -> userDetailsService "Carga detalles del usuario"
                userDetailsService -> userRepository "Consulta usuarios"

                # ============================================
                # RELACIONES - USER MANAGEMENT
                # ============================================

                userController -> userService "Llama"
                userController -> jwtAuthFilter "Protegido por" "JWT"

                userService -> userRepository "Lee/escribe usuarios"
                userService -> roleRepository "Consulta roles"
                userService -> jwtUtil "Genera tokens JWT"

                # ============================================
                # RELACIONES - PRODUCT CATALOG
                # ============================================

                productController -> productService "Llama"
                categoryController -> productService "Llama"

                productService -> productRepository "Lee/escribe productos"
                productService -> categoryRepository "Consulta categorías"

                # ============================================
                # RELACIONES - CART
                # ============================================

                cartController -> jwtAuthFilter "Protegido por" "JWT"
                cartController -> userService "Obtiene userId"
                cartController -> cartService "Llama"

                cartService -> cartRepository "Lee/escribe carritos"
                cartService -> cartItemRepository "Gestiona items"
                cartService -> productService "Valida stock y obtiene precios" "API Pública"

                # ============================================
                # RELACIONES - ORDER MANAGEMENT
                # ============================================

                orderController -> jwtAuthFilter "Protegido por" "JWT"
                orderController -> userService "Obtiene userId"
                orderController -> orderService "Llama"

                backofficeOrderController -> jwtAuthFilter "Protegido por" "JWT + ROLE_WAREHOUSE"
                backofficeOrderController -> userService "Obtiene warehouseUserId"
                backofficeOrderController -> orderService "Llama"

                orderService -> orderRepository "Lee/escribe pedidos"
                orderService -> orderStatusHistoryRepository "Registra cambios de estado"
                orderService -> cartService "Obtiene carrito y lo vacía" "API Pública"
                orderService -> productService "Valida stock, reduce y restaura" "API Pública"
                orderService -> userService "Obtiene info del cliente" "API Pública"

                # ============================================
                # RELACIONES CON BASE DE DATOS
                # ============================================

                userRepository -> database "Lee/escribe" "JDBC/JPA"
                roleRepository -> database "Lee/escribe" "JDBC/JPA"
                productRepository -> database "Lee/escribe" "JDBC/JPA"
                categoryRepository -> database "Lee/escribe" "JDBC/JPA"
                cartRepository -> database "Lee/escribe" "JDBC/JPA"
                cartItemRepository -> database "Lee/escribe" "JDBC/JPA"
                orderRepository -> database "Lee/escribe" "JDBC/JPA"
                orderStatusHistoryRepository -> database "Lee/escribe" "JDBC/JPA"
            }

            # Aplicación web (futuro frontend)
            webApp = container "Web Application" "Interfaz de usuario para clientes" "React/Angular" "Web Browser" {
                !docs docs/frontend
            }

            # Mobile app (futuro)
            mobileApp = container "Mobile App" "Aplicación móvil para clientes" "React Native/Flutter" "Mobile App" {
                !docs docs/mobile
            }
        }

        # ============================================
        # RELACIONES DE ALTO NIVEL
        # ============================================

        # Clientes
        cliente -> webApp "Usa" "HTTPS"
        cliente -> mobileApp "Usa" "HTTPS"
        cliente -> virtualPetSystem "Compra productos y gestiona pedidos"

        webApp -> apiApplication "Hace llamadas API a" "JSON/HTTPS"
        mobileApp -> apiApplication "Hace llamadas API a" "JSON/HTTPS"

        # Empleados
        empleadoAlmacen -> webApp "Gestiona pedidos vía" "HTTPS"
        empleadoAlmacen -> virtualPetSystem "Procesa y despacha pedidos"

        # Sistema externo
        apiApplication -> sistemaEmail "Envía emails usando" "SMTP"

        # Relaciones específicas con componentes (para nivel 3)
        cliente -> userController "Registra, login, perfil" "JSON/HTTPS"
        cliente -> productController "Lista y busca productos" "JSON/HTTPS"
        cliente -> categoryController "Consulta categorías" "JSON/HTTPS"
        cliente -> cartController "Gestiona carrito" "JSON/HTTPS"
        cliente -> orderController "Crea y consulta pedidos" "JSON/HTTPS"

        empleadoAlmacen -> backofficeOrderController "Gestiona pedidos" "JSON/HTTPS"
    }

    views {
        # ============================================
        # VISTA DE SISTEMA (Nivel 1)
        # ============================================

        systemContext virtualPetSystem "SystemContext" {
            include *
            autoLayout
            description "Diagrama de contexto del sistema Virtual Pet E-Commerce"
        }

        # ============================================
        # VISTA DE CONTENEDORES (Nivel 2)
        # ============================================

        container virtualPetSystem "Containers" {
            include *
            autoLayout
            description "Vista de contenedores del sistema Virtual Pet E-Commerce"
        }

        # ============================================
        # VISTAS DE COMPONENTES (Nivel 3)
        # ============================================

        # Vista general de todos los componentes
        component apiApplication "Components-All" {
            include *
            autoLayout
            description "Vista de todos los componentes de la aplicación Spring Boot"
        }

        # Vista: User Management Module
        component apiApplication "Components-UserManagement" {
            include userController userService userRepository roleRepository
            include jwtAuthFilter jwtUtil userDetailsService securityConfig
            include cliente database
            autoLayout
            description "Componentes del módulo User Management"
        }

        # Vista: Product Catalog Module
        component apiApplication "Components-ProductCatalog" {
            include productController categoryController productService
            include productRepository categoryRepository
            include cliente database
            autoLayout
            description "Componentes del módulo Product Catalog"
        }

        # Vista: Cart Module
        component apiApplication "Components-Cart" {
            include cartController cartService cartRepository cartItemRepository
            include userService productService
            include jwtAuthFilter
            include cliente database
            autoLayout
            description "Componentes del módulo Cart"
        }

        # Vista: Order Management Module
        component apiApplication "Components-OrderManagement" {
            include orderController backofficeOrderController orderService
            include orderRepository orderStatusHistoryRepository
            include cartService productService userService
            include jwtAuthFilter
            include cliente empleadoAlmacen database
            autoLayout
            description "Componentes del módulo Order Management"
        }

        # Vista: Security Components
        component apiApplication "Components-Security" {
            include securityConfig jwtAuthFilter jwtUtil userDetailsService
            include userRepository
            include database
            autoLayout
            description "Componentes de seguridad y autenticación"
        }

        # Vista: Flujo de creación de pedido
        component apiApplication "Components-CreateOrderFlow" {
            include cliente orderController orderService
            include userService cartService productService
            include orderRepository cartRepository productRepository
            include jwtAuthFilter
            include database
            autoLayout
            description "Flujo completo de creación de un pedido"
        }

        # ============================================
        # VISTAS DINÁMICAS (Secuencias)
        # ============================================

        dynamic apiApplication "CreateOrder-Sequence" "Secuencia de creación de pedido" {
            cliente -> orderController "1. POST /api/orders"
            orderController -> jwtAuthFilter "2. Valida JWT"
            orderController -> userService "3. Obtiene userId"
            orderController -> orderService "4. createOrder()"
            orderService -> userService "5. getUserById()"
            orderService -> cartService "6. getCartEntity()"
            orderService -> productService "7. checkAvailability()"
            orderService -> orderRepository "8. save(order)"
            orderService -> productService "9. reduceStock() [por cada item]"
            orderService -> cartService "10. clearCartAfterOrder()"
            orderController -> cliente "11. 201 Created + OrderResponse"
            autoLayout
        }

        dynamic apiApplication "AddToCart-Sequence" "Secuencia de agregar producto al carrito" {
            cliente -> cartController "1. POST /api/cart/items"
            cartController -> jwtAuthFilter "2. Valida JWT"
            cartController -> userService "3. getProfile(email)"
            cartController -> cartService "4. addToCart()"
            cartService -> productService "5. getProductById()"
            cartService -> productService "6. Valida stock disponible"
            cartService -> cartRepository "7. findByUserId()"
            cartService -> cartItemRepository "8. save(cartItem)"
            cartController -> cliente "9. 200 OK + CartResponse"
            autoLayout
        }

        dynamic apiApplication "Login-Sequence" "Secuencia de login y generación de JWT" {
            cliente -> userController "1. POST /api/users/login"
            userController -> userService "2. login(credentials)"
            userService -> userDetailsService "3. loadUserByUsername()"
            userDetailsService -> userRepository "4. findByEmail()"
            userService -> jwtUtil "5. generateToken()"
            userController -> cliente "6. 200 OK + JWT Token"
            autoLayout
        }

        # ============================================
        # ESTILOS Y TEMAS
        # ============================================

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
            element "External System" {
                background #999999
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
            element "Web Browser" {
                shape webbrowser
                background #438dd5
                color #ffffff
            }
            element "Mobile App" {
                shape mobiledevicelandscape
                background #438dd5
                color #ffffff
            }
            element "Controller" {
                background #85bbf0
                color #000000
            }
            element "Service" {
                background #5d9cec
                color #ffffff
            }
            element "Repository" {
                background #cfe2f3
                color #000000
            }
            element "Security" {
                background #f4b942
                color #000000
            }
            relationship "Relationship" {
                routing direct
                color #707070
                fontSize 24
            }
        }

        # ============================================
        # TEMAS ADICIONALES
        # ============================================

        themes default https://static.structurizr.com/themes/oracle/theme.json
    }

    configuration {
        scope softwaresystem
    }
}

