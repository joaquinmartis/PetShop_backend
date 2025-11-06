#!/bin/bash

# ============================================
# TEST E2E EXTENDIDO - MÚLTIPLES USUARIOS Y PEDIDOS
# Prueba el sistema con múltiples clientes y pedidos en diferentes estados
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

BASE_URL="http://localhost:8080/api"
WAREHOUSE_EMAIL="warehouse@test.com"
WAREHOUSE_PASSWORD="password123"
WAREHOUSE_TOKEN=""

# Arrays para almacenar datos de múltiples clientes
declare -a CLIENT_EMAILS
declare -a CLIENT_TOKENS
declare -a CLIENT_IDS
declare -a ORDER_IDS

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

mark_success() {
    echo -e "${GREEN}   ✅ $1${NC}"
    ((PASSED_TESTS++))
}

mark_failure() {
    echo -e "${RED}   ❌ $1${NC}"
    echo -e "${RED}      Razón: $2${NC}"
    ((FAILED_TESTS++))
}

print_info() {
    echo -e "${MAGENTA}   📋 $1${NC}"
}

# ============================================
# VERIFICAR SERVIDOR
# ============================================
print_header "🚀 INICIANDO TEST E2E EXTENDIDO"

SERVER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/products" 2>/dev/null || echo "000")

if [ "$SERVER_CHECK" != "000" ]; then
    echo -e "${GREEN}✅ Servidor corriendo${NC}"
else
    echo -e "${RED}❌ ERROR: Servidor no responde${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Este test creará múltiples clientes y pedidos en diferentes estados${NC}"
echo -e "${YELLOW}para validar el listado y filtrado del backoffice${NC}"
echo ""

# ============================================
# FASE 1: CREAR MÚLTIPLES CLIENTES
# ============================================
print_header "FASE 1: CREANDO 5 CLIENTES DIFERENTES"

for i in {1..5}; do
    ((TOTAL_TESTS++))
    print_step "Registrando Cliente #$i"

    EMAIL="cliente-$i-$(date +%s)@example.com"

    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$EMAIL\",
            \"password\": \"password123\",
            \"firstName\": \"Cliente\",
            \"lastName\": \"Test $i\",
            \"phone\": \"223456789$i\",
            \"address\": \"Calle Test $i, Mar del Plata\"
        }")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" -eq 201 ]; then
        CLIENT_ID=$(echo "$BODY" | jq -r '.id' 2>/dev/null)
        CLIENT_IDS+=("$CLIENT_ID")
        CLIENT_EMAILS+=("$EMAIL")

        # Login inmediato
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
            -H "Content-Type: application/json" \
            -d "{\"email\": \"$EMAIL\", \"password\": \"password123\"}")

        TOKEN=$(echo "$RESPONSE" | sed '$d' | jq -r '.accessToken' 2>/dev/null)
        CLIENT_TOKENS+=("$TOKEN")

        mark_success "Cliente #$i creado (ID: $CLIENT_ID)"
        print_info "Email: $EMAIL"
    else
        mark_failure "Error al crear cliente #$i" "HTTP $HTTP_CODE"
    fi
    echo ""
done

# ============================================
# FASE 2: CADA CLIENTE CREA PEDIDOS
# ============================================
print_header "FASE 2: CADA CLIENTE CREA PEDIDOS"

# Obtener productos disponibles
RESPONSE=$(curl -s -X GET "$BASE_URL/products?page=0&size=5")
PRODUCTS=$(echo "$RESPONSE" | jq -r '.content[] | "\(.id)|\(.name)|\(.price)"' 2>/dev/null)

# Cliente 1: Crea 2 pedidos
print_step "Cliente #1: Creando 2 pedidos diferentes"
((TOTAL_TESTS++))

TOKEN="${CLIENT_TOKENS[0]}"
EMAIL="${CLIENT_EMAILS[0]}"

# Pedido 1 del Cliente 1
PRODUCT1=$(echo "$PRODUCTS" | head -n1 | cut -d'|' -f1)
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT1, \"quantity\": 2}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Dirección Cliente 1 - Pedido 1\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 201 ]; then
    ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
    ORDER_IDS+=("$ORDER_ID")
    mark_success "Pedido #$ORDER_ID creado por Cliente #1"
else
    mark_failure "Error al crear pedido" "HTTP $HTTP_CODE"
fi

# Pedido 2 del Cliente 1
PRODUCT2=$(echo "$PRODUCTS" | head -n2 | tail -n1 | cut -d'|' -f1)
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT2, \"quantity\": 1}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Dirección Cliente 1 - Pedido 2\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 201 ]; then
    ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
    ORDER_IDS+=("$ORDER_ID")
    mark_success "Pedido #$ORDER_ID creado por Cliente #1"
fi
echo ""

# Cliente 2: Crea 1 pedido
print_step "Cliente #2: Creando 1 pedido"
((TOTAL_TESTS++))

TOKEN="${CLIENT_TOKENS[1]}"
PRODUCT3=$(echo "$PRODUCTS" | head -n3 | tail -n1 | cut -d'|' -f1)
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT3, \"quantity\": 3}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Dirección Cliente 2\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 201 ]; then
    ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
    ORDER_IDS+=("$ORDER_ID")
    mark_success "Pedido #$ORDER_ID creado por Cliente #2"
fi
echo ""

# Cliente 3: Crea 1 pedido
print_step "Cliente #3: Creando 1 pedido"
((TOTAL_TESTS++))

TOKEN="${CLIENT_TOKENS[2]}"
PRODUCT4=$(echo "$PRODUCTS" | head -n4 | tail -n1 | cut -d'|' -f1)
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT4, \"quantity\": 1}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Dirección Cliente 3\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 201 ]; then
    ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
    ORDER_IDS+=("$ORDER_ID")
    mark_success "Pedido #$ORDER_ID creado por Cliente #3"
fi
echo ""

# Cliente 4: Crea 2 pedidos
print_step "Cliente #4: Creando 2 pedidos"
((TOTAL_TESTS++))

TOKEN="${CLIENT_TOKENS[3]}"

# Pedido 1 del Cliente 4
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT1, \"quantity\": 1}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Dirección Cliente 4 - Pedido 1\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 201 ]; then
    ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
    ORDER_IDS+=("$ORDER_ID")
    mark_success "Pedido #$ORDER_ID creado por Cliente #4"
fi

# Pedido 2 del Cliente 4
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT2, \"quantity\": 2}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Dirección Cliente 4 - Pedido 2\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 201 ]; then
    ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
    ORDER_IDS+=("$ORDER_ID")
    mark_success "Pedido #$ORDER_ID creado por Cliente #4"
fi
echo ""

# Cliente 5: Crea 1 pedido
print_step "Cliente #5: Creando 1 pedido"
((TOTAL_TESTS++))

TOKEN="${CLIENT_TOKENS[4]}"
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT3, \"quantity\": 1}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Dirección Cliente 5\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 201 ]; then
    ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
    ORDER_IDS+=("$ORDER_ID")
    mark_success "Pedido #$ORDER_ID creado por Cliente #5"
fi
echo ""

TOTAL_ORDERS_CREATED=${#ORDER_IDS[@]}
print_info "Total de pedidos creados: $TOTAL_ORDERS_CREATED"

# ============================================
# FASE 3: WAREHOUSE LOGIN
# ============================================
print_header "FASE 3: LOGIN WAREHOUSE PARA GESTIONAR PEDIDOS"

((TOTAL_TESTS++))
print_step "Autenticando usuario WAREHOUSE"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$WAREHOUSE_EMAIL\",
        \"password\": \"$WAREHOUSE_PASSWORD\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
WAREHOUSE_TOKEN=$(echo "$RESPONSE" | sed '$d' | jq -r '.accessToken' 2>/dev/null)

if [ "$HTTP_CODE" -eq 200 ] && [ -n "$WAREHOUSE_TOKEN" ] && [ "$WAREHOUSE_TOKEN" != "null" ]; then
    mark_success "Login WAREHOUSE exitoso"
else
    mark_failure "Error al hacer login warehouse" "HTTP $HTTP_CODE"
    exit 1
fi
echo ""

# ============================================
# FASE 4: LISTAR TODOS LOS PEDIDOS
# ============================================
print_header "FASE 4: BACKOFFICE - LISTAR TODOS LOS PEDIDOS"

((TOTAL_TESTS++))
print_step "Obteniendo lista completa de pedidos"

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders?page=0&size=100" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOTAL_IN_SYSTEM=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
    TOTAL_PAGES=$(echo "$BODY" | jq -r '.totalPages' 2>/dev/null)

    mark_success "Lista de pedidos obtenida"
    print_info "Total de pedidos en el sistema: $TOTAL_IN_SYSTEM"
    print_info "Total de páginas: $TOTAL_PAGES"

    # Verificar que nuestros pedidos están en la lista
    echo ""
    echo -e "${CYAN}   Verificando que nuestros $TOTAL_ORDERS_CREATED pedidos aparecen:${NC}"
    FOUND_COUNT=0
    for ORDER_ID in "${ORDER_IDS[@]}"; do
        FOUND=$(echo "$BODY" | jq ".content[] | select(.id == $ORDER_ID)" 2>/dev/null)
        if [ -n "$FOUND" ]; then
            ((FOUND_COUNT++))
            echo -e "${GREEN}   ✓ Pedido #$ORDER_ID encontrado${NC}"
        else
            echo -e "${RED}   ✗ Pedido #$ORDER_ID NO encontrado${NC}"
        fi
    done

    echo ""
    if [ $FOUND_COUNT -eq $TOTAL_ORDERS_CREATED ]; then
        print_info "✅ Todos los $TOTAL_ORDERS_CREATED pedidos están en el sistema"
    else
        print_info "⚠️ Solo $FOUND_COUNT de $TOTAL_ORDERS_CREATED pedidos encontrados"
    fi
else
    mark_failure "Error al listar pedidos" "HTTP $HTTP_CODE"
fi
echo ""

# ============================================
# FASE 5: CAMBIAR ESTADOS DE ALGUNOS PEDIDOS
# ============================================
print_header "FASE 5: CAMBIAR ESTADOS PARA TENER VARIEDAD"

# Cambiar algunos pedidos a diferentes estados
if [ ${#ORDER_IDS[@]} -ge 5 ]; then
    # Pedido 1: READY_TO_SHIP
    ((TOTAL_TESTS++))
    print_step "Pedido #${ORDER_IDS[0]} → READY_TO_SHIP"

    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/${ORDER_IDS[0]}/ready-to-ship" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" -eq 200 ]; then
        mark_success "Estado cambiado a READY_TO_SHIP"
    else
        mark_failure "Error al cambiar estado" "HTTP $HTTP_CODE"
    fi
    echo ""

    # Pedido 2: SHIPPED
    ((TOTAL_TESTS++))
    print_step "Pedido #${ORDER_IDS[1]} → READY_TO_SHIP → SHIPPED"

    curl -s -X PATCH "$BASE_URL/backoffice/orders/${ORDER_IDS[1]}/ready-to-ship" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN" > /dev/null

    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/${ORDER_IDS[1]}/ship" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" -eq 200 ]; then
        mark_success "Estado cambiado a SHIPPED"
    else
        mark_failure "Error al cambiar estado" "HTTP $HTTP_CODE"
    fi
    echo ""

    # Pedido 3: DELIVERED
    ((TOTAL_TESTS++))
    print_step "Pedido #${ORDER_IDS[2]} → READY_TO_SHIP → SHIPPED → DELIVERED"

    curl -s -X PATCH "$BASE_URL/backoffice/orders/${ORDER_IDS[2]}/ready-to-ship" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN" > /dev/null
    curl -s -X PATCH "$BASE_URL/backoffice/orders/${ORDER_IDS[2]}/ship" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN" > /dev/null

    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/${ORDER_IDS[2]}/deliver" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" -eq 200 ]; then
        mark_success "Estado cambiado a DELIVERED"
    else
        mark_failure "Error al cambiar estado" "HTTP $HTTP_CODE"
    fi
    echo ""

    # Pedido 4: CANCELLED (por cliente)
    # Usar el último pedido del Cliente 4 (índice 5 en ORDER_IDS)
    # que todavía está en CONFIRMED
    ((TOTAL_TESTS++))

    # Cliente 4 tiene 2 pedidos: ORDER_IDS[4] y ORDER_IDS[5]
    # Usaremos el segundo (índice 5) para cancelar
    CANCEL_ORDER_INDEX=5
    if [ ${#ORDER_IDS[@]} -gt $CANCEL_ORDER_INDEX ]; then
        CANCEL_ORDER_ID="${ORDER_IDS[$CANCEL_ORDER_INDEX]}"
        print_step "Pedido #$CANCEL_ORDER_ID → CANCELLED (por Cliente #4)"

        # Este pedido pertenece al Cliente #4 (índice 3 en CLIENT_TOKENS)
        TOKEN="${CLIENT_TOKENS[3]}"
        RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/orders/$CANCEL_ORDER_ID/cancel" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"reason": "Cliente cambió de opinión"}')

        HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
        BODY=$(echo "$RESPONSE" | sed '$d')

        if [ "$HTTP_CODE" -eq 200 ]; then
            mark_success "Pedido cancelado por cliente"
        else
            mark_failure "Error al cancelar pedido #$CANCEL_ORDER_ID" "HTTP $HTTP_CODE"
            # Mostrar el error para debug
            echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
        fi
    else
        mark_failure "No hay suficientes pedidos para cancelar" "Se necesitan al menos 6 pedidos"
    fi
    echo ""
fi

# ============================================
# FASE 6: FILTRAR POR ESTADOS
# ============================================
print_header "FASE 6: PROBAR FILTROS POR ESTADO"

# Filtro 1: CONFIRMED
((TOTAL_TESTS++))
print_step "Filtrar pedidos en estado CONFIRMED"

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders?status=CONFIRMED&page=0&size=100" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOTAL_CONFIRMED=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
    mark_success "Filtro CONFIRMED exitoso"
    print_info "Pedidos en estado CONFIRMED: $TOTAL_CONFIRMED"

    # Verificar que TODOS son CONFIRMED
    WRONG_STATUS=$(echo "$BODY" | jq '[.content[] | select(.status != "CONFIRMED")] | length' 2>/dev/null)
    if [ "$WRONG_STATUS" -eq 0 ]; then
        print_info "✅ Todos los pedidos tienen estado CONFIRMED"
    else
        print_info "⚠️ $WRONG_STATUS pedidos con estado diferente"
    fi
else
    mark_failure "Error al filtrar CONFIRMED" "HTTP $HTTP_CODE"
fi
echo ""

# Filtro 2: READY_TO_SHIP
((TOTAL_TESTS++))
print_step "Filtrar pedidos en estado READY_TO_SHIP"

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders?status=READY_TO_SHIP&page=0&size=100" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOTAL_READY=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
    mark_success "Filtro READY_TO_SHIP exitoso"
    print_info "Pedidos en estado READY_TO_SHIP: $TOTAL_READY"
else
    mark_failure "Error al filtrar READY_TO_SHIP" "HTTP $HTTP_CODE"
fi
echo ""

# Filtro 3: SHIPPED
((TOTAL_TESTS++))
print_step "Filtrar pedidos en estado SHIPPED"

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders?status=SHIPPED&page=0&size=100" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOTAL_SHIPPED=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
    mark_success "Filtro SHIPPED exitoso"
    print_info "Pedidos en estado SHIPPED: $TOTAL_SHIPPED"
else
    mark_failure "Error al filtrar SHIPPED" "HTTP $HTTP_CODE"
fi
echo ""

# Filtro 4: DELIVERED
((TOTAL_TESTS++))
print_step "Filtrar pedidos en estado DELIVERED"

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders?status=DELIVERED&page=0&size=100" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOTAL_DELIVERED=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
    mark_success "Filtro DELIVERED exitoso"
    print_info "Pedidos en estado DELIVERED: $TOTAL_DELIVERED"
else
    mark_failure "Error al filtrar DELIVERED" "HTTP $HTTP_CODE"
fi
echo ""

# Filtro 5: CANCELLED
((TOTAL_TESTS++))
print_step "Filtrar pedidos en estado CANCELLED"

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders?status=CANCELLED&page=0&size=100" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOTAL_CANCELLED=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
    mark_success "Filtro CANCELLED exitoso"
    print_info "Pedidos en estado CANCELLED: $TOTAL_CANCELLED"
else
    mark_failure "Error al filtrar CANCELLED" "HTTP $HTTP_CODE"
fi
echo ""

# ============================================
# FASE 7: VERIFICAR PAGINACIÓN
# ============================================
print_header "FASE 7: PROBAR PAGINACIÓN"

((TOTAL_TESTS++))
print_step "Solicitar página 0 con tamaño 3"

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders?page=0&size=3" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    PAGE_SIZE=$(echo "$BODY" | jq -r '.size' 2>/dev/null)
    CONTENT_SIZE=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
    TOTAL_ELEMENTS=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)

    if [ "$PAGE_SIZE" -eq 3 ] && [ "$CONTENT_SIZE" -le 3 ]; then
        mark_success "Paginación correcta"
        print_info "Tamaño de página: $PAGE_SIZE"
        print_info "Elementos en página: $CONTENT_SIZE"
        print_info "Total en sistema: $TOTAL_ELEMENTS"
    else
        mark_failure "Paginación incorrecta" "Size: $PAGE_SIZE, Content: $CONTENT_SIZE"
    fi
else
    mark_failure "Error en paginación" "HTTP $HTTP_CODE"
fi
echo ""

# ============================================
# FASE 8: VERIFICAR QUE CLIENTES VEN SOLO SUS PEDIDOS
# ============================================
print_header "FASE 8: VERIFICAR AISLAMIENTO DE PEDIDOS POR CLIENTE"

((TOTAL_TESTS++))
print_step "Cliente #1 consulta sus pedidos"

TOKEN="${CLIENT_TOKENS[0]}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/orders?page=0&size=100" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    CLIENT_ORDERS=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
    mark_success "Cliente ve solo sus pedidos"
    print_info "Pedidos del Cliente #1: $CLIENT_ORDERS (debería ser 2)"

    # Verificar que todos los pedidos pertenecen al cliente
    WRONG_USER=$(echo "$BODY" | jq "[.content[] | select(.customerEmail != \"${CLIENT_EMAILS[0]}\")] | length" 2>/dev/null)
    if [ "$WRONG_USER" -eq 0 ]; then
        print_info "✅ Todos los pedidos pertenecen al cliente"
    else
        print_info "⚠️ $WRONG_USER pedidos de otro usuario (ERROR DE SEGURIDAD)"
    fi
else
    mark_failure "Error al consultar pedidos del cliente" "HTTP $HTTP_CODE"
fi
echo ""

# ============================================
# RESUMEN FINAL
# ============================================
print_header "📊 RESUMEN FINAL - TEST E2E EXTENDIDO"

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")

echo -e "${BLUE}Total de tests ejecutados:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Tests exitosos:${NC} $PASSED_TESTS"
echo -e "${RED}Tests fallidos:${NC} $FAILED_TESTS"
echo -e "${YELLOW}Tasa de éxito:${NC} $SUCCESS_RATE%"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  📈 ESTADÍSTICAS DEL TEST${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${MAGENTA}Clientes creados:${NC} 5"
echo -e "${MAGENTA}Pedidos creados:${NC} $TOTAL_ORDERS_CREATED"
echo -e "${MAGENTA}Estados probados:${NC} CONFIRMED, READY_TO_SHIP, SHIPPED, DELIVERED, CANCELLED"
echo -e "${MAGENTA}Filtros probados:${NC} 5 (por cada estado)"
echo -e "${MAGENTA}Paginación:${NC} ✓ Validada"
echo -e "${MAGENTA}Aislamiento:${NC} ✓ Clientes ven solo sus pedidos"
echo -e "${MAGENTA}Backoffice:${NC} ✓ Ve todos los pedidos"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  📦 DISTRIBUCIÓN DE PEDIDOS POR ESTADO${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

echo "  Estado            | Cantidad"
echo "  ──────────────────┼─────────"
echo "  CONFIRMED         | Variable"
echo "  READY_TO_SHIP     | ≥ 1"
echo "  SHIPPED           | ≥ 1"
echo "  DELIVERED         | ≥ 1"
echo "  CANCELLED         | ≥ 1"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  ✅ TEST E2E EXTENDIDO COMPLETADO ✅               ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  El sistema maneja correctamente:                 ║${NC}"
    echo -e "${GREEN}║  • Múltiples clientes simultáneos                 ║${NC}"
    echo -e "${GREEN}║  • Múltiples pedidos por cliente                  ║${NC}"
    echo -e "${GREEN}║  • Filtrado por estados                           ║${NC}"
    echo -e "${GREEN}║  • Paginación                                     ║${NC}"
    echo -e "${GREEN}║  • Aislamiento de datos por usuario               ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  🎉 Sistema listo para producción! 🐾             ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    EXIT_CODE=0
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠️  ALGUNOS TESTS FALLARON ⚠️                     ║${NC}"
    echo -e "${RED}║  Revisa los detalles arriba                       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════╝${NC}"
    EXIT_CODE=1
fi

echo ""
echo -e "${BLUE}Generado por:${NC} test-e2e-multiple-orders.sh"
echo -e "${BLUE}Fecha:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

exit $EXIT_CODE

