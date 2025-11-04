package com.virtualpet.ecommerce.modules.cart.repository;

import com.virtualpet.ecommerce.modules.cart.entity.CartItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CartItemRepository extends JpaRepository<CartItem, Long> {

    // Buscar item por carrito y producto
    Optional<CartItem> findByCartIdAndProductId(Long cartId, Long productId);

    // Verificar si existe item en carrito
    Boolean existsByCartIdAndProductId(Long cartId, Long productId);

    // Eliminar item específico
    @Modifying
    @Query("DELETE FROM CartItem ci WHERE ci.cart.id = :cartId AND ci.productId = :productId")
    int deleteByCartIdAndProductId(@Param("cartId") Long cartId, @Param("productId") Long productId);

    // Eliminar todos los items de un carrito
    @Modifying
    @Query("DELETE FROM CartItem ci WHERE ci.cart.id = :cartId")
    int deleteAllByCartId(@Param("cartId") Long cartId);
}

