workspace "Virtual Pet - C1 System Context" {

    model {
        // Personas
        customer = person "Cliente" "Compra productos, realiza pedidos y sigue sus pedidos"
        warehouse = person "Empleado BackOffice" "Gestiona pedidos y actualiza el estado de envíos"

        // Sistema principal
        virtualPet = softwareSystem "Virtual Pet System" "Plataforma ecommerce 100% digital para productos de mascotas"

        // Sistemas externos
        brevoEmailService = softwareSystem "Brevo Email" "Servicio externo de envío de correos electrónicos"
        telegramBotApi = softwareSystem "Telegram Bot API" "Servicio externo de mensajería instantánea"

        // Relaciones
        customer -> virtualPet "Consulta productos, compra y paga"
        warehouse -> virtualPet "Gestiona pedidos y estados de envío"

        virtualPet -> brevoEmailService "Envía notificaciones de despacho" "SMTP/TLS"
        virtualPet -> telegramBotApi "Envía mensajes automáticos al cliente" "HTTPS/JSON"

        brevoEmailService -> customer "Entrega notificación por email"
        telegramBotApi -> customer "Entrega notificación por Telegram"
    }

    views {
        systemContext virtualPet "VirtualPet-C1" {
            include *
            autolayout lr
            title "C1 - Diagrama de Contexto: Virtual Pet"
            description "Muestra cómo el sistema Virtual Pet se relaciona con los usuarios y los servicios externos de notificación"
        }

        styles {
            element "Person" {
                shape Person
                background "#FBC02D"
                color "#000000"
            }

            element "Software System" {
                shape RoundedBox
                background "#FFA000"
                color "#000000"
            }
        }

        theme default
    }
}
