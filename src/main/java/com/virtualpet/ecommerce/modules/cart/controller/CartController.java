package com.virtualpet.ecommerce.modules.cart.controller;

import com.virtualpet.ecommerce.modules.cart.dto.AddToCartRequest;
import com.virtualpet.ecommerce.modules.cart.dto.CartResponse;
import com.virtualpet.ecommerce.modules.cart.dto.UpdateCartItemRequest;
import com.virtualpet.ecommerce.modules.cart.service.CartService;
import com.virtualpet.ecommerce.modules.user.dto.ErrorResponse;
import com.virtualpet.ecommerce.modules.user.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/cart")
@CrossOrigin(origins = "*")
public class CartController {

    @Autowired
    private CartService cartService;

    @Autowired
    private UserService userService;

    /**
     * GET /api/cart
     * Obtener carrito del usuario autenticado
     */
    @GetMapping
    public ResponseEntity<?> getCart(Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            CartResponse cart = cartService.getCart(userId);
            return ResponseEntity.ok(cart);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("CartError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * POST /api/cart/items
     * Agregar producto al carrito
     */
    @PostMapping("/items")
    public ResponseEntity<?> addToCart(
            @Valid @RequestBody AddToCartRequest request,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            CartResponse cart = cartService.addToCart(userId, request);
            return ResponseEntity.ok(cart);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("CartError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * PATCH /api/cart/items/{productId}
     * Actualizar cantidad de un producto en el carrito
     */
    @PatchMapping("/items/{productId}")
    public ResponseEntity<?> updateCartItem(
            @PathVariable Long productId,
            @Valid @RequestBody UpdateCartItemRequest request,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            CartResponse cart = cartService.updateCartItem(userId, productId, request);
            return ResponseEntity.ok(cart);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("CartError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * DELETE /api/cart/items/{productId}
     * Eliminar un producto del carrito
     */
    @DeleteMapping("/items/{productId}")
    public ResponseEntity<?> removeFromCart(
            @PathVariable Long productId,
            Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            CartResponse cart = cartService.removeFromCart(userId, productId);
            return ResponseEntity.ok(cart);
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("CartError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * DELETE /api/cart/clear
     * Vaciar carrito completo
     */
    @DeleteMapping("/clear")
    public ResponseEntity<?> clearCart(Authentication authentication) {
        try {
            String email = authentication.getName();
            Long userId = userService.getProfile(email).getId();

            cartService.clearCart(userId);

            return ResponseEntity.ok().body(new MessageResponse("Carrito vaciado exitosamente"));
        } catch (RuntimeException e) {
            ErrorResponse error = ErrorResponse.builder()
                    .error("CartError")
                    .message(e.getMessage())
                    .build();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    // Clase interna para respuestas simples
    private static class MessageResponse {
        private String message;

        public MessageResponse(String message) {
            this.message = message;
        }

        public String getMessage() {
            return message;
        }

        public void setMessage(String message) {
            this.message = message;
        }
    }
}

