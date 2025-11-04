package com.virtualpet.ecommerce.modules.product.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CheckAvailabilityResponse {

    private Boolean available;
    private String message;
    private List<UnavailableProduct> unavailableProducts;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class UnavailableProduct {
        private Long productId;
        private String productName;
        private Integer requestedQuantity;
        private Integer availableStock;
    }
}

