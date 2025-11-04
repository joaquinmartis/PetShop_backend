package com.virtualpet.ecommerce.modules.product.repository;

import com.virtualpet.ecommerce.modules.product.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {

    // Buscar categoría por nombre
    Optional<Category> findByName(String name);

    // Buscar categorías activas
    List<Category> findByActiveTrue();

    // Verificar si existe por nombre
    Boolean existsByName(String name);
}

