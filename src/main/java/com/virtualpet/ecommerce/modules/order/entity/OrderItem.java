package com.virtualpet.ecommerce.modules.order.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "order_items", schema = "order_management")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @Column(name = "product_id", nullable = false)
    private Long productId;

    @Column(name = "product_name_snapshot", nullable = false, length = 150)
    private String productNameSnapshot;

    @Column(name = "product_image_snapshot", length = 255)
    private String productImageSnapshot;

    @Column(nullable = false)
    private Integer quantity;

    @Column(name = "unit_price_snapshot", nullable = false, precision = 10, scale = 2)
    private BigDecimal unitPriceSnapshot;

    // Nota: subtotal es calculado por la BD (GENERATED ALWAYS AS)
    // pero lo mapeamos para poder leerlo
    @Column(precision = 10, scale = 2, insertable = false, updatable = false)
    private BigDecimal subtotal;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * Obtener subtotal (calculado si no está en BD)
     */
    public BigDecimal getSubtotal() {
        if (subtotal != null) {
            return subtotal;
        }
        // Calcular si no está en BD
        if (unitPriceSnapshot != null && quantity != null) {
            return unitPriceSnapshot.multiply(new BigDecimal(quantity));
        }
        return BigDecimal.ZERO;
    }

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}

