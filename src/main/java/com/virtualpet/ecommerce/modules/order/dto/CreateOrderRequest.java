package com.virtualpet.ecommerce.modules.order.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateOrderRequest {

    @NotBlank(message = "La dirección de envío es requerida")
    private String shippingAddress;

    private String notes; // Opcional
}

