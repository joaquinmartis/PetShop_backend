package com.virtualpet.ecommerce.modules.order.controller;

import com.virtualpet.ecommerce.modules.order.dto.CancelOrderRequest;
import com.virtualpet.ecommerce.modules.order.dto.CreateOrderRequest;
import com.virtualpet.ecommerce.modules.order.dto.OrderResponse;
import com.virtualpet.ecommerce.modules.order.service.OrderService;
import com.virtualpet.ecommerce.modules.user.dto.ErrorResponse;
import com.virtualpet.ecommerce.modules.user.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/orders")
@CrossOrigin(origins = "*")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @Autowired
    private UserService userService;

    /**
     * POST /api/orders
     * Crear pedido desde el carrito del usuario autenticado
     */
    @PostMapping
    public ResponseEntity<?> createOrder(
            @Valid @RequestBody CreateOrderRequest request,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            OrderResponse order = orderService.createOrder(userId, request);
            return ResponseEntity.status(HttpStatus.CREATED).body(order);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("OrderError")
                    .message(e.getMessage())
                    .build();

            // Si es error de stock, retornar 409 Conflict
            if (e.getMessage().contains("Stock insuficiente")) {
                return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
            }

            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * GET /api/orders
     * Listar pedidos del usuario autenticado
     */
    @GetMapping
    public ResponseEntity<?> getMyOrders(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<OrderResponse> orders = orderService.getMyOrders(userId, pageable);
            return ResponseEntity.ok(orders);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("OrderError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * GET /api/orders/{id}
     * Obtener detalle de un pedido del usuario
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getOrderById(
            @PathVariable Long id,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            OrderResponse order = orderService.getOrderById(userId, id);
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("OrderError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * PATCH /api/orders/{id}/cancel
     * Cancelar pedido
     */
    @PatchMapping("/{id}/cancel")
    public ResponseEntity<?> cancelOrder(
            @PathVariable Long id,
            @Valid @RequestBody CancelOrderRequest request,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            OrderResponse order = orderService.cancelOrder(userId, id, request);
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("OrderError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }
}

