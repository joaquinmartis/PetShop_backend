package com.virtualpet.ecommerce.modules.notification.service;

import com.virtualpet.ecommerce.modules.notification.dto.NotificationLogResponse;
import com.virtualpet.ecommerce.modules.notification.dto.NotificationPreferenceRequest;
import com.virtualpet.ecommerce.modules.notification.dto.NotificationPreferenceResponse;
import com.virtualpet.ecommerce.modules.notification.entity.NotificationLog;
import com.virtualpet.ecommerce.modules.notification.entity.NotificationLog.NotificationChannel;
import com.virtualpet.ecommerce.modules.notification.entity.NotificationPreference;
import com.virtualpet.ecommerce.modules.notification.repository.NotificationLogRepository;
import com.virtualpet.ecommerce.modules.notification.repository.NotificationPreferenceRepository;
import com.virtualpet.ecommerce.modules.order.entity.Order;
import com.virtualpet.ecommerce.modules.user.dto.UserResponse;
import com.virtualpet.ecommerce.modules.user.service.UserService;
import jakarta.persistence.EntityNotFoundException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;


@Service
@Slf4j
public class NotificationService {

    @Autowired
    private NotificationPreferenceRepository preferenceRepository;

    @Autowired
    private NotificationLogRepository logRepository;

    @Autowired
    private UserService userService;

    @Autowired
    private EmailNotificationService emailService;

    @Autowired
    private WhatsappNotificationService whatsappService;

    @Autowired
    private SmsNotificationService smsService;

    @Autowired
    private TelegramNotificationService telegramService;

    // ============================================
    // GESTIÓN DE PREFERENCIAS
    // ============================================

    /**
     * Crear preferencias por defecto para un nuevo usuario
     */
    @Transactional
    public NotificationPreferenceResponse createDefaultPreferences(Long userId) {
        // Verificar si ya existen preferencias
        if (preferenceRepository.existsByUserId(userId)) {
            throw new IllegalArgumentException("El usuario ya tiene preferencias configuradas");
        }

        NotificationPreference preference = NotificationPreference.builder()
                .userId(userId)
                .emailEnabled(false)  // Desactivado por defecto - Usuario debe elegir
                .whatsappEnabled(false)
                .smsEnabled(false)
                .telegramEnabled(false)
                .build();

        preference = preferenceRepository.save(preference);
        log.info("Preferencias de notificación creadas para usuario {} (todos los canales desactivados por defecto)", userId);

        return mapToResponse(preference);
    }

    /**
     * Crear preferencias personalizadas
     */
    @Transactional
    public NotificationPreferenceResponse createPreferences(Long userId, NotificationPreferenceRequest request) {
        // Verificar si ya existen preferencias
        if (preferenceRepository.existsByUserId(userId)) {
            throw new IllegalArgumentException("El usuario ya tiene preferencias configuradas. Use PATCH para actualizar.");
        }

        NotificationPreference preference = NotificationPreference.builder()
                .userId(userId)
                .emailEnabled(request.getEmailEnabled() != null ? request.getEmailEnabled() : false)
                .whatsappEnabled(request.getWhatsappEnabled() != null ? request.getWhatsappEnabled() : false)
                .whatsappNumber(request.getWhatsappNumber())
                .smsEnabled(request.getSmsEnabled() != null ? request.getSmsEnabled() : false)
                .smsNumber(request.getSmsNumber())
                .telegramEnabled(request.getTelegramEnabled() != null ? request.getTelegramEnabled() : false)
                .telegramChatId(request.getTelegramChatId())
                .build();

        preference = preferenceRepository.save(preference);
        log.info("Preferencias de notificación creadas para usuario {}", userId);

        return mapToResponse(preference);
    }

    /**
     * Obtener preferencias del usuario autenticado
     */
    @Transactional(readOnly = true)
    public NotificationPreferenceResponse getMyPreferences(Long userId) {
        NotificationPreference preference = preferenceRepository.findByUserId(userId)
                .orElseThrow(() -> new EntityNotFoundException("No se encontraron preferencias de notificación"));

        return mapToResponse(preference);
    }

    /**
     * Actualizar preferencias del usuario
     */
    @Transactional
    public NotificationPreferenceResponse updatePreferences(Long userId, NotificationPreferenceRequest request) {
        NotificationPreference preference = preferenceRepository.findByUserId(userId)
                .orElseThrow(() -> new EntityNotFoundException("No se encontraron preferencias de notificación"));

        // Actualizar solo los campos que vienen en el request
        if (request.getEmailEnabled() != null) {
            preference.setEmailEnabled(request.getEmailEnabled());
        }
        if (request.getWhatsappEnabled() != null) {
            preference.setWhatsappEnabled(request.getWhatsappEnabled());
        }
        if (request.getWhatsappNumber() != null) {
            preference.setWhatsappNumber(request.getWhatsappNumber());
        }
        if (request.getSmsEnabled() != null) {
            preference.setSmsEnabled(request.getSmsEnabled());
        }
        if (request.getSmsNumber() != null) {
            preference.setSmsNumber(request.getSmsNumber());
        }
        if (request.getTelegramEnabled() != null) {
            preference.setTelegramEnabled(request.getTelegramEnabled());
        }
        if (request.getTelegramChatId() != null) {
            preference.setTelegramChatId(request.getTelegramChatId());
        }

        preference = preferenceRepository.save(preference);
        log.info("Preferencias de notificación actualizadas para usuario {}", userId);

        return mapToResponse(preference);
    }

    // ============================================
    // ENVÍO DE NOTIFICACIONES
    // ============================================

    /**
     * Notificar al cliente cuando su pedido es entregado
     */
    @Transactional
    public void notifyOrderDelivered(Order order) {
        log.info("Iniciando proceso de notificación para pedido {} del usuario {}", order.getId(), order.getUserId());

        // Obtener información del usuario
        UserResponse user = userService.getUserById(order.getUserId());

        // Construir mensaje
        String message = buildDeliveryMessage(user.getFirstName(), order.getShippingAddress(), order.getId());

        // Obtener preferencias de notificación (si existen)
        NotificationPreference preferences = preferenceRepository.findByUserId(order.getUserId()).orElse(null);

        // Si no tiene preferencias configuradas, NO enviar notificaciones
        // El usuario debe optar explícitamente por recibir notificaciones
        if (preferences == null) {
            log.info("Usuario {} no tiene preferencias configuradas. No se enviarán notificaciones (opt-in requerido).", order.getUserId());
            return;
        }

        // Enviar por los canales activos
        int sentCount = 0;

        if (preferences.getEmailEnabled()) {
            sendEmailNotification(order, user, message);
            sentCount++;
        }

        if (preferences.getWhatsappEnabled()) {
            sendWhatsappNotification(order, user, message);
            sentCount++;
        }

        if (preferences.getSmsEnabled()) {
            sendSmsNotification(order, user, message);
            sentCount++;
        }

        if (preferences.getTelegramEnabled()) {
            sendTelegramNotification(order, user, preferences.getTelegramChatId(), message);
            sentCount++;
        }

        if (sentCount == 0) {
            log.warn("Usuario {} tiene preferencias configuradas pero ningún canal activo. No se enviaron notificaciones.", order.getUserId());
        } else {
            log.info("Notificaciones enviadas para pedido {}: {} canales", order.getId(), sentCount);
        }
    }

    // ============================================
    // MÉTODOS PRIVADOS - ENVÍO POR CANAL
    // ============================================

    private void sendEmailNotification(Order order, UserResponse user, String message) {
        try {
            emailService.sendDeliveryNotification(user.getEmail(), user.getFirstName(), order.getId(), order.getShippingAddress());

            logRepository.save(NotificationLog.builder()
                    .userId(order.getUserId())
                    .orderId(order.getId())
                    .channel(NotificationLog.NotificationChannel.EMAIL)
                    .status(NotificationLog.NotificationStatus.SENT)
                    .message(message)
                    .recipient(user.getEmail())
                    .build());

            log.info("Email enviado a {}", user.getEmail());
        } catch (Exception e) {
            log.error("Error al enviar email: {}", e.getMessage());
            logRepository.save(NotificationLog.builder()
                    .userId(order.getUserId())
                    .orderId(order.getId())
                    .channel(NotificationLog.NotificationChannel.EMAIL)
                    .status(NotificationLog.NotificationStatus.FAILED)
                    .message(message)
                    .recipient(user.getEmail())
                    .errorDetail(e.getMessage())
                    .build());
        }
    }

    private void sendWhatsappNotification(Order order, UserResponse user, String message) {
        try {
            String whatsappLink = whatsappService.generateWhatsappLink(user.getPhone(), message);

            logRepository.save(NotificationLog.builder()
                    .userId(order.getUserId())
                    .orderId(order.getId())
                    .channel(NotificationLog.NotificationChannel.WHATSAPP)
                    .status(NotificationLog.NotificationStatus.SENT)
                    .message("WhatsApp link generado: " + whatsappLink)
                    .recipient(user.getPhone())
                    .build());

            log.info("WhatsApp link generado para {}: {}", user.getPhone(), whatsappLink);
        } catch (Exception e) {
            log.error("Error al generar WhatsApp link: {}", e.getMessage());
            logRepository.save(NotificationLog.builder()
                    .userId(order.getUserId())
                    .orderId(order.getId())
                    .channel(NotificationLog.NotificationChannel.WHATSAPP)
                    .status(NotificationLog.NotificationStatus.FAILED)
                    .message(message)
                    .recipient(user.getPhone())
                    .errorDetail(e.getMessage())
                    .build());
        }
    }

    private void sendSmsNotification(Order order, UserResponse user, String message) {
        try {
            smsService.sendSms(user.getPhone(), message);

            logRepository.save(NotificationLog.builder()
                    .userId(order.getUserId())
                    .orderId(order.getId())
                    .channel(NotificationLog.NotificationChannel.SMS)
                    .status(NotificationLog.NotificationStatus.SENT)
                    .message(message)
                    .recipient(user.getPhone())
                    .build());

            log.info("SMS enviado a {}", user.getPhone());
        } catch (Exception e) {
            log.error("Error al enviar SMS: {}", e.getMessage());
            logRepository.save(NotificationLog.builder()
                    .userId(order.getUserId())
                    .orderId(order.getId())
                    .channel(NotificationLog.NotificationChannel.SMS)
                    .status(NotificationLog.NotificationStatus.FAILED)
                    .message(message)
                    .recipient(user.getPhone())
                    .errorDetail(e.getMessage())
                    .build());
        }
    }

    private void sendTelegramNotification(Order order, UserResponse user, String telegramChatId, String message) {
        try {
            if (telegramChatId == null || telegramChatId.isBlank()) {
                throw new IllegalArgumentException("Telegram chat ID no configurado");
            }

            telegramService.sendMessage(telegramChatId, message);

            logRepository.save(NotificationLog.builder()
                    .userId(order.getUserId())
                    .orderId(order.getId())
                    .channel(NotificationLog.NotificationChannel.TELEGRAM)
                    .status(NotificationLog.NotificationStatus.SENT)
                    .message(message)
                    .recipient(telegramChatId)
                    .build());

            log.info("Telegram enviado a chat ID: {}", telegramChatId);
        } catch (Exception e) {
            log.error("Error al enviar Telegram: {}", e.getMessage());
            logRepository.save(NotificationLog.builder()
                    .userId(order.getUserId())
                    .orderId(order.getId())
                    .channel(NotificationLog.NotificationChannel.TELEGRAM)
                    .status(NotificationLog.NotificationStatus.FAILED)
                    .message(message)
                    .recipient(telegramChatId)
                    .errorDetail(e.getMessage())
                    .build());
        }
    }

    // ============================================
    // HELPERS
    // ============================================

    private String buildDeliveryMessage(String customerName, String address, Long orderId) {
        return String.format(
                "Hola %s, desde VirtualPet te contamos que en el día de hoy estarás recibiendo en %s el pedido #%d que has realizado en nuestro portal. Que tengas un buen día. Atte VirtualPet",
                customerName,
                address,
                orderId
        );
    }

    private NotificationPreferenceResponse mapToResponse(NotificationPreference preference) {
        return NotificationPreferenceResponse.builder()
                .id(preference.getId())
                .userId(preference.getUserId())
                .emailEnabled(preference.getEmailEnabled())
                .whatsappEnabled(preference.getWhatsappEnabled())
                .whatsappNumber(preference.getWhatsappNumber())
                .smsEnabled(preference.getSmsEnabled())
                .smsNumber(preference.getSmsNumber())
                .telegramEnabled(preference.getTelegramEnabled())
                .telegramChatId(preference.getTelegramChatId())
                .createdAt(preference.getCreatedAt())
                .updatedAt(preference.getUpdatedAt())
                .build();
    }

    // ============================================
    // MÉTODOS PARA BACKOFFICE
    // ============================================

    /**
     * Obtener todas las notificaciones de un pedido (para backoffice)
     */
    @Transactional(readOnly = true)
    public List<NotificationLogResponse> getNotificationsByOrderId(Long orderId) {
        List<NotificationLog> logs = logRepository.findByOrderId(orderId);
        return logs.stream()
                .map(this::mapLogToResponse)
                .collect(java.util.stream.Collectors.toList());
    }

    /**
     * Mapear NotificationLog a NotificationLogResponse
     */
    private NotificationLogResponse mapLogToResponse(NotificationLog log) {
        NotificationLogResponse response = NotificationLogResponse.builder()
                .id(log.getId())
                .channel(log.getChannel().name())
                .status(log.getStatus().name())
                .message(log.getMessage())
                .errorDetail(log.getErrorDetail())
                .recipient(log.getRecipient())
                .sentAt(log.getSentAt())
                .build();

        // Si es WhatsApp y el mensaje contiene el link, extraerlo
        if (log.getChannel() == NotificationChannel.WHATSAPP && log.getMessage() != null) {
            String message = log.getMessage();
            if (message.contains("https://wa.me/")) {
                int startIndex = message.indexOf("https://wa.me/");
                int endIndex = message.indexOf(" ", startIndex);
                if (endIndex == -1) {
                    endIndex = message.length();
                }
                String whatsappLink = message.substring(startIndex, endIndex);
                response.setWhatsappLink(whatsappLink);
            }
        }

        return response;
    }
}

