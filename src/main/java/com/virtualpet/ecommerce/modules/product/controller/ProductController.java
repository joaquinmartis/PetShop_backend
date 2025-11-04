package com.virtualpet.ecommerce.modules.product.controller;

import com.virtualpet.ecommerce.modules.product.dto.CheckAvailabilityRequest;
import com.virtualpet.ecommerce.modules.product.dto.CheckAvailabilityResponse;
import com.virtualpet.ecommerce.modules.product.dto.ProductResponse;
import com.virtualpet.ecommerce.modules.product.service.ProductService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/products")
@CrossOrigin(origins = "*")
public class ProductController {

    @Autowired
    private ProductService productService;

    /**
     * GET /api/products
     * Listar productos con filtros y paginación
     * Parámetros opcionales:
     * - categoryId: filtrar por categoría
     * - name: búsqueda por nombre
     * - inStock: solo productos con stock
     * - page: número de página (default: 0)
     * - size: tamaño de página (default: 10)
     * - sort: campo de ordenamiento (default: name)
     */
    @GetMapping
    public ResponseEntity<Page<ProductResponse>> getProducts(
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) Boolean inStock,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "name") String sort) {

        Pageable pageable = PageRequest.of(page, size, Sort.by(sort));
        Page<ProductResponse> products = productService.searchProducts(categoryId, name, inStock, pageable);
        return ResponseEntity.ok(products);
    }

    /**
     * GET /api/products/{id}
     * Obtener detalle de un producto
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getProductById(@PathVariable Long id) {
        try {
            ProductResponse product = productService.getProductById(id);
            return ResponseEntity.ok(product);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * POST /api/products/check-availability
     * Verificar disponibilidad de stock para múltiples productos
     * Este endpoint será usado por Cart y Order Management
     */
    @PostMapping("/check-availability")
    public ResponseEntity<CheckAvailabilityResponse> checkAvailability(
            @Valid @RequestBody CheckAvailabilityRequest request) {
        try {
            CheckAvailabilityResponse response = productService.checkAvailability(request.getItems());
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().build();
        }
    }
}

