package com.virtualpet.ecommerce.modules.order.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderResponse {

    private Long id;
    private Long userId;
    private String status;
    private BigDecimal total;
    private String shippingMethod;
    private Long shippingId;
    private String shippingAddress;
    private String customerName;
    private String customerEmail;
    private String customerPhone;
    private String notes;
    private String cancellationReason;
    private LocalDateTime cancelledAt;
    private String cancelledBy;
    private List<OrderItemResponse> items;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Información de notificaciones (para backoffice)
    private Boolean hasNotifications;  // Si se enviaron notificaciones
    private Integer notificationCount; // Cantidad de notificaciones enviadas
}

