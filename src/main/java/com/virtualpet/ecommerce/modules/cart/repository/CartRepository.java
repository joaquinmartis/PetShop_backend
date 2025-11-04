package com.virtualpet.ecommerce.modules.cart.repository;

import com.virtualpet.ecommerce.modules.cart.entity.Cart;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CartRepository extends JpaRepository<Cart, Long> {

    // Buscar carrito por usuario
    Optional<Cart> findByUserId(Long userId);

    // Verificar si existe carrito para un usuario
    Boolean existsByUserId(Long userId);

    // Buscar carrito con items cargados (JOIN FETCH para evitar N+1)
    @Query("SELECT c FROM Cart c LEFT JOIN FETCH c.items WHERE c.userId = :userId")
    Optional<Cart> findByUserIdWithItems(@Param("userId") Long userId);
}

