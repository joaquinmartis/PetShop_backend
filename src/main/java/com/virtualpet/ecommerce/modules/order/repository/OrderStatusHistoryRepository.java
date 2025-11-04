package com.virtualpet.ecommerce.modules.order.repository;

import com.virtualpet.ecommerce.modules.order.entity.OrderStatusHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderStatusHistoryRepository extends JpaRepository<OrderStatusHistory, Long> {

    // Buscar historial por pedido
    List<OrderStatusHistory> findByOrderIdOrderByCreatedAtAsc(Long orderId);
}

