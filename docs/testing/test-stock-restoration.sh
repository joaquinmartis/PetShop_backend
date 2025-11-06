#!/bin/bash

# ============================================
# TEST VALIDACIÓN DE RESTAURACIÓN DE STOCK
# Verifica que el stock se restaura al cancelar pedidos
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

BASE_URL="http://localhost:8080/api"
TEST_EMAIL="stock-test-$(date +%s)@example.com"
TOKEN=""
PRODUCT_ID=""
INITIAL_STOCK=0
AFTER_ORDER_STOCK=0
AFTER_CANCEL_STOCK=0
ORDER_ID=""

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}➤ $1${NC}"
}

print_success() {
    echo -e "${GREEN}   ✅ $1${NC}"
}

print_failure() {
    echo -e "${RED}   ❌ $1${NC}"
}

print_info() {
    echo -e "${CYAN}   📋 $1${NC}"
}

print_header "TEST: VALIDACIÓN DE RESTAURACIÓN DE STOCK AL CANCELAR"

echo -e "${YELLOW}Este test verifica que el stock se restaura correctamente${NC}"
echo -e "${YELLOW}cuando un cliente cancela un pedido${NC}"
echo ""

# ============================================
# PASO 1: REGISTRO Y LOGIN
# ============================================
print_step "1. Registrando usuario de prueba"

curl -s -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"password123\",
        \"firstName\": \"Test\",
        \"lastName\": \"Stock\",
        \"phone\": \"1234567890\",
        \"address\": \"Test Address\"
    }" > /dev/null

RESPONSE=$(curl -s -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$TEST_EMAIL\", \"password\": \"password123\"}")

TOKEN=$(echo "$RESPONSE" | jq -r '.accessToken' 2>/dev/null)

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    print_success "Usuario registrado y autenticado"
else
    print_failure "Error al autenticar usuario"
    exit 1
fi

# ============================================
# PASO 2: OBTENER PRODUCTO Y STOCK INICIAL
# ============================================
echo ""
print_step "2. Obteniendo producto y stock inicial"

RESPONSE=$(curl -s -X GET "$BASE_URL/products?page=0&size=1")
PRODUCT=$(echo "$RESPONSE" | jq '.content[0]' 2>/dev/null)

PRODUCT_ID=$(echo "$PRODUCT" | jq -r '.id' 2>/dev/null)
PRODUCT_NAME=$(echo "$PRODUCT" | jq -r '.name' 2>/dev/null)
INITIAL_STOCK=$(echo "$PRODUCT" | jq -r '.stock' 2>/dev/null)

print_info "Producto seleccionado: $PRODUCT_NAME (ID: $PRODUCT_ID)"
print_info "Stock INICIAL: $INITIAL_STOCK unidades"

# ============================================
# PASO 3: CREAR PEDIDO (REDUCE STOCK)
# ============================================
echo ""
print_step "3. Creando pedido con 5 unidades del producto"

QUANTITY=5

# Agregar al carrito
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT_ID, \"quantity\": $QUANTITY}" > /dev/null

# Crear pedido
RESPONSE=$(curl -s -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Test Address\"}")

ORDER_ID=$(echo "$RESPONSE" | jq -r '.id' 2>/dev/null)

if [ -n "$ORDER_ID" ] && [ "$ORDER_ID" != "null" ]; then
    print_success "Pedido #$ORDER_ID creado exitosamente"
    print_info "Cantidad en pedido: $QUANTITY unidades"
else
    print_failure "Error al crear pedido"
    exit 1
fi

# ============================================
# PASO 4: VERIFICAR STOCK DESPUÉS DEL PEDIDO
# ============================================
echo ""
print_step "4. Verificando stock después de crear el pedido"

RESPONSE=$(curl -s -X GET "$BASE_URL/products/$PRODUCT_ID")
AFTER_ORDER_STOCK=$(echo "$RESPONSE" | jq -r '.stock' 2>/dev/null)

EXPECTED_STOCK=$((INITIAL_STOCK - QUANTITY))

print_info "Stock DESPUÉS del pedido: $AFTER_ORDER_STOCK unidades"
print_info "Stock esperado: $EXPECTED_STOCK unidades"

if [ "$AFTER_ORDER_STOCK" -eq "$EXPECTED_STOCK" ]; then
    print_success "✓ Stock reducido correctamente al crear el pedido"
else
    print_failure "✗ Stock NO se redujo correctamente"
    print_info "Esperado: $EXPECTED_STOCK, Obtenido: $AFTER_ORDER_STOCK"
fi

# ============================================
# PASO 5: CANCELAR EL PEDIDO
# ============================================
echo ""
print_step "5. Cancelando el pedido #$ORDER_ID"

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/orders/$ORDER_ID/cancel" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"reason": "Test de restauración de stock"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -eq 200 ]; then
    print_success "Pedido cancelado exitosamente"
else
    print_failure "Error al cancelar pedido (HTTP $HTTP_CODE)"
    exit 1
fi

# ============================================
# PASO 6: VERIFICAR STOCK RESTAURADO
# ============================================
echo ""
print_step "6. Verificando restauración del stock"

# Esperar un momento para que se procese la restauración
sleep 1

RESPONSE=$(curl -s -X GET "$BASE_URL/products/$PRODUCT_ID")
AFTER_CANCEL_STOCK=$(echo "$RESPONSE" | jq -r '.stock' 2>/dev/null)

print_info "Stock DESPUÉS de cancelar: $AFTER_CANCEL_STOCK unidades"
print_info "Stock INICIAL (esperado): $INITIAL_STOCK unidades"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  📊 COMPARACIÓN DE STOCK${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

echo "  Momento                    | Stock"
echo "  ───────────────────────────┼───────"
echo "  1. Stock inicial           | $INITIAL_STOCK"
echo "  2. Después de crear pedido | $AFTER_ORDER_STOCK (reducido $QUANTITY)"
echo "  3. Después de cancelar     | $AFTER_CANCEL_STOCK"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"

# ============================================
# RESULTADO FINAL
# ============================================
echo ""

if [ "$AFTER_CANCEL_STOCK" -eq "$INITIAL_STOCK" ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  ✅ TEST EXITOSO ✅                                ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  El stock se RESTAURÓ correctamente               ║${NC}"
    echo -e "${GREEN}║  al cancelar el pedido                            ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  Stock inicial:      $INITIAL_STOCK unidades                     ║${NC}"
    echo -e "${GREEN}║  Stock actual:       $AFTER_CANCEL_STOCK unidades                     ║${NC}"
    echo -e "${GREEN}║  Diferencia:         0 unidades ✓                 ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  🎉 Sistema funciona correctamente 🐾             ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
else
    DIFFERENCE=$((INITIAL_STOCK - AFTER_CANCEL_STOCK))
    echo -e "${RED}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}║  ❌ TEST FALLIDO ❌                                ║${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}║  El stock NO se restauró correctamente            ║${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}║  Stock inicial:      $INITIAL_STOCK unidades                     ║${NC}"
    echo -e "${RED}║  Stock actual:       $AFTER_CANCEL_STOCK unidades                     ║${NC}"
    echo -e "${RED}║  Diferencia:         $DIFFERENCE unidades ✗                 ║${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}║  ⚠️  BUG DETECTADO: Stock no restaurado           ║${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi

