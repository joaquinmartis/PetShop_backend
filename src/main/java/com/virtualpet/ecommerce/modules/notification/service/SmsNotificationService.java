package com.virtualpet.ecommerce.modules.notification.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class SmsNotificationService {

    /**
     * Simulación de envío de SMS
     * En producción, aquí usarías un proveedor como Twilio, AWS SNS, etc.
     */
    public void sendSms(String phoneNumber, String message) {
        try {
            // Limpiar el número
            String cleanPhone = phoneNumber.replaceAll("[^0-9+]", "");

            // SIMULACIÓN - En producción usarías una API real
            log.info("═══════════════════════════════════════════════════");
            log.info("📱 SIMULACIÓN SMS");
            log.info("Para: {}", cleanPhone);
            log.info("Mensaje: {}", message);
            log.info("═══════════════════════════════════════════════════");

            // Simular delay de red
            Thread.sleep(100);

            log.info("✅ SMS simulado enviado exitosamente a {}", cleanPhone);

        } catch (Exception e) {
            log.error("Error al enviar SMS a {}: {}", phoneNumber, e.getMessage());
            throw new RuntimeException("Error al enviar SMS", e);
        }
    }

    /**
     * Validar formato de número de teléfono
     */
    public boolean isValidPhoneNumber(String phoneNumber) {
        if (phoneNumber == null || phoneNumber.isBlank()) {
            return false;
        }

        String cleanPhone = phoneNumber.replaceAll("[^0-9+]", "");
        return cleanPhone.length() >= 10; // Mínimo 10 dígitos
    }
}

