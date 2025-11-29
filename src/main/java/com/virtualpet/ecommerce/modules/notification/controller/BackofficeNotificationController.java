package com.virtualpet.ecommerce.modules.notification.controller;

import com.virtualpet.ecommerce.modules.notification.dto.NotificationLogResponse;
import com.virtualpet.ecommerce.modules.notification.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/backoffice/notifications")
@CrossOrigin(origins = "*")
@PreAuthorize("hasRole('WAREHOUSE')")
@Tag(name = "Notifications - Backoffice", description = "Consulta de notificaciones enviadas (para backoffice)")
@SecurityRequirement(name = "bearer-jwt")
@Slf4j
public class BackofficeNotificationController {

    @Autowired
    private NotificationService notificationService;

    @Operation(
            summary = "Obtener notificaciones de un pedido",
            description = "Retorna todas las notificaciones enviadas para un pedido específico. " +
                    "Incluye el link de WhatsApp si fue enviado. Requiere rol WAREHOUSE."
    )
    @GetMapping("/orders/{orderId}")
    public ResponseEntity<List<NotificationLogResponse>> getNotificationsByOrder(
            @Parameter(description = "ID del pedido") @PathVariable Long orderId) {

        log.info("Consultando notificaciones para pedido {}", orderId);

        List<NotificationLogResponse> notifications = notificationService.getNotificationsByOrderId(orderId);

        return ResponseEntity.ok(notifications);
    }
}

