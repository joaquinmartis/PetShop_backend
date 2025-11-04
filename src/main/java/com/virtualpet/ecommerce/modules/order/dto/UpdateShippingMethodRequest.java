package com.virtualpet.ecommerce.modules.order.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateShippingMethodRequest {

    @NotNull(message = "El método de envío es requerido")
    private String shippingMethod; // OWN_TEAM o COURIER
}

