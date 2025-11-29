package com.virtualpet.ecommerce.modules.notification.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Service
@Slf4j
public class TelegramNotificationService {

    @Value("${telegram.bot.token:}")
    private String botToken;

    @Value("${telegram.bot.enabled:false}")
    private boolean telegramEnabled;

    private final RestTemplate restTemplate;

    public TelegramNotificationService() {
        this.restTemplate = new RestTemplate();
    }

    /**
     * Enviar mensaje por Telegram
     */
    public void sendMessage(String chatId, String message) {
        if (!telegramEnabled || botToken == null || botToken.isBlank()) {
            log.warn("Telegram no está configurado. Simulando envío...");
            simulateSendTelegram(chatId, message);
            return;
        }

        try {
            String url = String.format("https://api.telegram.org/bot%s/sendMessage", botToken);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> body = new HashMap<>();
            body.put("chat_id", chatId);
            body.put("text", message);
            body.put("parse_mode", "HTML");

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);

            restTemplate.postForObject(url, request, String.class);

            log.info("✅ Mensaje de Telegram enviado al chat ID: {}", chatId);

        } catch (Exception e) {
            log.error("Error al enviar mensaje de Telegram: {}", e.getMessage());
            throw new RuntimeException("Error al enviar Telegram: " + e.getMessage(), e);
        }
    }

    /**
     * Simulación de envío cuando Telegram no está configurado
     */
    private void simulateSendTelegram(String chatId, String message) {
        log.info("═══════════════════════════════════════════════════");
        log.info("📲 SIMULACIÓN TELEGRAM");
        log.info("Chat ID: {}", chatId);
        log.info("Mensaje: {}", message);
        log.info("═══════════════════════════════════════════════════");
        log.info("ℹ️  Para habilitar Telegram, configura en application.properties:");
        log.info("   telegram.bot.token=TU_TOKEN_AQUI");
        log.info("   telegram.bot.enabled=true");
    }

    /**
     * Validar que el bot esté configurado
     */
    public boolean isTelegramConfigured() {
        return telegramEnabled && botToken != null && !botToken.isBlank();
    }
}

