package com.virtualpet.ecommerce.modules.product.repository;

import com.virtualpet.ecommerce.modules.product.entity.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    // Buscar productos activos
    Page<Product> findByActiveTrue(Pageable pageable);

    // Buscar por categoría
    Page<Product> findByCategoryIdAndActiveTrue(Long categoryId, Pageable pageable);

    // Buscar por nombre (búsqueda parcial)
    Page<Product> findByNameContainingIgnoreCaseAndActiveTrue(String name, Pageable pageable);

    // Buscar por categoría y nombre
    Page<Product> findByCategoryIdAndNameContainingIgnoreCaseAndActiveTrue(
            Long categoryId, String name, Pageable pageable);

    // Buscar productos con stock disponible
    Page<Product> findByActiveTrueAndStockGreaterThan(Integer minStock, Pageable pageable);

    // Buscar productos por categoría con stock
    Page<Product> findByCategoryIdAndActiveTrueAndStockGreaterThan(
            Long categoryId, Integer minStock, Pageable pageable);

    // Buscar producto por ID y que esté activo
    Optional<Product> findByIdAndActiveTrue(Long id);

    // Obtener productos por lista de IDs
    List<Product> findByIdIn(List<Long> ids);

    // Reducir stock (método personalizado)
    @Modifying
    @Query("UPDATE Product p SET p.stock = p.stock - :quantity WHERE p.id = :productId AND p.stock >= :quantity")
    int reduceStock(@Param("productId") Long productId, @Param("quantity") Integer quantity);

    // Restaurar stock (para cancelaciones)
    @Modifying
    @Query("UPDATE Product p SET p.stock = p.stock + :quantity WHERE p.id = :productId")
    int restoreStock(@Param("productId") Long productId, @Param("quantity") Integer quantity);
}

