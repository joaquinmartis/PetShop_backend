package com.virtualpet.ecommerce.modules.product.controller;

import com.virtualpet.ecommerce.modules.product.dto.CheckAvailabilityRequest;
import com.virtualpet.ecommerce.modules.product.dto.CheckAvailabilityResponse;
import com.virtualpet.ecommerce.modules.product.dto.ProductResponse;
import com.virtualpet.ecommerce.modules.product.service.ProductService;
import com.virtualpet.ecommerce.modules.user.dto.ErrorResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
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
@Tag(name = "Product Catalog", description = "Gestión del catálogo de productos")
public class ProductController {

    @Autowired
    private ProductService productService;

    @Operation(
            summary = "Listar productos",
            description = "Obtiene una lista paginada de productos con filtros opcionales por categoría, nombre y disponibilidad de stock"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Lista de productos obtenida exitosamente",
                    content = @Content(schema = @Schema(implementation = Page.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @GetMapping
    public ResponseEntity<Page<ProductResponse>> getProducts(
            @Parameter(description = "ID de categoría para filtrar") @RequestParam(required = false) Long categoryId,
            @Parameter(description = "Nombre o parte del nombre del producto") @RequestParam(required = false) String name,
            @Parameter(description = "Filtrar solo productos con stock disponible") @RequestParam(required = false) Boolean inStock,
            @Parameter(description = "Número de página (empieza en 0)") @RequestParam(defaultValue = "0") int page,
            @Parameter(description = "Cantidad de elementos por página") @RequestParam(defaultValue = "10") int size,
            @Parameter(description = "Campo para ordenar (ej: 'name' o 'price,asc')") @RequestParam(defaultValue = "name") String sort) {

        // Parsear el sort para soportar formato "field,direction"
        Sort sortObj;
        if (sort.contains(",")) {
            String[] parts = sort.split(",");
            String field = parts[0];
            String direction = parts.length > 1 ? parts[1] : "asc";
            sortObj = direction.equalsIgnoreCase("desc") ? Sort.by(field).descending() : Sort.by(field).ascending();
        } else {
            sortObj = Sort.by(sort).ascending();
        }

        Pageable pageable = PageRequest.of(page, size, sortObj);
        Page<ProductResponse> products = productService.searchProducts(categoryId, name, inStock, pageable);
        return ResponseEntity.ok(products);
    }

    @Operation(
            summary = "Obtener producto por ID",
            description = "Retorna el detalle completo de un producto específico"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Producto encontrado",
                    content = @Content(schema = @Schema(implementation = ProductResponse.class))
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Producto no encontrado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @GetMapping("/{id}")
    public ResponseEntity<ProductResponse> getProductById(@Parameter(description = "ID del producto") @PathVariable Long id) {
        ProductResponse product = productService.getProductById(id);
        return ResponseEntity.ok(product);
    }

    @Operation(
            summary = "Verificar disponibilidad de stock",
            description = "Verifica si hay stock disponible para múltiples productos. Usado internamente por Cart y Order Management"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Verificación completada",
                    content = @Content(schema = @Schema(implementation = CheckAvailabilityResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Datos inválidos",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @PostMapping("/check-availability")
    public ResponseEntity<CheckAvailabilityResponse> checkAvailability(
            @Valid @RequestBody CheckAvailabilityRequest request) {
        CheckAvailabilityResponse response = productService.checkAvailability(request.getItems());
        return ResponseEntity.ok(response);
    }
}

