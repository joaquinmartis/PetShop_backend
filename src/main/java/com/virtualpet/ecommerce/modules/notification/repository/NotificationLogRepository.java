package com.virtualpet.ecommerce.modules.notification.repository;

import com.virtualpet.ecommerce.modules.notification.entity.NotificationLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationLogRepository extends JpaRepository<NotificationLog, Long> {
    List<NotificationLog> findByOrderId(Long orderId);
    List<NotificationLog> findByUserId(Long userId);
}

