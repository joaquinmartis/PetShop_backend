package com.virtualpet.ecommerce.modules.order.service;

import com.virtualpet.ecommerce.modules.cart.entity.Cart;
import com.virtualpet.ecommerce.modules.cart.entity.CartItem;
import com.virtualpet.ecommerce.modules.cart.service.CartService;
import com.virtualpet.ecommerce.modules.order.dto.*;
import com.virtualpet.ecommerce.modules.order.entity.Order;
import com.virtualpet.ecommerce.modules.order.entity.OrderItem;
import com.virtualpet.ecommerce.modules.order.entity.OrderStatusHistory;
import com.virtualpet.ecommerce.modules.order.repository.OrderRepository;
import com.virtualpet.ecommerce.modules.order.repository.OrderStatusHistoryRepository;
import com.virtualpet.ecommerce.modules.product.dto.CheckAvailabilityResponse;
import com.virtualpet.ecommerce.modules.product.dto.StockItem;
import com.virtualpet.ecommerce.modules.product.service.ProductService;
import com.virtualpet.ecommerce.modules.user.dto.UserResponse;
import com.virtualpet.ecommerce.modules.user.service.UserService;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderStatusHistoryRepository statusHistoryRepository;

    @Autowired
    private CartService cartService;

    @Autowired
    private ProductService productService;

    @Autowired
    private UserService userService;

    // ============================================
    // MÉTODOS PARA CLIENTES
    // ============================================

    /**
     * Crear pedido desde el carrito del usuario
     */
    @Transactional
    public OrderResponse createOrder(Long userId, CreateOrderRequest request) {
        // 1. Obtener información del usuario
        UserResponse user = userService.getUserById(userId);

        // 2. Obtener carrito con items
        Cart cart = cartService.getCartEntity(userId);

        if (cart.getItems().isEmpty()) {
            throw new IllegalArgumentException("El carrito está vacío");
        }

        // 3. Validar stock de todos los productos
        List<StockItem> stockItems = cart.getItems().stream()
                .map(item -> new StockItem(item.getProductId(), item.getQuantity()))
                .collect(Collectors.toList());

        CheckAvailabilityResponse availability = productService.checkAvailability(stockItems);

        if (!availability.getAvailable()) {
            // Stock insuficiente - retornar error con detalles
            StringBuilder errorMessage = new StringBuilder("Stock insuficiente para los siguientes productos:\n");
            availability.getUnavailableProducts().forEach(product ->
                    errorMessage.append(String.format("- %s: solicitaste %d, disponible %d\n",
                            product.getProductName(),
                            product.getRequestedQuantity(),
                            product.getAvailableStock()))
            );
            throw new IllegalArgumentException(errorMessage.toString());
        }

        // 4. Crear el pedido
        Order order = new Order();
        order.setUserId(userId);
        order.setStatus(Order.OrderStatus.CONFIRMED); // Stock ya validado
        order.setShippingAddress(request.getShippingAddress());
        order.setNotes(request.getNotes());

        // Snapshots de información del cliente
        order.setCustomerName(user.getFirstName() + " " + user.getLastName());
        order.setCustomerEmail(user.getEmail());
        order.setCustomerPhone(user.getPhone());

        // Calcular total
        BigDecimal total = cart.getItems().stream()
                .map(CartItem::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal shipping = new BigDecimal("10000");
        total = total.add(shipping);
        order.setTotal(total);

        // 5. Crear los items del pedido (con snapshots del carrito)
        for (CartItem cartItem : cart.getItems()) {
            OrderItem orderItem = new OrderItem();
            orderItem.setOrder(order);
            orderItem.setProductId(cartItem.getProductId());
            orderItem.setProductNameSnapshot(cartItem.getProductNameSnapshot());

            // Obtener imagen del producto actual
            try {
                String imageUrl = productService.getProductById(cartItem.getProductId()).getImageUrl();
                orderItem.setProductImageSnapshot(imageUrl);
            } catch (Exception e) {
                orderItem.setProductImageSnapshot(null);
            }

            orderItem.setQuantity(cartItem.getQuantity());
            orderItem.setUnitPriceSnapshot(cartItem.getUnitPriceSnapshot());

            order.getItems().add(orderItem);
        }

        // 6. Guardar pedido
        order = orderRepository.save(order);

        // 7. Registrar cambio de estado en historial
        recordStatusChange(order, null, Order.OrderStatus.CONFIRMED, userId, Order.CancelledBy.SYSTEM, "Pedido creado y confirmado");

        // 8. Reducir stock de productos
        for (CartItem cartItem : cart.getItems()) {
            productService.reduceStock(cartItem.getProductId(), cartItem.getQuantity());
        }

        // 9. Vaciar carrito
        cartService.clearCartAfterOrder(userId);

        // 10. Retornar respuesta
        return mapToOrderResponse(order);
    }

    /**
     * Obtener pedidos del usuario
     */
    @Transactional(readOnly = true)
    public Page<OrderResponse> getMyOrders(Long userId, Pageable pageable) {
        return orderRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(this::mapToOrderResponse);
    }

    /**
     * Obtener detalle de un pedido del usuario
     */
    @Transactional(readOnly = true)
    public OrderResponse getOrderById(Long userId, Long orderId) {
        Order order = orderRepository.findByIdAndUserId(orderId, userId)
                .orElseThrow(() -> new EntityNotFoundException("Pedido no encontrado"));

        // Cargar items si no están cargados
        order = orderRepository.findByIdWithItems(orderId).orElseThrow();

        return mapToOrderResponse(order);
    }

    /**
     * Cancelar pedido (solo cliente)
     */
    @Transactional
    public OrderResponse cancelOrder(Long userId, Long orderId, CancelOrderRequest request) {
        Order order = orderRepository.findByIdAndUserId(orderId, userId)
                .orElseThrow(() -> new EntityNotFoundException("Pedido no encontrado"));

        // Validar que el pedido pueda ser cancelado
        if (order.getStatus() == Order.OrderStatus.CANCELLED) {
            throw new IllegalArgumentException("El pedido ya está cancelado");
        }

        if (order.getStatus() == Order.OrderStatus.SHIPPED || order.getStatus() == Order.OrderStatus.DELIVERED) {
            throw new IllegalArgumentException("No puedes cancelar un pedido que ya fue despachado o entregado");
        }

        // Cargar items
        order = orderRepository.findByIdWithItems(orderId).orElseThrow();

        Order.OrderStatus previousStatus = order.getStatus();

        // Cancelar pedido
        order.setStatus(Order.OrderStatus.CANCELLED);
        order.setCancellationReason(request.getReason());
        order.setCancelledAt(LocalDateTime.now());
        order.setCancelledBy(Order.CancelledBy.CLIENT);

        order = orderRepository.save(order);

        // Registrar en historial
        recordStatusChange(order, previousStatus, Order.OrderStatus.CANCELLED, userId, Order.CancelledBy.CLIENT, request.getReason());

        // Restaurar stock
        for (OrderItem item : order.getItems()) {
            productService.restoreStock(item.getProductId(), item.getQuantity());
        }

        return mapToOrderResponse(order);
    }

    // ============================================
    // MÉTODOS PARA BACKOFFICE (WAREHOUSE)
    // ============================================

    /**
     * Listar todos los pedidos con filtro de estado
     */
    @Transactional(readOnly = true)
    public Page<OrderResponse> getAllOrders(String status, Pageable pageable) {
        if (status != null && !status.isBlank()) {
            Order.OrderStatus orderStatus = Order.OrderStatus.valueOf(status.toUpperCase());
            return orderRepository.findByStatusOrderByCreatedAtDesc(orderStatus, pageable)
                    .map(this::mapToOrderResponse);
        }
        return orderRepository.findAll(pageable)
                .map(this::mapToOrderResponse);
    }

    /**
     * Obtener detalle de cualquier pedido
     */
    @Transactional(readOnly = true)
    public OrderResponse getOrderByIdAdmin(Long orderId) {
        Order order = orderRepository.findByIdWithItems(orderId)
                .orElseThrow(() -> new EntityNotFoundException("Pedido no encontrado"));
        return mapToOrderResponse(order);
    }

    /**
     * Marcar pedido como listo para enviar
     */
    @Transactional
    public OrderResponse markReadyToShip(Long orderId, Long warehouseUserId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new EntityNotFoundException("Pedido no encontrado"));

        if (order.getStatus() != Order.OrderStatus.CONFIRMED) {
            throw new IllegalArgumentException("Solo se pueden marcar como listos los pedidos confirmados");
        }

        Order.OrderStatus previousStatus = order.getStatus();
        order.setStatus(Order.OrderStatus.READY_TO_SHIP);
        order = orderRepository.save(order);

        recordStatusChange(order, previousStatus, Order.OrderStatus.READY_TO_SHIP, warehouseUserId, Order.CancelledBy.WAREHOUSE, null);

        return mapToOrderResponse(order);
    }

    /**
     * Marcar pedido como despachado
     */
    @Transactional
    public OrderResponse markShipped(Long orderId, Long warehouseUserId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new EntityNotFoundException("Pedido no encontrado"));

        if (order.getStatus() != Order.OrderStatus.READY_TO_SHIP) {
            throw new IllegalArgumentException("Solo se pueden despachar pedidos listos para enviar");
        }

        Order.OrderStatus previousStatus = order.getStatus();
        order.setStatus(Order.OrderStatus.SHIPPED);
        order = orderRepository.save(order);

        recordStatusChange(order, previousStatus, Order.OrderStatus.SHIPPED, warehouseUserId, Order.CancelledBy.WAREHOUSE, null);

        return mapToOrderResponse(order);
    }

    /**
     * Marcar pedido como entregado
     */
    @Transactional
    public OrderResponse markDelivered(Long orderId, Long warehouseUserId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new EntityNotFoundException("Pedido no encontrado"));

        if (order.getStatus() != Order.OrderStatus.SHIPPED) {
            throw new IllegalArgumentException("Solo se pueden entregar pedidos despachados");
        }

        Order.OrderStatus previousStatus = order.getStatus();
        order.setStatus(Order.OrderStatus.DELIVERED);
        order = orderRepository.save(order);

        recordStatusChange(order, previousStatus, Order.OrderStatus.DELIVERED, warehouseUserId, Order.CancelledBy.WAREHOUSE, null);

        return mapToOrderResponse(order);
    }

    /**
     * Actualizar método de envío
     */
    @Transactional
    public OrderResponse updateShippingMethod(Long orderId, UpdateShippingMethodRequest request, Long warehouseUserId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new EntityNotFoundException("Pedido no encontrado"));

        try {
            Order.ShippingMethod method = Order.ShippingMethod.valueOf(request.getShippingMethod().toUpperCase());
            order.setShippingMethod(method);
            order = orderRepository.save(order);

            return mapToOrderResponse(order);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Método de envío inválido. Debe ser OWN_TEAM o COURIER");
        }
    }

    /**
     * Rechazar pedido (backoffice)
     */
    @Transactional
    public OrderResponse rejectOrder(Long orderId, CancelOrderRequest request, Long warehouseUserId) {
        Order order = orderRepository.findByIdWithItems(orderId)
                .orElseThrow(() -> new EntityNotFoundException("Pedido no encontrado"));

        if (order.getStatus() == Order.OrderStatus.CANCELLED) {
            throw new IllegalArgumentException("El pedido ya está cancelado");
        }

        Order.OrderStatus previousStatus = order.getStatus();

        order.setStatus(Order.OrderStatus.CANCELLED);
        order.setCancellationReason(request.getReason());
        order.setCancelledAt(LocalDateTime.now());
        order.setCancelledBy(Order.CancelledBy.WAREHOUSE);

        order = orderRepository.save(order);

        recordStatusChange(order, previousStatus, Order.OrderStatus.CANCELLED, warehouseUserId, Order.CancelledBy.WAREHOUSE, request.getReason());

        // Restaurar stock
        for (OrderItem item : order.getItems()) {
            productService.restoreStock(item.getProductId(), item.getQuantity());
        }

        return mapToOrderResponse(order);
    }

    // ============================================
    // MÉTODOS PRIVADOS
    // ============================================

    private void recordStatusChange(Order order, Order.OrderStatus fromStatus, Order.OrderStatus toStatus,
                                     Long userId, Order.CancelledBy role, String notes) {
        OrderStatusHistory history = new OrderStatusHistory();
        history.setOrder(order);
        history.setFromStatus(fromStatus);
        history.setToStatus(toStatus);
        history.setChangedByUserId(userId);
        history.setChangedByRole(role);
        history.setNotes(notes);

        statusHistoryRepository.save(history);
    }

    private OrderResponse mapToOrderResponse(Order order) {
        List<OrderItemResponse> itemResponses = order.getItems().stream()
                .map(this::mapToOrderItemResponse)
                .collect(Collectors.toList());

        return OrderResponse.builder()
                .id(order.getId())
                .userId(order.getUserId())
                .status(order.getStatus().name())
                .total(order.getTotal())
                .shippingMethod(order.getShippingMethod() != null ? order.getShippingMethod().name() : null)
                .shippingId(order.getShippingId())
                .shippingAddress(order.getShippingAddress())
                .customerName(order.getCustomerName())
                .customerEmail(order.getCustomerEmail())
                .customerPhone(order.getCustomerPhone())
                .notes(order.getNotes())
                .cancellationReason(order.getCancellationReason())
                .cancelledAt(order.getCancelledAt())
                .cancelledBy(order.getCancelledBy() != null ? order.getCancelledBy().name() : null)
                .items(itemResponses)
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt())
                .build();
    }

    private OrderItemResponse mapToOrderItemResponse(OrderItem item) {
        return OrderItemResponse.builder()
                .id(item.getId())
                .productId(item.getProductId())
                .productName(item.getProductNameSnapshot())
                .productImage(item.getProductImageSnapshot())
                .quantity(item.getQuantity())
                .unitPrice(item.getUnitPriceSnapshot())
                .subtotal(item.getSubtotal())
                .build();
    }
}

