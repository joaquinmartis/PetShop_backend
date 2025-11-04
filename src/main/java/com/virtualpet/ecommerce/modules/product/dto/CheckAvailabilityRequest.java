package com.virtualpet.ecommerce.modules.product.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CheckAvailabilityRequest {

    @NotEmpty(message = "La lista de items no puede estar vacía")
    @Valid
    private List<StockItem> items;
}

