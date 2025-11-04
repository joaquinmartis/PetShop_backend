package com.virtualpet.ecommerce.modules.product.controller;

import com.virtualpet.ecommerce.modules.product.dto.CategoryResponse;
import com.virtualpet.ecommerce.modules.product.dto.ProductResponse;
import com.virtualpet.ecommerce.modules.product.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
@CrossOrigin(origins = "*")
public class CategoryController {

    @Autowired
    private ProductService productService;

    /**
     * GET /api/categories
     * Listar todas las categorías activas
     */
    @GetMapping
    public ResponseEntity<List<CategoryResponse>> getAllCategories() {
        List<CategoryResponse> categories = productService.getAllCategories();
        return ResponseEntity.ok(categories);
    }

    /**
     * GET /api/categories/{id}
     * Obtener detalle de una categoría
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getCategoryById(@PathVariable Long id) {
        try {
            CategoryResponse category = productService.getCategoryById(id);
            return ResponseEntity.ok(category);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * GET /api/categories/{id}/products
     * Obtener productos de una categoría
     */
    @GetMapping("/{id}/products")
    public ResponseEntity<?> getProductsByCategory(
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "name") String sort) {

        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by(sort));
            Page<ProductResponse> products = productService.getProductsByCategory(id, pageable);
            return ResponseEntity.ok(products);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}

