package com.virtualpet.ecommerce.modules.notification.repository;

import com.virtualpet.ecommerce.modules.notification.entity.NotificationPreference;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface NotificationPreferenceRepository extends JpaRepository<NotificationPreference, Long> {
    Optional<NotificationPreference> findByUserId(Long userId);
    boolean existsByUserId(Long userId);
}

