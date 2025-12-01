workspace "Virtual Pet E-Commerce - Component View" "Vista de componentes completa de la API Application incluyendo módulo de Notification" {

    model {
        # Actores
        frontendWebApp = softwareSystem "Frontend Web SPA" "Interfaz web para clientes y empleados del backoffice" "React"

        # Sistemas externos de notificación
        brevoEmailSystem = softwareSystem "Brevo Email Service" "Servicio externo de envío de correos electrónicos vía SMTP" "External System"
        telegramBotSystem = softwareSystem "Telegram Bot API" "API externa de Telegram para envío de mensajes instantáneos" "External System"

        # Sistema principal
        virtualPetSystem = softwareSystem "Virtual Pet E-Commerce" {

            # Base de datos
            database = container "PostgreSQL Database" "Almacena usuarios, productos, carritos, pedidos y notificaciones" "PostgreSQL 14" "Database"

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
                cartRepository = component "Cart Repository" "Acceso a datos de carritos en shopping_cart.carts" "Spring Data JPA Repository" "Repository"
                cartItemRepository = component "Cart Item Repository" "Acceso a datos de items en shopping_cart.cart_items" "Spring Data JPA Repository" "Repository"

                # ==========================================
                # ORDER MANAGEMENT MODULE
                # ==========================================

                orderController = component "Order Controller" "POST /api/orders, GET /api/orders, PATCH /api/orders/{id}/cancel" "Spring REST Controller" "Controller"
                backofficeOrderController = component "Backoffice Order Controller" "GET /api/backoffice/orders, PATCH /api/backoffice/orders/{id}/ship" "Spring REST Controller" "Controller"
                orderService = component "Order Service" "createOrder(), cancelOrder(), markShipped(), markDelivered()" "Spring Service" "Service"
                orderRepository = component "Order Repository" "Acceso a datos de pedidos en order_management.orders" "Spring Data JPA Repository" "Repository"
                orderStatusHistoryRepository = component "Order Status History Repository" "Acceso a historial en order_management.order_status_history" "Spring Data JPA Repository" "Repository"

                # ==========================================
                # NOTIFICATION MODULE
                # ==========================================

                notificationController = component "Notification Preference Controller" "POST /api/notifications/preferences, GET /api/notifications/preferences, PUT /api/notifications/preferences, GET /api/notifications/preferences/status" "Spring REST Controller" "Controller"
                backofficeNotificationController = component "Backoffice Notification Controller" "GET /api/backoffice/notifications/orders/{orderId}" "Spring REST Controller" "Controller"

                notificationService = component "Notification Service" "createPreferences(), updatePreferences(), getMyPreferences(), notifyOrderDelivered() [API Pública], getNotificationsByOrderId() [API Pública]" "Spring Service" "Service"
                emailNotificationService = component "Email Notification Service" "sendDeliveryNotification() - Integración con Brevo vía SMTP" "Spring Service" "Service"
                whatsappNotificationService = component "WhatsApp Notification Service" "generateWhatsAppLink() - Genera links de WhatsApp Web" "Spring Service" "Service"
                smsNotificationService = component "SMS Notification Service" "sendSMS() - Simulación de envío SMS" "Spring Service" "Service"
                telegramNotificationService = component "Telegram Notification Service" "sendMessage() - Integración con Telegram Bot API" "Spring Service" "Service"

                notificationPreferenceRepository = component "Notification Preference Repository" "Acceso a preferencias en notification_management.notification_preferences" "Spring Data JPA Repository" "Repository"
                notificationLogRepository = component "Notification Log Repository" "Acceso a logs en notification_management.notification_logs" "Spring Data JPA Repository" "Repository"

                # ==========================================
                # RELACIONES - SECURITY
                # ==========================================

                jwtAuthFilter -> jwtUtil "Valida tokens JWT usando"
                jwtAuthFilter -> userDetailsService "Carga usuario autenticado desde"
                userDetailsService -> userRepository "Lee usuarios desde"
                frontendWebApp -> securityConfig "Requests pasan por seguridad"

                # ==========================================
                # RELACIONES - USER MANAGEMENT
                # ==========================================

                userController -> userService "Delega lógica de negocio a"
                userService -> userRepository "Lee/escribe usuarios en"
                userService -> roleRepository "Consulta roles desde"
                userService -> jwtUtil "Genera tokens JWT usando"

                # ==========================================
                # RELACIONES - PRODUCT CATALOG
                # ==========================================

                productController -> productService "Delega lógica a"
                categoryController -> productService "Delega lógica a"
                productService -> productRepository "Lee/escribe productos en"
                productService -> categoryRepository "Consulta categorías desde"

                # ==========================================
                # RELACIONES - CART (Usa User y Product)
                # ==========================================

                cartController -> userService "Obtiene userId desde email autenticado"
                cartController -> cartService "Delega lógica a"
                cartService -> productService "Valida producto existe y tiene stock [API Pública]"
                cartService -> cartRepository "Lee/escribe carritos en"
                cartService -> cartItemRepository "Gestiona items en"

                # ==========================================
                # RELACIONES - ORDER (Usa User, Cart, Product y Notification)
                # ==========================================

                orderController -> userService "Obtiene userId del cliente autenticado"
                backofficeOrderController -> userService "Obtiene userId del empleado warehouse"
                orderController -> orderService "Delega lógica a"
                backofficeOrderController -> orderService "Delega lógica a"

                # OrderService es el ORQUESTADOR - usa 4 módulos
                orderService -> userService "Obtiene información completa del cliente [API Pública]"
                orderService -> cartService "Obtiene items del carrito y lo vacía después [API Pública]"
                orderService -> productService "Valida stock, reduce y restaura [API Pública]"
                orderService -> notificationService "Envía notificación cuando pedido se marca como SHIPPED [API Pública]"

                orderService -> orderRepository "Lee/escribe pedidos en"
                orderService -> orderStatusHistoryRepository "Registra cambios de estado en"

                # ==========================================
                # RELACIONES - NOTIFICATION (Usa User y Order)
                # ==========================================

                # Controllers → NotificationService
                notificationController -> userService "Obtiene userId del usuario autenticado"
                notificationController -> notificationService "Delega lógica de preferencias a"
                backofficeNotificationController -> notificationService "Consulta logs de notificaciones"

                # NotificationService coordina los servicios específicos de canal
                notificationService -> userService "Obtiene datos completos del usuario (nombre, email, etc.) [API Pública]"
                notificationService -> emailNotificationService "Envía email si está habilitado"
                notificationService -> whatsappNotificationService "Genera link de WhatsApp si está habilitado"
                notificationService -> smsNotificationService "Simula envío SMS si está habilitado"
                notificationService -> telegramNotificationService "Envía mensaje Telegram si está habilitado"

                # NotificationService → Repositories
                # ES EL ÚNICO que accede a los repositories (no los servicios de canal)
                notificationService -> notificationPreferenceRepository "Lee/escribe preferencias en"
                notificationService -> notificationLogRepository "Guarda logs de TODOS los canales: email, whatsapp (link), telegram, SMS"

                # Servicios de canal específico → Sistemas externos
                # NO acceden a repositories, solo hacen el envío/generación
                emailNotificationService -> brevoEmailSystem "Envía emails vía SMTP/TLS"
                telegramNotificationService -> telegramBotSystem "Envía mensajes vía HTTPS/JSON"

                # ==========================================
                # RELACIONES DE SEGURIDAD
                # ==========================================

                securityConfig -> jwtAuthFilter "Registra filtro JWT en la cadena de seguridad"
                securityConfig -> userDetailsService "Registra servicio de usuarios para autenticación"
                securityConfig -> jwtUtil "Configura utilidades JWT"

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
                notificationPreferenceRepository -> database "JDBC/JPA"
                notificationLogRepository -> database "JDBC/JPA"
            }
        }

        # Relaciones externas
        frontendWebApp -> userController "Registra usuarios, login, perfil"
        frontendWebApp -> productController "Consulta productos"
        frontendWebApp -> categoryController "Consulta categorías"
        frontendWebApp -> cartController "Gestiona carrito"
        frontendWebApp -> orderController "Gestiona pedidos del cliente"
        frontendWebApp -> backofficeOrderController "Gestión de pedidos del warehouse"
        frontendWebApp -> notificationController "Gestiona preferencias de notificación (cliente)"
        frontendWebApp -> backofficeNotificationController "Consulta logs de notificaciones (backoffice)"
    }

    views {

        # ==========================================
        # VISTA PRINCIPAL: COMPONENT ALL
        # ==========================================

        component apiApplication "Components-All" {
            include *
            autoLayout lr
            title "C3 - Vista de Componentes: Virtual Pet E-Commerce API"
            description "Arquitectura completa en capas con 5 módulos (User, Product, Cart, Order, Notification) y comunicación con sistemas externos"
        }

        # ==========================================
        # VISTA FILTRADA: SOLO NOTIFICATION MODULE
        # ==========================================

        component apiApplication "Components-Notification-Focus" {
            include element.tag==Controller
            include element.tag==Service
            include element.tag==Repository
            include notificationController
            include backofficeNotificationController
            include notificationService
            include emailNotificationService
            include whatsappNotificationService
            include smsNotificationService
            include telegramNotificationService
            include notificationPreferenceRepository
            include notificationLogRepository
            include userService
            include orderService
            include database
            include brevoEmailSystem
            include telegramBotSystem
            autoLayout tb
            title "C3 - Vista Filtrada: Módulo de Notification"
            description "Detalle del módulo de notificación multicanal. NotificationService coordina el envío por todos los canales y guarda logs en BD (email, whatsapp link, telegram, sms). Los servicios de canal NO acceden a BD directamente."
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
            element "External System" {
                background #999999
                color #ffffff
                shape RoundedBox
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
                fontSize 14
            }
        }
    }
}
