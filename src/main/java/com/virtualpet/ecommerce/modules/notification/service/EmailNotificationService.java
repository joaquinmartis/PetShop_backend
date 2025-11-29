package com.virtualpet.ecommerce.modules.notification.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class EmailNotificationService {

    private final JavaMailSender mailSender;

    @Value("${mail.from.address}")
    private String fromEmail;

    @Value("${mail.from.name}")
    private String fromName;

    public EmailNotificationService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    /**
     * Enviar notificación de entrega por email
     */
    public void sendDeliveryNotification(String toEmail, String customerName, Long orderId, String shippingAddress) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            // Configurar remitente con nombre personalizado
            helper.setFrom(fromEmail, fromName);
            helper.setTo(toEmail);
            helper.setSubject("Tu pedido #" + orderId + " está en camino - VirtualPet");
            helper.setText(buildEmailBody(customerName, orderId, shippingAddress), false);

            // Headers adicionales para mejorar entregabilidad y configurar nombre del remitente
            message.addHeader("X-Priority", "1");
            message.addHeader("X-MSMail-Priority", "High");
            message.addHeader("X-Mailer", "VirtualPet Notification System");
            message.addHeader("Reply-To", fromEmail);
            message.addHeader("Sender", fromName + " <" + fromEmail + ">");

            mailSender.send(message);
            log.info("Email de notificación enviado exitosamente a: {}", toEmail);
        } catch (MessagingException e) {
            log.error("Error de mensajería al enviar email a {}: {}", toEmail, e.getMessage());
            throw new RuntimeException("Error al enviar email: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Error inesperado al enviar email a {}: {}", toEmail, e.getMessage());
            throw new RuntimeException("Error al enviar email: " + e.getMessage(), e);
        }
    }

    private String buildEmailBody(String customerName, Long orderId, String shippingAddress) {
        return String.format("""
                Hola %s,
                
                Desde VirtualPet te contamos que en el día de hoy estarás recibiendo en %s el pedido #%d que has realizado en nuestro portal.
                
                ¡Gracias por confiar en nosotros!
                
                Que tengas un buen día.
                
                Atentamente,
                Equipo VirtualPet
                """,
                customerName,
                shippingAddress,
                orderId
        );
    }
}

