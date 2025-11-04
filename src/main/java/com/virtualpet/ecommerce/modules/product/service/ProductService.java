package com.virtualpet.ecommerce.modules.product.service;

import com.virtualpet.ecommerce.modules.product.dto.*;
import com.virtualpet.ecommerce.modules.product.entity.Category;
import com.virtualpet.ecommerce.modules.product.entity.Product;
import com.virtualpet.ecommerce.modules.product.repository.CategoryRepository;
import com.virtualpet.ecommerce.modules.product.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    // ============================================
    // MÉTODOS PÚBLICOS - Para clientes y otros módulos
    // ============================================

    /**
     * Obtener todos los productos con paginación
     */
    public Page<ProductResponse> getAllProducts(Pageable pageable) {
        return productRepository.findByActiveTrue(pageable)
                .map(this::mapToProductResponse);
    }

    /**
     * Obtener producto por ID
     * API PÚBLICA para otros módulos
     */
    public ProductResponse getProductById(Long productId) {
        Product product = productRepository.findByIdAndActiveTrue(productId)
                .orElseThrow(() -> new RuntimeException("Producto no encontrado o inactivo"));
        return mapToProductResponse(product);
    }

    /**
     * Buscar productos con filtros
     */
    public Page<ProductResponse> searchProducts(Long categoryId, String name, Boolean inStock, Pageable pageable) {
        Page<Product> products;

        // Filtro por categoría y nombre
        if (categoryId != null && name != null && !name.isBlank()) {
            if (inStock != null && inStock) {
                products = productRepository.findByCategoryIdAndActiveTrueAndStockGreaterThan(categoryId, 0, pageable);
            } else {
                products = productRepository.findByCategoryIdAndNameContainingIgnoreCaseAndActiveTrue(
                        categoryId, name, pageable);
            }
        }
        // Solo filtro por categoría
        else if (categoryId != null) {
            if (inStock != null && inStock) {
                products = productRepository.findByCategoryIdAndActiveTrueAndStockGreaterThan(categoryId, 0, pageable);
            } else {
                products = productRepository.findByCategoryIdAndActiveTrue(categoryId, pageable);
            }
        }
        // Solo filtro por nombre
        else if (name != null && !name.isBlank()) {
            products = productRepository.findByNameContainingIgnoreCaseAndActiveTrue(name, pageable);
        }
        // Solo filtro por stock
        else if (inStock != null && inStock) {
            products = productRepository.findByActiveTrueAndStockGreaterThan(0, pageable);
        }
        // Sin filtros
        else {
            products = productRepository.findByActiveTrue(pageable);
        }

        return products.map(this::mapToProductResponse);
    }

    /**
     * Validar disponibilidad de stock para múltiples productos
     * API PÚBLICA para Cart y Order Management
     */
    @Transactional(readOnly = true)
    public CheckAvailabilityResponse checkAvailability(List<StockItem> items) {
        List<CheckAvailabilityResponse.UnavailableProduct> unavailableProducts = new ArrayList<>();

        for (StockItem item : items) {
            Product product = productRepository.findById(item.getProductId())
                    .orElseThrow(() -> new RuntimeException("Producto no encontrado: " + item.getProductId()));

            if (!product.getActive()) {
                unavailableProducts.add(CheckAvailabilityResponse.UnavailableProduct.builder()
                        .productId(product.getId())
                        .productName(product.getName())
                        .requestedQuantity(item.getQuantity())
                        .availableStock(0)
                        .build());
            } else if (product.getStock() < item.getQuantity()) {
                unavailableProducts.add(CheckAvailabilityResponse.UnavailableProduct.builder()
                        .productId(product.getId())
                        .productName(product.getName())
                        .requestedQuantity(item.getQuantity())
                        .availableStock(product.getStock())
                        .build());
            }
        }

        if (unavailableProducts.isEmpty()) {
            return CheckAvailabilityResponse.builder()
                    .available(true)
                    .message("Todos los productos están disponibles")
                    .unavailableProducts(null)
                    .build();
        } else {
            return CheckAvailabilityResponse.builder()
                    .available(false)
                    .message("Algunos productos no tienen stock suficiente")
                    .unavailableProducts(unavailableProducts)
                    .build();
        }
    }

    /**
     * Reducir stock de un producto
     * API PÚBLICA para Order Management
     */
    @Transactional
    public void reduceStock(Long productId, Integer quantity) {
        int updated = productRepository.reduceStock(productId, quantity);
        if (updated == 0) {
            throw new RuntimeException("No se pudo reducir el stock. Producto no encontrado o stock insuficiente");
        }
    }

    /**
     * Restaurar stock de un producto (para cancelaciones)
     * API PÚBLICA para Order Management
     */
    @Transactional
    public void restoreStock(Long productId, Integer quantity) {
        int updated = productRepository.restoreStock(productId, quantity);
        if (updated == 0) {
            throw new RuntimeException("No se pudo restaurar el stock. Producto no encontrado");
        }
    }

    // ============================================
    // CATEGORÍAS
    // ============================================

    /**
     * Obtener todas las categorías activas
     */
    public List<CategoryResponse> getAllCategories() {
        return categoryRepository.findByActiveTrue()
                .stream()
                .map(this::mapToCategoryResponse)
                .collect(Collectors.toList());
    }

    /**
     * Obtener categoría por ID
     */
    public CategoryResponse getCategoryById(Long categoryId) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Categoría no encontrada"));
        return mapToCategoryResponse(category);
    }

    /**
     * Obtener productos de una categoría
     */
    public Page<ProductResponse> getProductsByCategory(Long categoryId, Pageable pageable) {
        // Verificar que la categoría existe
        categoryRepository.findById(categoryId)
                .orElseThrow(() -> new RuntimeException("Categoría no encontrada"));

        return productRepository.findByCategoryIdAndActiveTrue(categoryId, pageable)
                .map(this::mapToProductResponse);
    }

    // ============================================
    // MAPPERS
    // ============================================

    private ProductResponse mapToProductResponse(Product product) {
        return ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .description(product.getDescription())
                .price(product.getPrice())
                .stock(product.getStock())
                .category(mapToCategoryResponse(product.getCategory()))
                .imageUrl(product.getImageUrl())
                .active(product.getActive())
                .createdAt(product.getCreatedAt())
                .updatedAt(product.getUpdatedAt())
                .build();
    }

    private CategoryResponse mapToCategoryResponse(Category category) {
        return CategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .description(category.getDescription())
                .active(category.getActive())
                .createdAt(category.getCreatedAt())
                .updatedAt(category.getUpdatedAt())
                .build();
    }
}

