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
public class NotificationPreferenceResponse {
    private Long id;
    private Long userId;
    private Boolean emailEnabled;
    private Boolean whatsappEnabled;
    private String whatsappNumber;
    private Boolean smsEnabled;
    private String smsNumber;
    private Boolean telegramEnabled;
    private String telegramChatId;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

