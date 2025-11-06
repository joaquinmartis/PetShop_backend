package com.virtualpet.ecommerce.modules.cart.service;

import com.virtualpet.ecommerce.modules.cart.dto.*;
import com.virtualpet.ecommerce.modules.cart.entity.Cart;
import com.virtualpet.ecommerce.modules.cart.entity.CartItem;
import com.virtualpet.ecommerce.modules.cart.repository.CartItemRepository;
import com.virtualpet.ecommerce.modules.cart.repository.CartRepository;
import com.virtualpet.ecommerce.modules.product.dto.ProductResponse;
import com.virtualpet.ecommerce.modules.product.service.ProductService;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class CartService {

    @Autowired
    private CartRepository cartRepository;

    @Autowired
    private CartItemRepository cartItemRepository;

    @Autowired
    private ProductService productService;

    // ============================================
    // MÉTODOS PÚBLICOS - Para clientes
    // ============================================

    /**
     * Obtener carrito del usuario (o crear uno nuevo si no existe)
     */
    @Transactional
    public CartResponse getCart(Long userId) {
        Cart cart = cartRepository.findByUserIdWithItems(userId)
                .orElseGet(() -> createNewCart(userId));
        return mapToCartResponse(cart);
    }

    /**
     * Agregar producto al carrito
     */
    @Transactional
    public CartResponse addToCart(Long userId, AddToCartRequest request) {
        // Validar cantidad
        if (request.getQuantity() <= 0) {
            throw new IllegalArgumentException("La cantidad debe ser mayor a 0");
        }

        // Obtener información del producto desde Product Service
        ProductResponse product = productService.getProductById(request.getProductId());

        // Validar que haya stock suficiente
        if (product.getStock() < request.getQuantity()) {
            throw new IllegalArgumentException("Stock insuficiente. Disponible: " + product.getStock());
        }

        // Obtener o crear carrito
        Cart cart = cartRepository.findByUserId(userId)
                .orElseGet(() -> createNewCart(userId));

        // Verificar si el producto ya está en el carrito
        CartItem existingItem = cartItemRepository
                .findByCartIdAndProductId(cart.getId(), request.getProductId())
                .orElse(null);

        if (existingItem != null) {
            // Actualizar cantidad existente
            int newQuantity = existingItem.getQuantity() + request.getQuantity();

            // Validar stock para la nueva cantidad
            if (product.getStock() < newQuantity) {
                throw new IllegalArgumentException("Stock insuficiente para la cantidad solicitada. Disponible: "
                        + product.getStock() + ", en carrito: " + existingItem.getQuantity());
            }

            existingItem.setQuantity(newQuantity);
            cartItemRepository.save(existingItem);
        } else {
            // Crear nuevo item
            CartItem newItem = new CartItem();
            newItem.setCart(cart);
            newItem.setProductId(request.getProductId());
            newItem.setQuantity(request.getQuantity());
            newItem.setUnitPriceSnapshot(product.getPrice());
            newItem.setProductNameSnapshot(product.getName());

            cart.getItems().add(newItem);
            cartItemRepository.save(newItem);
        }

        // Recargar carrito con items actualizados
        cart = cartRepository.findByUserIdWithItems(userId).orElseThrow();
        return mapToCartResponse(cart);
    }

    /**
     * Actualizar cantidad de un item en el carrito
     */
    @Transactional
    public CartResponse updateCartItem(Long userId, Long productId, UpdateCartItemRequest request) {
        // Validar cantidad
        if (request.getQuantity() <= 0) {
            throw new IllegalArgumentException("La cantidad debe ser mayor a 0");
        }

        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new EntityNotFoundException("Carrito no encontrado"));

        CartItem item = cartItemRepository.findByCartIdAndProductId(cart.getId(), productId)
                .orElseThrow(() -> new EntityNotFoundException("Producto no encontrado en el carrito"));

        // Validar stock disponible
        ProductResponse product = productService.getProductById(productId);
        if (product.getStock() < request.getQuantity()) {
            throw new IllegalArgumentException("Stock insuficiente. Disponible: " + product.getStock());
        }

        item.setQuantity(request.getQuantity());
        cartItemRepository.save(item);

        // Recargar carrito
        cart = cartRepository.findByUserIdWithItems(userId).orElseThrow();
        return mapToCartResponse(cart);
    }

    /**
     * Eliminar un producto del carrito
     */
    @Transactional
    public CartResponse removeFromCart(Long userId, Long productId) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new EntityNotFoundException("Carrito no encontrado"));

        int deleted = cartItemRepository.deleteByCartIdAndProductId(cart.getId(), productId);

        if (deleted == 0) {
            throw new EntityNotFoundException("Producto no encontrado en el carrito");
        }

        // Recargar carrito
        cart = cartRepository.findByUserIdWithItems(userId).orElseThrow();
        return mapToCartResponse(cart);
    }

    /**
     * Vaciar carrito completo
     */
    @Transactional
    public void clearCart(Long userId) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new EntityNotFoundException("Carrito no encontrado"));

        cartItemRepository.deleteAllByCartId(cart.getId());
    }

    // ============================================
    // API PÚBLICA - Para Order Management
    // ============================================

    /**
     * Obtener carrito con validación (usado por Order Management)
     */
    @Transactional(readOnly = true)
    public Cart getCartEntity(Long userId) {
        return cartRepository.findByUserIdWithItems(userId)
                .orElseThrow(() -> new EntityNotFoundException("Carrito no encontrado para el usuario"));
    }

    /**
     * Vaciar carrito después de crear pedido (usado por Order Management)
     */
    @Transactional
    public void clearCartAfterOrder(Long userId) {
        clearCart(userId);
    }

    // ============================================
    // MÉTODOS PRIVADOS
    // ============================================

    private Cart createNewCart(Long userId) {
        Cart cart = new Cart();
        cart.setUserId(userId);
        return cartRepository.save(cart);
    }

    private CartResponse mapToCartResponse(Cart cart) {
        List<CartItemResponse> itemResponses = cart.getItems().stream()
                .map(this::mapToCartItemResponse)
                .collect(Collectors.toList());

        // Calcular totales
        int totalItems = cart.getItems().stream()
                .mapToInt(CartItem::getQuantity)
                .sum();

        BigDecimal totalAmount = cart.getItems().stream()
                .map(CartItem::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return CartResponse.builder()
                .id(cart.getId())
                .userId(cart.getUserId())
                .items(itemResponses)
                .totalItems(totalItems)
                .totalAmount(totalAmount)
                .createdAt(cart.getCreatedAt())
                .updatedAt(cart.getUpdatedAt())
                .build();
    }

    private CartItemResponse mapToCartItemResponse(CartItem item) {
        // Obtener imagen del producto actual (puede haber cambiado)
        String imageUrl = null;
        try {
            ProductResponse product = productService.getProductById(item.getProductId());
            imageUrl = product.getImageUrl();
        } catch (Exception e) {
            // Si el producto fue eliminado, usar null
        }

        return CartItemResponse.builder()
                .id(item.getId())
                .productId(item.getProductId())
                .productName(item.getProductNameSnapshot())
                .quantity(item.getQuantity())
                .unitPrice(item.getUnitPriceSnapshot())
                .subtotal(item.getSubtotal())
                .imageUrl(imageUrl)
                .addedAt(item.getAddedAt())
                .updatedAt(item.getUpdatedAt())
                .build();
    }
}

