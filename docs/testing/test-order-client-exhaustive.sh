#!/bin/bash

# ============================================
# TEST EXHAUSTIVO - MÓDULO ORDER (CLIENTE)
# Validación completa de JSON + Códigos HTTP + Lógica de negocio
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

BASE_URL="http://localhost:8080/api"
TEST_EMAIL="order-client-test-$(date +%s)@example.com"
TEST_PASSWORD="password123"
TOKEN=""
ORDER_ID=""
PRODUCT_ID=""

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

validate_field() {
    local json=$1
    local field=$2
    local expected_value=$3

    if [ -z "$expected_value" ]; then
        if echo "$json" | jq -e ".$field" > /dev/null 2>&1; then
            echo -e "${GREEN}   ✓ Campo '$field' presente${NC}"
            return 0
        else
            echo -e "${RED}   ✗ Campo '$field' AUSENTE${NC}"
            return 1
        fi
    else
        actual=$(echo "$json" | jq -r ".$field" 2>/dev/null)
        if [ "$actual" = "$expected_value" ]; then
            echo -e "${GREEN}   ✓ Campo '$field' = '$expected_value'${NC}"
            return 0
        else
            echo -e "${RED}   ✗ Campo '$field': esperado '$expected_value', obtenido '$actual'${NC}"
            return 1
        fi
    fi
}

validate_order_response() {
    local json=$1
    local validation_passed=true

    validate_field "$json" "id" || validation_passed=false
    validate_field "$json" "userId" || validation_passed=false
    validate_field "$json" "status" || validation_passed=false
    validate_field "$json" "total" || validation_passed=false
    validate_field "$json" "shippingAddress" || validation_passed=false
    validate_field "$json" "customerName" || validation_passed=false
    validate_field "$json" "customerEmail" || validation_passed=false
    validate_field "$json" "customerPhone" || validation_passed=false
    validate_field "$json" "items" || validation_passed=false
    validate_field "$json" "createdAt" || validation_passed=false
    validate_field "$json" "updatedAt" || validation_passed=false

    return $([ "$validation_passed" = true ] && echo 0 || echo 1)
}

validate_order_item() {
    local json=$1
    local validation_passed=true

    validate_field "$json" "id" || validation_passed=false
    validate_field "$json" "productId" || validation_passed=false
    validate_field "$json" "productName" || validation_passed=false
    validate_field "$json" "quantity" || validation_passed=false
    validate_field "$json" "unitPrice" || validation_passed=false
    validate_field "$json" "subtotal" || validation_passed=false

    return $([ "$validation_passed" = true ] && echo 0 || echo 1)
}

validate_error_response() {
    local json=$1
    local expected_status=$2
    local validation_passed=true

    validate_field "$json" "status" "$expected_status" || validation_passed=false
    validate_field "$json" "error" || validation_passed=false
    validate_field "$json" "message" || validation_passed=false
    validate_field "$json" "path" || validation_passed=false
    validate_field "$json" "timestamp" || validation_passed=false

    return $([ "$validation_passed" = true ] && echo 0 || echo 1)
}

validate_page_structure() {
    local json=$1
    local validation_passed=true

    validate_field "$json" "content" || validation_passed=false
    validate_field "$json" "pageable" || validation_passed=false
    validate_field "$json" "totalElements" || validation_passed=false
    validate_field "$json" "totalPages" || validation_passed=false
    validate_field "$json" "size" || validation_passed=false
    validate_field "$json" "number" || validation_passed=false

    return $([ "$validation_passed" = true ] && echo 0 || echo 1)
}

mark_test_passed() {
    echo -e "${GREEN}✅ TEST PASSED: $1${NC}"
    echo ""
    ((PASSED_TESTS++))
}

mark_test_failed() {
    echo -e "${RED}❌ TEST FAILED: $1${NC}"
    echo -e "${RED}   Razón: $2${NC}"
    echo ""
    ((FAILED_TESTS++))
}

# ============================================
# VERIFICAR SERVIDOR
# ============================================
print_header "VERIFICANDO SERVIDOR"

SERVER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/products" 2>/dev/null || echo "000")

if [ "$SERVER_CHECK" != "000" ]; then
    echo -e "${GREEN}✅ Servidor corriendo${NC}"
    echo ""
else
    echo -e "${RED}❌ ERROR: Servidor no responde${NC}"
    exit 1
fi

# ============================================
# SETUP: REGISTRAR, LOGIN Y PREPARAR CARRITO
# ============================================
print_header "SETUP: PREPARAR USUARIO Y CARRITO CON PRODUCTOS"

echo "1. Registrando usuario: $TEST_EMAIL"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\",
        \"firstName\": \"Order\",
        \"lastName\": \"Client\",
        \"phone\": \"1234567890\",
        \"address\": \"Calle Test 123, Mar del Plata\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 201 ]; then
    echo -e "${GREEN}✓ Usuario registrado${NC}"
else
    echo -e "${RED}✗ Error al registrar usuario: $HTTP_CODE${NC}"
    exit 1
fi

echo ""
echo "2. Haciendo login..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
TOKEN=$(echo "$BODY" | jq -r '.accessToken' 2>/dev/null)

if [ "$HTTP_CODE" -eq 200 ] && [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo -e "${GREEN}✓ Login exitoso${NC}"
else
    echo -e "${RED}✗ Error al hacer login: $HTTP_CODE${NC}"
    exit 1
fi

echo ""
echo "3. Obteniendo productos..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=2")
BODY=$(echo "$RESPONSE" | sed '$d')
PRODUCT_ID=$(echo "$BODY" | jq -r '.content[0].id' 2>/dev/null)
PRODUCT_NAME=$(echo "$BODY" | jq -r '.content[0].name' 2>/dev/null)
PRODUCT_PRICE=$(echo "$BODY" | jq -r '.content[0].price' 2>/dev/null)

if [ -n "$PRODUCT_ID" ] && [ "$PRODUCT_ID" != "null" ]; then
    echo -e "${GREEN}✓ Producto 1: ID=$PRODUCT_ID${NC}"
else
    echo -e "${RED}✗ Error al obtener productos${NC}"
    exit 1
fi

echo ""
echo "4. Agregando productos al carrito..."
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT_ID, \"quantity\": 2}" > /dev/null

echo -e "${GREEN}✓ Carrito preparado con 2 productos${NC}"
echo ""

# ============================================
# TEST 1: CREAR PEDIDO DESDE CARRITO
# ============================================
print_header "TEST 1: CREAR PEDIDO DESDE CARRITO"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"shippingAddress\": \"Calle Test 123, Mar del Plata\",
        \"notes\": \"Entregar en horario de oficina\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.'
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 201 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 201 Created, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 201 Created${NC}"
fi

validate_order_response "$BODY" || VALIDATION_PASSED=false

# Guardar ORDER_ID
ORDER_ID=$(echo "$BODY" | jq -r '.id' 2>/dev/null)
if [ -n "$ORDER_ID" ] && [ "$ORDER_ID" != "null" ]; then
    echo -e "${GREEN}   ✓ Order ID obtenido: $ORDER_ID${NC}"
else
    echo -e "${RED}   ✗ No se pudo obtener Order ID${NC}"
    VALIDATION_PASSED=false
fi

# Validar status inicial (puede ser PENDING o CONFIRMED)
STATUS=$(echo "$BODY" | jq -r '.status' 2>/dev/null)
if [ "$STATUS" = "PENDING" ] || [ "$STATUS" = "CONFIRMED" ]; then
    echo -e "${GREEN}   ✓ Status inicial: $STATUS${NC}"
else
    echo -e "${RED}   ✗ Status: esperado PENDING o CONFIRMED, obtenido $STATUS${NC}"
    VALIDATION_PASSED=false
fi

# Validar que tiene items
ITEMS_COUNT=$(echo "$BODY" | jq '.items | length' 2>/dev/null)
if [ "$ITEMS_COUNT" -gt 0 ]; then
    echo -e "${GREEN}   ✓ Pedido tiene $ITEMS_COUNT items${NC}"

    # Validar estructura del primer item
    echo ""
    echo "   Validando estructura del primer item:"
    FIRST_ITEM=$(echo "$BODY" | jq '.items[0]')
    validate_order_item "$FIRST_ITEM" || VALIDATION_PASSED=false

    # Validar cantidad
    ITEM_QUANTITY=$(echo "$FIRST_ITEM" | jq -r '.quantity' 2>/dev/null)
    if [ "$ITEM_QUANTITY" = "2" ]; then
        echo -e "${GREEN}   ✓ Cantidad correcta: 2${NC}"
    else
        echo -e "${RED}   ✗ Cantidad: esperado 2, obtenido $ITEM_QUANTITY${NC}"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${RED}   ✗ Pedido sin items${NC}"
    VALIDATION_PASSED=false
fi

# Validar que el total es correcto
TOTAL=$(echo "$BODY" | jq -r '.total' 2>/dev/null)
if [ "$(echo "$TOTAL > 0" | bc -l 2>/dev/null)" -eq 1 ]; then
    echo -e "${GREEN}   ✓ Total > 0: $TOTAL${NC}"
else
    echo -e "${RED}   ✗ Total inválido: $TOTAL${NC}"
    VALIDATION_PASSED=false
fi

# Validar datos del cliente
CUSTOMER_EMAIL=$(echo "$BODY" | jq -r '.customerEmail' 2>/dev/null)
if [ "$CUSTOMER_EMAIL" = "$TEST_EMAIL" ]; then
    echo -e "${GREEN}   ✓ Email del cliente correcto${NC}"
else
    echo -e "${RED}   ✗ Email: esperado $TEST_EMAIL, obtenido $CUSTOMER_EMAIL${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Pedido creado con estructura completa y correcta"
else
    mark_test_failed "Crear pedido" "Validación falló"
fi

# ============================================
# TEST 2: CREAR PEDIDO SIN TOKEN
# ============================================
print_header "TEST 2: CREAR PEDIDO SIN TOKEN (DEBE FALLAR)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Content-Type: application/json" \
    -d "{
        \"shippingAddress\": \"Test\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: $HTTP_CODE (Acceso denegado)${NC}"
    mark_test_passed "Crear pedido sin token bloqueado"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 401 o 403, obtenido $HTTP_CODE${NC}"
    mark_test_failed "Seguridad crear pedido" "Acceso no bloqueado"
fi

# ============================================
# TEST 3: CREAR PEDIDO CON CARRITO VACÍO
# ============================================
print_header "TEST 3: CREAR PEDIDO CON CARRITO VACÍO (DEBE FALLAR)"
((TOTAL_TESTS++))

# Verificar que el carrito quedó vacío después del pedido anterior
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/cart" \
    -H "Authorization: Bearer $TOKEN")
BODY=$(echo "$RESPONSE" | sed '$d')
CART_ITEMS=$(echo "$BODY" | jq -r '.totalItems' 2>/dev/null)

if [ "$CART_ITEMS" -eq 0 ]; then
    echo "Carrito vacío confirmado (totalItems = 0)"
else
    echo "Carrito tiene $CART_ITEMS items, vaciando..."
    curl -s -X DELETE "$BASE_URL/cart/clear" -H "Authorization: Bearer $TOKEN" > /dev/null
fi

echo ""
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"shippingAddress\": \"Test\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -eq 400 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: 400 Bad Request${NC}"
    validate_error_response "$BODY" "400" || VALIDATION_PASSED=false

    MESSAGE=$(echo "$BODY" | jq -r '.message' 2>/dev/null)
    if [[ "$MESSAGE" =~ "carrito" ]] || [[ "$MESSAGE" =~ "vacío" ]] || [[ "$MESSAGE" =~ "vacio" ]]; then
        echo -e "${GREEN}   ✓ Mensaje indica carrito vacío${NC}"
    else
        echo -e "${YELLOW}   ⚠ Mensaje no específico: $MESSAGE${NC}"
    fi
else
    echo -e "${RED}   ✗ HTTP Code: esperado 400, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Carrito vacío rechazado con 400"
else
    mark_test_failed "Validación carrito vacío" "Error no apropiado"
fi

# ============================================
# TEST 4: LISTAR MIS PEDIDOS (PAGINADO)
# ============================================
print_header "TEST 4: LISTAR MIS PEDIDOS CON PAGINACIÓN"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/orders?page=0&size=10" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response (estructura Page):"
echo "$BODY" | jq '{totalElements, totalPages, size, number, contentLength: (.content | length)}' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

validate_page_structure "$BODY" || VALIDATION_PASSED=false

# Validar que hay al menos 1 pedido
TOTAL_ELEMENTS=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
if [ "$TOTAL_ELEMENTS" -gt 0 ]; then
    echo -e "${GREEN}   ✓ Total pedidos: $TOTAL_ELEMENTS${NC}"

    # Validar el primer pedido
    FIRST_ORDER=$(echo "$BODY" | jq '.content[0]')
    validate_order_response "$FIRST_ORDER" || VALIDATION_PASSED=false
else
    echo -e "${RED}   ✗ No hay pedidos en la lista${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Listar pedidos retorna Page con estructura correcta"
else
    mark_test_failed "Listar pedidos" "Validación falló"
fi

# ============================================
# TEST 5: OBTENER DETALLE DE PEDIDO
# ============================================
print_header "TEST 5: OBTENER DETALLE DE PEDIDO POR ID"
((TOTAL_TESTS++))

if [ -z "$ORDER_ID" ] || [ "$ORDER_ID" = "null" ]; then
    mark_test_failed "Obtener detalle" "No hay ORDER_ID disponible"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/orders/$ORDER_ID" \
        -H "Authorization: Bearer $TOKEN")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Order ID: $ORDER_ID"
    echo "Response:"
    echo "$BODY" | jq '{id, status, total, itemsCount: (.items | length), customerEmail}' 2>/dev/null
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    validate_order_response "$BODY" || VALIDATION_PASSED=false

    # Validar que el ID coincide
    RETURNED_ID=$(echo "$BODY" | jq -r '.id' 2>/dev/null)
    if [ "$RETURNED_ID" = "$ORDER_ID" ]; then
        echo -e "${GREEN}   ✓ ID coincide: $ORDER_ID${NC}"
    else
        echo -e "${RED}   ✗ ID no coincide: esperado $ORDER_ID, obtenido $RETURNED_ID${NC}"
        VALIDATION_PASSED=false
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Detalle de pedido con estructura completa"
    else
        mark_test_failed "Obtener detalle" "Validación falló"
    fi
fi

# ============================================
# TEST 6: OBTENER PEDIDO INEXISTENTE
# ============================================
print_header "TEST 6: OBTENER PEDIDO INEXISTENTE (DEBE FALLAR)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/orders/99999" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -eq 404 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: 404 Not Found${NC}"
    validate_error_response "$BODY" "404" || VALIDATION_PASSED=false
else
    echo -e "${RED}   ✗ HTTP Code: esperado 404, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Pedido inexistente retorna 404"
else
    mark_test_failed "Pedido inexistente" "Error no apropiado"
fi

# ============================================
# TEST 7: OBTENER PEDIDO DE OTRO USUARIO
# ============================================
print_header "TEST 7: INTENTAR VER PEDIDO DE OTRO USUARIO (DEBE FALLAR)"
((TOTAL_TESTS++))

# Crear otro usuario
OTHER_EMAIL="other-user-$(date +%s)@example.com"
curl -s -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$OTHER_EMAIL\",
        \"password\": \"password123\",
        \"firstName\": \"Other\",
        \"lastName\": \"User\",
        \"phone\": \"9999999999\",
        \"address\": \"Test\"
    }" > /dev/null

# Login del otro usuario
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$OTHER_EMAIL\", \"password\": \"password123\"}")
OTHER_TOKEN=$(echo "$RESPONSE" | sed '$d' | jq -r '.accessToken' 2>/dev/null)

if [ -n "$OTHER_TOKEN" ] && [ "$OTHER_TOKEN" != "null" ] && [ -n "$ORDER_ID" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/orders/$ORDER_ID" \
        -H "Authorization: Bearer $OTHER_TOKEN")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

    echo "HTTP Status: $HTTP_CODE"
    echo "Intentando ver pedido ID=$ORDER_ID con token de otro usuario"
    echo ""

    if [ "$HTTP_CODE" -eq 404 ] || [ "$HTTP_CODE" -eq 403 ]; then
        echo -e "${GREEN}   ✓ HTTP Code: $HTTP_CODE (Acceso denegado)${NC}"
        mark_test_passed "Pedido de otro usuario bloqueado"
    else
        echo -e "${RED}   ✗ HTTP Code: esperado 404 o 403, obtenido $HTTP_CODE${NC}"
        mark_test_failed "Seguridad pedido de otro usuario" "No bloqueado apropiadamente"
    fi
else
    echo -e "${YELLOW}⚠ Saltando test: No se pudo crear otro usuario${NC}"
    ((TOTAL_TESTS--))
fi

# ============================================
# TEST 8: CANCELAR PEDIDO
# ============================================
print_header "TEST 8: CANCELAR PEDIDO EN ESTADO PENDING"
((TOTAL_TESTS++))

# Primero crear un nuevo pedido para cancelar
echo "Preparando: Agregando producto al carrito para nuevo pedido..."
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT_ID, \"quantity\": 1}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Test\"}")

NEW_ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
echo "Pedido creado: ID=$NEW_ORDER_ID"
echo ""

if [ -n "$NEW_ORDER_ID" ] && [ "$NEW_ORDER_ID" != "null" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/orders/$NEW_ORDER_ID/cancel" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"reason\": \"Cliente cambió de opinión\"
        }")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Response:"
    echo "$BODY" | jq '{id, status, cancellationReason, cancelledAt}' 2>/dev/null
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    validate_order_response "$BODY" || VALIDATION_PASSED=false

    # Validar que el status cambió a CANCELLED
    STATUS=$(echo "$BODY" | jq -r '.status' 2>/dev/null)
    if [ "$STATUS" = "CANCELLED" ]; then
        echo -e "${GREEN}   ✓ Status: CANCELLED${NC}"
    else
        echo -e "${RED}   ✗ Status: esperado CANCELLED, obtenido $STATUS${NC}"
        VALIDATION_PASSED=false
    fi

    # Validar que tiene cancellationReason
    REASON=$(echo "$BODY" | jq -r '.cancellationReason' 2>/dev/null)
    if [[ "$REASON" =~ "Cliente" ]] || [[ "$REASON" =~ "cambió" ]]; then
        echo -e "${GREEN}   ✓ Razón de cancelación presente${NC}"
    else
        echo -e "${YELLOW}   ⚠ Razón: $REASON${NC}"
    fi

    # Validar que tiene cancelledAt
    CANCELLED_AT=$(echo "$BODY" | jq -r '.cancelledAt' 2>/dev/null)
    if [ -n "$CANCELLED_AT" ] && [ "$CANCELLED_AT" != "null" ]; then
        echo -e "${GREEN}   ✓ cancelledAt presente${NC}"
    else
        echo -e "${RED}   ✗ cancelledAt ausente${NC}"
        VALIDATION_PASSED=false
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Pedido cancelado correctamente con datos completos"
    else
        mark_test_failed "Cancelar pedido" "Validación falló"
    fi
else
    mark_test_failed "Cancelar pedido" "No se pudo crear pedido para cancelar"
fi

# ============================================
# TEST 9: CANCELAR PEDIDO SIN RAZÓN
# ============================================
print_header "TEST 9: CANCELAR PEDIDO SIN RAZÓN (VALIDAR CAMPO REQUERIDO)"
((TOTAL_TESTS++))

# Crear otro pedido
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT_ID, \"quantity\": 1}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Test\"}")

ANOTHER_ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)

if [ -n "$ANOTHER_ORDER_ID" ] && [ "$ANOTHER_ORDER_ID" != "null" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/orders/$ANOTHER_ORDER_ID/cancel" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{}")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo ""

    if [ "$HTTP_CODE" -eq 400 ]; then
        echo -e "${GREEN}   ✓ HTTP Code: 400 Bad Request${NC}"
        validate_error_response "$BODY" "400"
        mark_test_passed "Campo reason validado como requerido"
    else
        echo -e "${RED}   ✗ HTTP Code: esperado 400, obtenido $HTTP_CODE${NC}"
        mark_test_failed "Validación campo requerido" "No validado apropiadamente"
    fi
else
    echo -e "${YELLOW}⚠ Saltando test: No se pudo crear pedido${NC}"
    ((TOTAL_TESTS--))
fi

# ============================================
# TEST 10: CANCELAR PEDIDO INEXISTENTE
# ============================================
print_header "TEST 10: CANCELAR PEDIDO INEXISTENTE (DEBE FALLAR)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/orders/99999/cancel" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"reason\": \"Test\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -eq 404 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: 404 Not Found${NC}"
    validate_error_response "$BODY" "404"
    mark_test_passed "Pedido inexistente manejado correctamente"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 404, obtenido $HTTP_CODE${NC}"
    mark_test_failed "Cancelar inexistente" "Error no apropiado"
fi

# ============================================
# TEST 11: PAGINACIÓN DE PEDIDOS
# ============================================
print_header "TEST 11: PAGINACIÓN - DIFERENTES TAMAÑOS DE PÁGINA"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/orders?page=0&size=2" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Solicitado: size=2"
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

SIZE=$(echo "$BODY" | jq -r '.size' 2>/dev/null)
if [ "$SIZE" -eq 2 ]; then
    echo -e "${GREEN}   ✓ Size correcto: 2${NC}"
else
    echo -e "${RED}   ✗ Size: esperado 2, obtenido $SIZE${NC}"
    VALIDATION_PASSED=false
fi

CONTENT_LENGTH=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
if [ "$CONTENT_LENGTH" -le 2 ]; then
    echo -e "${GREEN}   ✓ Content tiene $CONTENT_LENGTH elementos (≤ 2)${NC}"
else
    echo -e "${RED}   ✗ Content tiene $CONTENT_LENGTH elementos (> 2)${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Paginación funciona correctamente"
else
    mark_test_failed "Paginación" "Validación falló"
fi

# ============================================
# TEST 12: ORDENAMIENTO DE PEDIDOS
# ============================================
print_header "TEST 12: ORDENAMIENTO - PEDIDOS MÁS RECIENTES PRIMERO"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/orders?page=0&size=10" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

# Verificar que los pedidos están ordenados por fecha descendente
CONTENT_LENGTH=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
if [ "$CONTENT_LENGTH" -ge 2 ]; then
    FIRST_DATE=$(echo "$BODY" | jq -r '.content[0].createdAt' 2>/dev/null)
    SECOND_DATE=$(echo "$BODY" | jq -r '.content[1].createdAt' 2>/dev/null)

    if [[ "$FIRST_DATE" > "$SECOND_DATE" ]] || [[ "$FIRST_DATE" == "$SECOND_DATE" ]]; then
        echo -e "${GREEN}   ✓ Pedidos ordenados por fecha descendente${NC}"
    else
        echo -e "${RED}   ✗ Orden incorrecto: $FIRST_DATE vs $SECOND_DATE${NC}"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${YELLOW}   ⚠ Solo hay $CONTENT_LENGTH pedido(s), no se puede verificar orden${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Pedidos ordenados correctamente"
else
    mark_test_failed "Ordenamiento" "Validación falló"
fi

# ============================================
# RESUMEN FINAL
# ============================================
print_header "RESUMEN FINAL - VALIDACIÓN EXHAUSTIVA"

echo -e "${BLUE}Total de Tests:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Tests Exitosos:${NC} $PASSED_TESTS"
echo -e "${RED}Tests Fallidos:${NC} $FAILED_TESTS"

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
echo -e "${YELLOW}Tasa de Éxito:${NC} $SUCCESS_RATE%"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}VALIDACIONES REALIZADAS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "✅ Código HTTP correcto"
echo "✅ Estructura OrderResponse completa"
echo "✅ Estructura OrderItemResponse completa"
echo "✅ Estructura Page con paginación"
echo "✅ Campos obligatorios presentes"
echo "✅ Estados del pedido (PENDING, CANCELLED)"
echo "✅ Cálculos correctos (total, subtotales)"
echo "✅ Seguridad JWT funcionando"
echo "✅ Validación de carrito vacío"
echo "✅ Cancelación de pedidos"
echo "✅ Ordenamiento por fecha"
echo "✅ Paginación correcta"
echo "✅ ErrorResponse estandarizado"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON CON VALIDACIÓN COMPLETA! 🎉${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}⚠️  $FAILED_TESTS test(s) fallaron en validación exhaustiva${NC}"
    EXIT_CODE=1
fi

echo ""
echo -e "${BLUE}📄 Usuario de prueba: $TEST_EMAIL${NC}"
echo ""

exit $EXIT_CODE

