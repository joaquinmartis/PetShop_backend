package com.virtualpet.ecommerce.modules.user.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "Respuesta estándar de error de la API")
public class ErrorResponse {

    @Schema(description = "Código de estado HTTP", example = "404")
    private int status;

    @Schema(description = "Tipo de error", example = "Not Found")
    private String error;

    @Schema(description = "Mensaje descriptivo del error", example = "Recurso no encontrado")
    private String message;

    @Schema(description = "Ruta del endpoint que generó el error", example = "/api/products/999")
    private String path;

    @Schema(description = "Timestamp del error", example = "2025-11-06T15:30:00")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    @Builder.Default
    private LocalDateTime timestamp = LocalDateTime.now();

    @Schema(description = "Campo específico que causó el error (opcional)", example = "email")
    private String field;
}