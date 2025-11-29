package com.virtualpet.ecommerce.modules.notification.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationLogResponse {
    private Long id;
    private String channel;  // EMAIL, WHATSAPP, SMS, TELEGRAM
    private String status;   // SENT, FAILED
    private String message;
    private String errorDetail;
    private String recipient;
    private String whatsappLink;  // Solo para WhatsApp
    private LocalDateTime sentAt;
}

