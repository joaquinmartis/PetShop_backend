package com.virtualpet.ecommerce.modules.order.repository;

import com.virtualpet.ecommerce.modules.order.entity.OrderItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {

    // Buscar items por pedido
    List<OrderItem> findByOrderId(Long orderId);
}

