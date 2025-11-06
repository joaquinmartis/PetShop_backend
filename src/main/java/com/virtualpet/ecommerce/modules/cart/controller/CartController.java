package com.virtualpet.ecommerce.modules.cart.controller;

import com.virtualpet.ecommerce.modules.cart.dto.AddToCartRequest;
import com.virtualpet.ecommerce.modules.cart.dto.CartResponse;
import com.virtualpet.ecommerce.modules.cart.dto.UpdateCartItemRequest;
import com.virtualpet.ecommerce.modules.cart.service.CartService;
import com.virtualpet.ecommerce.modules.user.dto.ErrorResponse;
import com.virtualpet.ecommerce.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/cart")
@CrossOrigin(origins = "*")
@Tag(name = "Cart", description = "Gestión del carrito de compras")
@SecurityRequirement(name = "Bearer Authentication")
public class CartController {

    @Autowired
    private CartService cartService;

    @Autowired
    private UserService userService;

    @Operation(
            summary = "Obtener carrito",
            description = "Retorna el carrito de compras del usuario autenticado"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Carrito obtenido exitosamente",
                    content = @Content(schema = @Schema(implementation = CartResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Error al obtener el carrito",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @GetMapping
    public ResponseEntity<CartResponse> getCart(Authentication authentication) {
        String email = authentication.getName();
        Long userId = userService.getProfile(email).getId();

        CartResponse cart = cartService.getCart(userId);
        return ResponseEntity.ok(cart);
    }

    @Operation(
            summary = "Agregar producto al carrito",
            description = "Agrega un producto al carrito o actualiza su cantidad si ya existe"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Producto agregado exitosamente",
                    content = @Content(schema = @Schema(implementation = CartResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Stock insuficiente o producto inválido",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @PostMapping("/items")
    public ResponseEntity<CartResponse> addToCart(
            @Valid @RequestBody AddToCartRequest request,
            Authentication authentication) {
        String email = authentication.getName();
        Long userId = userService.getProfile(email).getId();

        CartResponse cart = cartService.addToCart(userId, request);
        return ResponseEntity.ok(cart);
    }

    @Operation(
            summary = "Actualizar cantidad de producto",
            description = "Actualiza la cantidad de un producto específico en el carrito"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Cantidad actualizada exitosamente",
                    content = @Content(schema = @Schema(implementation = CartResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Stock insuficiente o producto no encontrado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @PatchMapping("/items/{productId}")
    public ResponseEntity<CartResponse> updateCartItem(
            @Parameter(description = "ID del producto") @PathVariable Long productId,
            @Valid @RequestBody UpdateCartItemRequest request,
            Authentication authentication) {
        String email = authentication.getName();
        Long userId = userService.getProfile(email).getId();

        CartResponse cart = cartService.updateCartItem(userId, productId, request);
        return ResponseEntity.ok(cart);
    }

    @Operation(
            summary = "Eliminar producto del carrito",
            description = "Elimina un producto específico del carrito"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Producto eliminado exitosamente",
                    content = @Content(schema = @Schema(implementation = CartResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Error al eliminar el producto",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @DeleteMapping("/items/{productId}")
    public ResponseEntity<CartResponse> removeFromCart(
            @Parameter(description = "ID del producto a eliminar") @PathVariable Long productId,
            Authentication authentication) {
        String email = authentication.getName();
        Long userId = userService.getProfile(email).getId();

        CartResponse cart = cartService.removeFromCart(userId, productId);
        return ResponseEntity.ok(cart);
    }

    @Operation(
            summary = "Vaciar carrito",
            description = "Elimina todos los productos del carrito"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Carrito vaciado exitosamente",
                    content = @Content(schema = @Schema(implementation = MessageResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Error al vaciar el carrito",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @DeleteMapping("/clear")
    public ResponseEntity<MessageResponse> clearCart(Authentication authentication) {
        String email = authentication.getName();
        Long userId = userService.getProfile(email).getId();

        cartService.clearCart(userId);

        return ResponseEntity.ok().body(new MessageResponse("Carrito vaciado exitosamente"));
    }

    // Clase interna para respuestas simples
    @Schema(description = "Respuesta simple con mensaje de texto")
    public static class MessageResponse {
        @Schema(description = "Mensaje de respuesta", example = "Carrito vaciado exitosamente")
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

