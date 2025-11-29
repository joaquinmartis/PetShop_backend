package com.virtualpet.ecommerce.modules.notification.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Service
@Slf4j
public class WhatsappNotificationService {

    /**
     * Generar link de WhatsApp Web con mensaje pre-cargado
     * Este link puede ser enviado al usuario o guardado en el log
     */
    public String generateWhatsappLink(String phoneNumber, String message) {
        try {
            // Limpiar el número de teléfono (remover espacios, guiones, etc.)
            String cleanPhone = phoneNumber.replaceAll("[^0-9+]", "");

            // Codificar el mensaje para URL
            String encodedMessage = URLEncoder.encode(message, StandardCharsets.UTF_8);

            // Generar el link de WhatsApp Web
            String whatsappLink = String.format("https://wa.me/%s?text=%s", cleanPhone, encodedMessage);

            log.info("WhatsApp link generado para {}: {}", cleanPhone, whatsappLink);

            return whatsappLink;
        } catch (Exception e) {
            log.error("Error al generar WhatsApp link: {}", e.getMessage());
            throw new RuntimeException("Error al generar WhatsApp link", e);
        }
    }

    /**
     * Simulación de envío de WhatsApp
     * En producción, aquí usarías la API de WhatsApp Business
     */
    public void simulateSendWhatsapp(String phoneNumber, String message) {
        String link = generateWhatsappLink(phoneNumber, message);
        log.info("SIMULACIÓN WhatsApp - Link generado: {}", link);
        log.info("SIMULACIÓN WhatsApp - En producción, aquí se enviaría el mensaje al número: {}", phoneNumber);
    }
}

