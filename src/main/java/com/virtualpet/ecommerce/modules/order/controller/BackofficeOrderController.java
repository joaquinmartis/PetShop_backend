package com.virtualpet.ecommerce.modules.order.controller;

import com.virtualpet.ecommerce.modules.order.dto.CancelOrderRequest;
import com.virtualpet.ecommerce.modules.order.dto.OrderResponse;
import com.virtualpet.ecommerce.modules.order.dto.UpdateShippingMethodRequest;
import com.virtualpet.ecommerce.modules.order.service.OrderService;
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
@Tag(name = "Orders - Backoffice", description = "Gestión de pedidos para empleados de almacén (WAREHOUSE)")
@SecurityRequirement(name = "Bearer Authentication")
public class BackofficeOrderController {

    @Autowired
    private OrderService orderService;

    @Autowired
    private UserService userService;

    @Operation(
            summary = "Listar todos los pedidos",
            description = "Obtiene una lista paginada de todos los pedidos con filtro opcional por estado. Requiere rol WAREHOUSE."
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Lista de pedidos obtenida exitosamente",
                    content = @Content(schema = @Schema(implementation = Page.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Error al obtener pedidos",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Sin permisos (requiere rol WAREHOUSE)",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @GetMapping
    public ResponseEntity<Page<OrderResponse>> getAllOrders(
            @Parameter(description = "Filtrar por estado (PENDING, CONFIRMED, READY_TO_SHIP, SHIPPED, DELIVERED, CANCELLED, REJECTED)")
            @RequestParam(required = false) String status,
            @Parameter(description = "Número de página") @RequestParam(defaultValue = "0") int page,
            @Parameter(description = "Elementos por página") @RequestParam(defaultValue = "10") int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<OrderResponse> orders = orderService.getAllOrders(status, pageable);
        return ResponseEntity.ok(orders);
    }

    @Operation(
            summary = "Obtener detalle de pedido",
            description = "Retorna la información completa de cualquier pedido. Requiere rol WAREHOUSE."
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Pedido encontrado",
                    content = @Content(schema = @Schema(implementation = OrderResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Sin permisos",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Pedido no encontrado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @GetMapping("/{id}")
    public ResponseEntity<OrderResponse> getOrderById(@Parameter(description = "ID del pedido") @PathVariable Long id) {
        OrderResponse order = orderService.getOrderByIdAdmin(id);
        return ResponseEntity.ok(order);
    }

    @Operation(
            summary = "Marcar como listo para enviar",
            description = "Cambia el estado del pedido a READY_TO_SHIP. Solo aplica si está en CONFIRMED."
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Estado actualizado exitosamente",
                    content = @Content(schema = @Schema(implementation = OrderResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Estado inválido para esta transición",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Sin permisos",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @PatchMapping("/{id}/ready-to-ship")
    public ResponseEntity<OrderResponse> markReadyToShip(
            @Parameter(description = "ID del pedido") @PathVariable Long id,
            Authentication authentication) {
        String email = authentication.getName();
        Long userId = userService.getProfile(email).getId();

        OrderResponse order = orderService.markReadyToShip(id, userId);
        return ResponseEntity.ok(order);
    }

    @Operation(
            summary = "Marcar como despachado",
            description = "Cambia el estado del pedido a SHIPPED. Solo aplica si está en READY_TO_SHIP."
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Pedido despachado exitosamente",
                    content = @Content(schema = @Schema(implementation = OrderResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Estado inválido para esta transición",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Sin permisos",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @PatchMapping("/{id}/ship")
    public ResponseEntity<OrderResponse> markShipped(
            @Parameter(description = "ID del pedido") @PathVariable Long id,
            Authentication authentication) {
        String email = authentication.getName();
        Long userId = userService.getProfile(email).getId();

        OrderResponse order = orderService.markShipped(id, userId);
        return ResponseEntity.ok(order);
    }

    @Operation(
            summary = "Marcar como entregado",
            description = "Cambia el estado del pedido a DELIVERED. Solo aplica si está en SHIPPED."
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Pedido marcado como entregado",
                    content = @Content(schema = @Schema(implementation = OrderResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Estado inválido para esta transición",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Sin permisos",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @PatchMapping("/{id}/deliver")
    public ResponseEntity<OrderResponse> markDelivered(
            @Parameter(description = "ID del pedido") @PathVariable Long id,
            Authentication authentication) {
        String email = authentication.getName();
        Long userId = userService.getProfile(email).getId();

        OrderResponse order = orderService.markDelivered(id, userId);
        return ResponseEntity.ok(order);
    }

    @Operation(
            summary = "Actualizar método de envío",
            description = "Actualiza el método de envío del pedido. Solo aplica si está en CONFIRMED o READY_TO_SHIP."
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Método de envío actualizado",
                    content = @Content(schema = @Schema(implementation = OrderResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Estado inválido o método de envío inválido",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Sin permisos",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @PatchMapping("/{id}/shipping-method")
    public ResponseEntity<OrderResponse> updateShippingMethod(
            @Parameter(description = "ID del pedido") @PathVariable Long id,
            @Valid @RequestBody UpdateShippingMethodRequest request,
            Authentication authentication) {
        String email = authentication.getName();
        Long userId = userService.getProfile(email).getId();

        OrderResponse order = orderService.updateShippingMethod(id, request, userId);
        return ResponseEntity.ok(order);
    }

    @Operation(
            summary = "Rechazar pedido",
            description = "Rechaza un pedido y restaura el stock. Solo aplica si está en PENDING o CONFIRMED."
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Pedido rechazado exitosamente",
                    content = @Content(schema = @Schema(implementation = OrderResponse.class))
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Estado inválido para rechazo",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "401",
                    description = "No autenticado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "403",
                    description = "Sin permisos",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))
            )
    })
    @PatchMapping("/{id}/reject")
    public ResponseEntity<OrderResponse> rejectOrder(
            @Parameter(description = "ID del pedido") @PathVariable Long id,
            @Valid @RequestBody CancelOrderRequest request,
            Authentication authentication) {
        String email = authentication.getName();
        Long userId = userService.getProfile(email).getId();

        OrderResponse order = orderService.rejectOrder(id, request, userId);
        return ResponseEntity.ok(order);
    }
}

