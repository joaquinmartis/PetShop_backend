#!/bin/bash

# ============================================
# TEST EXHAUSTIVO - MÓDULO ORDER (BACKOFFICE)
# Validación completa de JSON + Códigos HTTP + Flujo de estados
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
CLIENT_EMAIL="backoffice-client-$(date +%s)@example.com"
WAREHOUSE_EMAIL="warehouse@test.com"
WAREHOUSE_PASSWORD="password123"
CLIENT_TOKEN=""
WAREHOUSE_TOKEN=""
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
    validate_field "$json" "items" || validation_passed=false
    validate_field "$json" "createdAt" || validation_passed=false
    validate_field "$json" "updatedAt" || validation_passed=false

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
# SETUP: PREPARAR USUARIOS Y PEDIDOS
# ============================================
print_header "SETUP: PREPARAR USUARIOS Y CREAR PEDIDO DE PRUEBA"

echo "1. Login usuario WAREHOUSE..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$WAREHOUSE_EMAIL\",
        \"password\": \"$WAREHOUSE_PASSWORD\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
WAREHOUSE_TOKEN=$(echo "$BODY" | jq -r '.accessToken' 2>/dev/null)

if [ "$HTTP_CODE" -eq 200 ] && [ -n "$WAREHOUSE_TOKEN" ] && [ "$WAREHOUSE_TOKEN" != "null" ]; then
    echo -e "${GREEN}✓ Login WAREHOUSE exitoso${NC}"
else
    echo -e "${YELLOW}⚠ Login WAREHOUSE falló (401), intentando crear usuario...${NC}"

    # Intentar crear el usuario warehouse
    curl -s -X POST "$BASE_URL/users/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$WAREHOUSE_EMAIL\",
            \"password\": \"$WAREHOUSE_PASSWORD\",
            \"firstName\": \"Warehouse\",
            \"lastName\": \"Manager\",
            \"phone\": \"9999999999\",
            \"address\": \"Depósito Central\"
        }" > /dev/null

    echo -e "${YELLOW}⚠ Usuario warehouse creado, pero necesita rol WAREHOUSE en la base de datos${NC}"
    echo -e "${YELLOW}⚠ Ejecuta este SQL:${NC}"
    echo -e "${YELLOW}   UPDATE user_management.users SET role_id = 2 WHERE email = 'warehouse@test.com';${NC}"
    echo ""
    echo -e "${RED}✗ No se puede continuar sin usuario WAREHOUSE${NC}"
    echo -e "${RED}✗ Usa el script create-warehouse-user.sql para crear el usuario${NC}"
    exit 1
fi

echo ""
echo "2. Creando usuario cliente..."
curl -s -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$CLIENT_EMAIL\",
        \"password\": \"password123\",
        \"firstName\": \"Cliente\",
        \"lastName\": \"Test\",
        \"phone\": \"1234567890\",
        \"address\": \"Calle Test 123\"
    }" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$CLIENT_EMAIL\", \"password\": \"password123\"}")

CLIENT_TOKEN=$(echo "$RESPONSE" | sed '$d' | jq -r '.accessToken' 2>/dev/null)
echo -e "${GREEN}✓ Cliente creado y autenticado${NC}"

echo ""
echo "3. Obteniendo producto..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=1")
BODY=$(echo "$RESPONSE" | sed '$d')
PRODUCT_ID=$(echo "$BODY" | jq -r '.content[0].id' 2>/dev/null)
echo -e "${GREEN}✓ Producto ID=$PRODUCT_ID${NC}"

echo ""
echo "4. Creando pedido de prueba..."
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT_ID, \"quantity\": 2}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Calle Test 123\"}")

ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
echo -e "${GREEN}✓ Pedido creado: ID=$ORDER_ID${NC}"
echo ""

# ============================================
# TEST 1: LISTAR TODOS LOS PEDIDOS (SIN FILTRO)
# ============================================
print_header "TEST 1: LISTAR TODOS LOS PEDIDOS"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders?page=0&size=10" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response (resumen):"
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

TOTAL_ELEMENTS=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
if [ "$TOTAL_ELEMENTS" -gt 0 ]; then
    echo -e "${GREEN}   ✓ Total pedidos: $TOTAL_ELEMENTS${NC}"

    FIRST_ORDER=$(echo "$BODY" | jq '.content[0]')
    validate_order_response "$FIRST_ORDER" || VALIDATION_PASSED=false
else
    echo -e "${RED}   ✗ No hay pedidos${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Listar todos los pedidos con estructura correcta"
else
    mark_test_failed "Listar pedidos" "Validación falló"
fi

# ============================================
# TEST 2: LISTAR PEDIDOS FILTRADO POR ESTADO
# ============================================
print_header "TEST 2: LISTAR PEDIDOS FILTRADO POR ESTADO (CONFIRMED)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders?status=CONFIRMED&page=0&size=10" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Filtro: status=CONFIRMED"
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

validate_page_structure "$BODY" || VALIDATION_PASSED=false

# Verificar que TODOS los pedidos tienen estado CONFIRMED
CONTENT_LENGTH=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
if [ "$CONTENT_LENGTH" -gt 0 ]; then
    WRONG_STATUS=0
    for i in $(seq 0 $(($CONTENT_LENGTH - 1))); do
        STATUS=$(echo "$BODY" | jq -r ".content[$i].status" 2>/dev/null)
        if [ "$STATUS" != "CONFIRMED" ]; then
            ((WRONG_STATUS++))
        fi
    done

    if [ "$WRONG_STATUS" -eq 0 ]; then
        echo -e "${GREEN}   ✓ TODOS los pedidos tienen status CONFIRMED${NC}"
    else
        echo -e "${RED}   ✗ $WRONG_STATUS pedidos con status diferente${NC}"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${YELLOW}   ⚠ No hay pedidos con estado CONFIRMED${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Filtro por estado funciona correctamente"
else
    mark_test_failed "Filtrar por estado" "Validación falló"
fi

# ============================================
# TEST 3: ACCESO SIN ROL WAREHOUSE
# ============================================
print_header "TEST 3: INTENTAR ACCEDER SIN ROL WAREHOUSE (DEBE FALLAR)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders" \
    -H "Authorization: Bearer $CLIENT_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo "HTTP Status: $HTTP_CODE"
echo "Intentando con token CLIENT (sin rol WAREHOUSE)"
echo ""

if [ "$HTTP_CODE" -eq 403 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: 403 Forbidden${NC}"
    mark_test_passed "Acceso sin rol WAREHOUSE bloqueado"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 403, obtenido $HTTP_CODE${NC}"
    mark_test_failed "Seguridad rol WAREHOUSE" "Acceso no bloqueado"
fi

# ============================================
# TEST 4: OBTENER DETALLE DE PEDIDO
# ============================================
print_header "TEST 4: OBTENER DETALLE DE PEDIDO"
((TOTAL_TESTS++))

if [ -z "$ORDER_ID" ] || [ "$ORDER_ID" = "null" ]; then
    mark_test_failed "Obtener detalle" "No hay ORDER_ID"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders/$ORDER_ID" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Order ID: $ORDER_ID"
    echo "Response:"
    echo "$BODY" | jq '{id, status, total, customerEmail}' 2>/dev/null
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    validate_order_response "$BODY" || VALIDATION_PASSED=false

    RETURNED_ID=$(echo "$BODY" | jq -r '.id' 2>/dev/null)
    if [ "$RETURNED_ID" = "$ORDER_ID" ]; then
        echo -e "${GREEN}   ✓ ID coincide: $ORDER_ID${NC}"
    else
        echo -e "${RED}   ✗ ID no coincide${NC}"
        VALIDATION_PASSED=false
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Detalle de pedido completo"
    else
        mark_test_failed "Obtener detalle" "Validación falló"
    fi
fi

# ============================================
# TEST 5: OBTENER PEDIDO INEXISTENTE
# ============================================
print_header "TEST 5: OBTENER PEDIDO INEXISTENTE (DEBE FALLAR)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders/99999" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
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
# TEST 6: MARCAR COMO LISTO PARA ENVIAR
# ============================================
print_header "TEST 6: MARCAR PEDIDO COMO LISTO PARA ENVIAR"
((TOTAL_TESTS++))

if [ -z "$ORDER_ID" ]; then
    mark_test_failed "Ready to ship" "No hay ORDER_ID"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$ORDER_ID/ready-to-ship" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Response:"
    echo "$BODY" | jq '{id, status}' 2>/dev/null
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    validate_order_response "$BODY" || VALIDATION_PASSED=false

    STATUS=$(echo "$BODY" | jq -r '.status' 2>/dev/null)
    if [ "$STATUS" = "READY_TO_SHIP" ]; then
        echo -e "${GREEN}   ✓ Status cambió a READY_TO_SHIP${NC}"
    else
        echo -e "${RED}   ✗ Status: esperado READY_TO_SHIP, obtenido $STATUS${NC}"
        VALIDATION_PASSED=false
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Pedido marcado como listo para enviar"
    else
        mark_test_failed "Ready to ship" "Validación falló"
    fi
fi

# ============================================
# TEST 7: ACTUALIZAR MÉTODO DE ENVÍO
# ============================================
print_header "TEST 7: ACTUALIZAR MÉTODO DE ENVÍO"
((TOTAL_TESTS++))

if [ -z "$ORDER_ID" ]; then
    mark_test_failed "Actualizar shipping method" "No hay ORDER_ID"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$ORDER_ID/shipping-method" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"shippingMethod": "COURIER"}')

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Response:"
    echo "$BODY" | jq '{id, shippingMethod}' 2>/dev/null
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    validate_order_response "$BODY" || VALIDATION_PASSED=false

    SHIPPING_METHOD=$(echo "$BODY" | jq -r '.shippingMethod' 2>/dev/null)
    if [ "$SHIPPING_METHOD" = "COURIER" ]; then
        echo -e "${GREEN}   ✓ shippingMethod actualizado a COURIER${NC}"
    else
        echo -e "${RED}   ✗ shippingMethod: esperado COURIER, obtenido $SHIPPING_METHOD${NC}"
        VALIDATION_PASSED=false
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Método de envío actualizado correctamente"
    else
        mark_test_failed "Actualizar shipping method" "Validación falló"
    fi
fi

# ============================================
# TEST 8: MÉTODO DE ENVÍO INVÁLIDO
# ============================================
print_header "TEST 8: ACTUALIZAR CON MÉTODO DE ENVÍO INVÁLIDO (DEBE FALLAR)"
((TOTAL_TESTS++))

if [ -z "$ORDER_ID" ]; then
    mark_test_failed "Validar shipping method" "No hay ORDER_ID"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$ORDER_ID/shipping-method" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"shippingMethod": "INVALID_METHOD"}')

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo ""

    if [ "$HTTP_CODE" -eq 400 ]; then
        echo -e "${GREEN}   ✓ HTTP Code: 400 Bad Request${NC}"
        validate_error_response "$BODY" "400"
        mark_test_passed "Método inválido rechazado con 400"
    else
        echo -e "${RED}   ✗ HTTP Code: esperado 400, obtenido $HTTP_CODE${NC}"
        mark_test_failed "Validar shipping method" "Error no apropiado"
    fi
fi

# ============================================
# TEST 9: MARCAR COMO DESPACHADO
# ============================================
print_header "TEST 9: MARCAR PEDIDO COMO DESPACHADO"
((TOTAL_TESTS++))

if [ -z "$ORDER_ID" ]; then
    mark_test_failed "Ship order" "No hay ORDER_ID"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$ORDER_ID/ship" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Response:"
    echo "$BODY" | jq '{id, status}' 2>/dev/null
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    STATUS=$(echo "$BODY" | jq -r '.status' 2>/dev/null)
    if [ "$STATUS" = "SHIPPED" ]; then
        echo -e "${GREEN}   ✓ Status cambió a SHIPPED${NC}"
    else
        echo -e "${RED}   ✗ Status: esperado SHIPPED, obtenido $STATUS${NC}"
        VALIDATION_PASSED=false
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Pedido marcado como despachado"
    else
        mark_test_failed "Ship order" "Validación falló"
    fi
fi

# ============================================
# TEST 10: MARCAR COMO ENTREGADO
# ============================================
print_header "TEST 10: MARCAR PEDIDO COMO ENTREGADO"
((TOTAL_TESTS++))

if [ -z "$ORDER_ID" ]; then
    mark_test_failed "Deliver order" "No hay ORDER_ID"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$ORDER_ID/deliver" \
        -H "Authorization: Bearer $WAREHOUSE_TOKEN")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Response:"
    echo "$BODY" | jq '{id, status}' 2>/dev/null
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    STATUS=$(echo "$BODY" | jq -r '.status' 2>/dev/null)
    if [ "$STATUS" = "DELIVERED" ]; then
        echo -e "${GREEN}   ✓ Status cambió a DELIVERED${NC}"
    else
        echo -e "${RED}   ✗ Status: esperado DELIVERED, obtenido $STATUS${NC}"
        VALIDATION_PASSED=false
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Pedido marcado como entregado"
    else
        mark_test_failed "Deliver order" "Validación falló"
    fi
fi

# ============================================
# TEST 11: TRANSICIÓN DE ESTADO INVÁLIDA
# ============================================
print_header "TEST 11: TRANSICIÓN DE ESTADO INVÁLIDA (DEBE FALLAR)"
((TOTAL_TESTS++))

echo "Creando nuevo pedido para test de transición inválida..."
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT_ID, \"quantity\": 1}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Test\"}")

NEW_ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
echo "Nuevo pedido: ID=$NEW_ORDER_ID (status=CONFIRMED)"
echo ""

# Intentar marcar como SHIPPED sin pasar por READY_TO_SHIP
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$NEW_ORDER_ID/ship" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Intentando CONFIRMED → SHIPPED (debe fallar)"
echo ""

if [ "$HTTP_CODE" -eq 400 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: 400 Bad Request${NC}"
    validate_error_response "$BODY" "400"

    MESSAGE=$(echo "$BODY" | jq -r '.message' 2>/dev/null)
    if [[ "$MESSAGE" =~ "listo" ]] || [[ "$MESSAGE" =~ "READY_TO_SHIP" ]]; then
        echo -e "${GREEN}   ✓ Mensaje indica estado requerido${NC}"
    fi

    mark_test_passed "Transición inválida rechazada"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 400, obtenido $HTTP_CODE${NC}"
    mark_test_failed "Transición inválida" "Permitió transición incorrecta"
fi

# ============================================
# TEST 12: RECHAZAR PEDIDO
# ============================================
print_header "TEST 12: RECHAZAR PEDIDO"
((TOTAL_TESTS++))

echo "Creando nuevo pedido para rechazar..."
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT_ID, \"quantity\": 1}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Test\"}")

REJECT_ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
echo "Pedido creado: ID=$REJECT_ORDER_ID"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$REJECT_ORDER_ID/reject" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"reason": "Producto fuera de stock"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '{id, status, cancellationReason}' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

validate_order_response "$BODY" || VALIDATION_PASSED=false

STATUS=$(echo "$BODY" | jq -r '.status' 2>/dev/null)
if [ "$STATUS" = "CANCELLED" ]; then
    echo -e "${GREEN}   ✓ Status cambió a CANCELLED (pedido rechazado)${NC}"
else
    echo -e "${RED}   ✗ Status: esperado CANCELLED, obtenido $STATUS${NC}"
    VALIDATION_PASSED=false
fi

CANCELLATION_REASON=$(echo "$BODY" | jq -r '.cancellationReason' 2>/dev/null)
if [[ "$CANCELLATION_REASON" =~ "stock" ]]; then
    echo -e "${GREEN}   ✓ Razón de rechazo presente${NC}"
else
    echo -e "${YELLOW}   ⚠ Razón: $CANCELLATION_REASON${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Pedido rechazado correctamente"
else
    mark_test_failed "Rechazar pedido" "Validación falló"
fi

# ============================================
# TEST 13: RECHAZAR SIN RAZÓN
# ============================================
print_header "TEST 13: RECHAZAR PEDIDO SIN RAZÓN (DEBE FALLAR)"
((TOTAL_TESTS++))

echo "Creando pedido para test de validación..."
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT_ID, \"quantity\": 1}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Test\"}")

ANOTHER_ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$ANOTHER_ORDER_ID/reject" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -eq 400 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: 400 Bad Request${NC}"
    mark_test_passed "Campo reason validado como requerido"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 400, obtenido $HTTP_CODE${NC}"
    mark_test_failed "Validar reason" "No validado apropiadamente"
fi

# ============================================
# TEST 14: FLUJO COMPLETO DE ESTADOS
# ============================================
print_header "TEST 14: FLUJO COMPLETO DE ESTADOS (CONFIRMED → DELIVERED)"
((TOTAL_TESTS++))

echo "Creando pedido para flujo completo..."
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT_ID, \"quantity\": 1}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"shippingAddress\": \"Test\"}")

FLOW_ORDER_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.id' 2>/dev/null)
INITIAL_STATUS=$(echo "$RESPONSE" | sed '$d' | jq -r '.status' 2>/dev/null)
echo "Pedido: ID=$FLOW_ORDER_ID, Status inicial=$INITIAL_STATUS"
echo ""

VALIDATION_PASSED=true

# Estado 1: CONFIRMED → READY_TO_SHIP
echo "1. CONFIRMED → READY_TO_SHIP"
RESPONSE=$(curl -s -X PATCH "$BASE_URL/backoffice/orders/$FLOW_ORDER_ID/ready-to-ship" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")
STATUS=$(echo "$RESPONSE" | jq -r '.status' 2>/dev/null)
if [ "$STATUS" = "READY_TO_SHIP" ]; then
    echo -e "${GREEN}   ✓ READY_TO_SHIP${NC}"
else
    echo -e "${RED}   ✗ Error: $STATUS${NC}"
    VALIDATION_PASSED=false
fi

# Estado 2: READY_TO_SHIP → SHIPPED
echo "2. READY_TO_SHIP → SHIPPED"
RESPONSE=$(curl -s -X PATCH "$BASE_URL/backoffice/orders/$FLOW_ORDER_ID/ship" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")
STATUS=$(echo "$RESPONSE" | jq -r '.status' 2>/dev/null)
if [ "$STATUS" = "SHIPPED" ]; then
    echo -e "${GREEN}   ✓ SHIPPED${NC}"
else
    echo -e "${RED}   ✗ Error: $STATUS${NC}"
    VALIDATION_PASSED=false
fi

# Estado 3: SHIPPED → DELIVERED
echo "3. SHIPPED → DELIVERED"
RESPONSE=$(curl -s -X PATCH "$BASE_URL/backoffice/orders/$FLOW_ORDER_ID/deliver" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")
STATUS=$(echo "$RESPONSE" | jq -r '.status' 2>/dev/null)
if [ "$STATUS" = "DELIVERED" ]; then
    echo -e "${GREEN}   ✓ DELIVERED${NC}"
else
    echo -e "${RED}   ✗ Error: $STATUS${NC}"
    VALIDATION_PASSED=false
fi

echo ""
if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Flujo completo de estados exitoso"
else
    mark_test_failed "Flujo completo" "Alguna transición falló"
fi

# ============================================
# TEST 15: PAGINACIÓN
# ============================================
print_header "TEST 15: PAGINACIÓN CON DIFERENTES TAMAÑOS"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders?page=0&size=2" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")

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
echo "✅ Estructura Page con paginación"
echo "✅ Filtros por estado funcionando"
echo "✅ Transiciones de estado validadas"
echo "✅ Flujo completo: CONFIRMED → DELIVERED"
echo "✅ Seguridad rol WAREHOUSE"
echo "✅ Validación de campos requeridos"
echo "✅ Actualización de shipping method"
echo "✅ Rechazo de pedidos"
echo "✅ ErrorResponse estandarizado"
echo "✅ Paginación correcta"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON CON VALIDACIÓN COMPLETA! 🎉${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}⚠️  $FAILED_TESTS test(s) fallaron en validación exhaustiva${NC}"
    EXIT_CODE=1
fi

echo ""
echo -e "${BLUE}📄 Usuario WAREHOUSE: $WAREHOUSE_EMAIL${NC}"
echo ""

exit $EXIT_CODE

