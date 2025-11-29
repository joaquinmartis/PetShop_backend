package com.virtualpet.ecommerce.modules.notification.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationPreferenceRequest {
    private Boolean emailEnabled;
    private Boolean whatsappEnabled;
    private String whatsappNumber;
    private Boolean smsEnabled;
    private String smsNumber;
    private Boolean telegramEnabled;
    private String telegramChatId;
}

