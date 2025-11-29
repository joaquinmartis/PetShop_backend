package com.virtualpet.ecommerce.modules.notification.controller;

import com.virtualpet.ecommerce.modules.notification.dto.NotificationPreferenceRequest;
import com.virtualpet.ecommerce.modules.notification.dto.NotificationPreferenceResponse;
import com.virtualpet.ecommerce.modules.notification.service.NotificationService;
import com.virtualpet.ecommerce.modules.user.service.UserService;
import com.virtualpet.ecommerce.security.JwtUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.persistence.EntityNotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications/preferences")
@Tag(name = "Notification Preferences", description = "Gestión de preferencias de notificación del usuario")
@SecurityRequirement(name = "bearer-jwt")
@Slf4j
public class NotificationPreferenceController {

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private UserService userService;

    @Autowired
    private JwtUtil jwtUtil;

    /**
     * Crear preferencias de notificación (después del registro)
     */
    @PostMapping
    @Operation(summary = "Crear preferencias de notificación",
               description = "Crea las preferencias de notificación para el usuario. Por defecto, email está activado.")
    public ResponseEntity<?> createPreferences(
            @RequestBody(required = false) NotificationPreferenceRequest request,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);

            NotificationPreferenceResponse response;

            if (request == null || isEmptyRequest(request)) {
                // Crear preferencias por defecto
                response = notificationService.createDefaultPreferences(userId);
            } else {
                // Crear con preferencias personalizadas
                response = notificationService.createPreferences(userId, request);
            }

            return ResponseEntity.status(HttpStatus.CREATED).body(response);

        } catch (IllegalArgumentException e) {
            log.error("Error al crear preferencias: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("Error inesperado al crear preferencias: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error al crear preferencias de notificación"));
        }
    }

    /**
     * Obtener preferencias del usuario autenticado
     */
    @GetMapping
    @Operation(summary = "Obtener mis preferencias",
               description = "Retorna las preferencias de notificación del usuario autenticado")
    public ResponseEntity<?> getMyPreferences(Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            NotificationPreferenceResponse response = notificationService.getMyPreferences(userId);
            return ResponseEntity.ok(response);

        } catch (EntityNotFoundException e) {
            log.error("Preferencias no encontradas: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of(
                        "error", "Preferencias no encontradas",
                        "suggestion", "Usa POST /api/notifications/preferences para crearlas"
                    ));
        } catch (Exception e) {
            log.error("Error al obtener preferencias: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error al obtener preferencias"));
        }
    }

    /**
     * Actualizar preferencias
     */
    @PutMapping
    @Operation(summary = "Actualizar preferencias",
               description = "Actualiza las preferencias de notificación del usuario. Solo actualiza los campos enviados.")
    public ResponseEntity<?> updatePreferences(
            @RequestBody NotificationPreferenceRequest request,
            Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);
            NotificationPreferenceResponse response = notificationService.updatePreferences(userId, request);
            return ResponseEntity.ok(response);

        } catch (EntityNotFoundException e) {
            log.error("Preferencias no encontradas: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of(
                        "error", "Preferencias no encontradas",
                        "suggestion", "Usa POST /api/notifications/preferences para crearlas primero"
                    ));
        } catch (Exception e) {
            log.error("Error al actualizar preferencias: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error al actualizar preferencias"));
        }
    }

    /**
     * Obtener estado de las preferencias (si existen o no)
     */
    @GetMapping("/status")
    @Operation(summary = "Verificar si existen preferencias",
               description = "Retorna si el usuario tiene preferencias configuradas")
    public ResponseEntity<?> checkPreferencesStatus(Authentication authentication) {
        try {
            Long userId = getUserIdFromAuth(authentication);

            Map<String, Object> status = new HashMap<>();
            try {
                NotificationPreferenceResponse preferences = notificationService.getMyPreferences(userId);
                status.put("exists", true);
                status.put("preferences", preferences);
            } catch (EntityNotFoundException e) {
                status.put("exists", false);
                status.put("message", "No tienes preferencias configuradas aún");
            }

            return ResponseEntity.ok(status);

        } catch (Exception e) {
            log.error("Error al verificar estado: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error al verificar estado"));
        }
    }

    // Helper methods
    private Long getUserIdFromAuth(Authentication authentication) {
        try {
            String email = authentication.getName();
            return userService.getProfile(email).getId();
        } catch (Exception e) {
            log.error("Error al obtener userId desde authentication: {}", e.getMessage());
            throw new RuntimeException("No se pudo obtener el ID del usuario");
        }
    }

    private boolean isEmptyRequest(NotificationPreferenceRequest request) {
        return request.getEmailEnabled() == null
            && request.getWhatsappEnabled() == null
            && request.getWhatsappNumber() == null
            && request.getSmsEnabled() == null
            && request.getSmsNumber() == null
            && request.getTelegramEnabled() == null
            && request.getTelegramChatId() == null;
    }
}

