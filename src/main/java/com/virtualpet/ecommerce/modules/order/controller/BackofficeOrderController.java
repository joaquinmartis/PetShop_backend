package com.virtualpet.ecommerce.modules.order.controller;

import com.virtualpet.ecommerce.modules.order.dto.CancelOrderRequest;
import com.virtualpet.ecommerce.modules.order.dto.OrderResponse;
import com.virtualpet.ecommerce.modules.order.dto.UpdateShippingMethodRequest;
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
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/backoffice/orders")
@CrossOrigin(origins = "*")
@PreAuthorize("hasRole('WAREHOUSE')")
public class BackofficeOrderController {

    @Autowired
    private OrderService orderService;

    @Autowired
    private UserService userService;

    /**
     * GET /api/backoffice/orders
     * Listar todos los pedidos con filtro de estado
     */
    @GetMapping
    public ResponseEntity<?> getAllOrders(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
            Page<OrderResponse> orders = orderService.getAllOrders(status, pageable);
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
     * GET /api/backoffice/orders/{id}
     * Obtener detalle de cualquier pedido
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getOrderById(@PathVariable Long id) {
        try {
            OrderResponse order = orderService.getOrderByIdAdmin(id);
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
     * PATCH /api/backoffice/orders/{id}/ready-to-ship
     * Marcar pedido como listo para enviar
     */
    @PatchMapping("/{id}/ready-to-ship")
    public ResponseEntity<?> markReadyToShip(
            @PathVariable Long id,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            OrderResponse order = orderService.markReadyToShip(id, userId);
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("OrderError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * PATCH /api/backoffice/orders/{id}/ship
     * Marcar pedido como despachado
     */
    @PatchMapping("/{id}/ship")
    public ResponseEntity<?> markShipped(
            @PathVariable Long id,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            OrderResponse order = orderService.markShipped(id, userId);
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("OrderError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * PATCH /api/backoffice/orders/{id}/deliver
     * Marcar pedido como entregado
     */
    @PatchMapping("/{id}/deliver")
    public ResponseEntity<?> markDelivered(
            @PathVariable Long id,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            OrderResponse order = orderService.markDelivered(id, userId);
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("OrderError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * PATCH /api/backoffice/orders/{id}/shipping-method
     * Actualizar método de envío
     */
    @PatchMapping("/{id}/shipping-method")
    public ResponseEntity<?> updateShippingMethod(
            @PathVariable Long id,
            @Valid @RequestBody UpdateShippingMethodRequest request,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            OrderResponse order = orderService.updateShippingMethod(id, request, userId);
            return ResponseEntity.ok(order);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("OrderError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * PATCH /api/backoffice/orders/{id}/reject
     * Rechazar pedido
     */
    @PatchMapping("/{id}/reject")
    public ResponseEntity<?> rejectOrder(
            @PathVariable Long id,
            @Valid @RequestBody CancelOrderRequest request,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            OrderResponse order = orderService.rejectOrder(id, request, userId);
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

