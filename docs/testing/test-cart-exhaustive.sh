#!/bin/bash

# ============================================
# TEST EXHAUSTIVO - MÓDULO CART
# Validación completa de JSON + Códigos HTTP + Seguridad
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
TEST_EMAIL="cart-test-$(date +%s)@example.com"
TEST_PASSWORD="password123"
TOKEN=""
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

validate_cart_response() {
    local json=$1
    local validation_passed=true

    validate_field "$json" "id" || validation_passed=false
    validate_field "$json" "userId" || validation_passed=false
    validate_field "$json" "items" || validation_passed=false
    validate_field "$json" "totalItems" || validation_passed=false
    validate_field "$json" "totalAmount" || validation_passed=false
    validate_field "$json" "createdAt" || validation_passed=false
    validate_field "$json" "updatedAt" || validation_passed=false

    return $([ "$validation_passed" = true ] && echo 0 || echo 1)
}

validate_cart_item() {
    local json=$1
    local validation_passed=true

    validate_field "$json" "id" || validation_passed=false
    validate_field "$json" "productId" || validation_passed=false
    validate_field "$json" "productName" || validation_passed=false
    validate_field "$json" "quantity" || validation_passed=false
    validate_field "$json" "unitPrice" || validation_passed=false
    validate_field "$json" "subtotal" || validation_passed=false
    validate_field "$json" "imageUrl" || validation_passed=false
    validate_field "$json" "addedAt" || validation_passed=false
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
# SETUP: REGISTRAR Y HACER LOGIN
# ============================================
print_header "SETUP: CREAR USUARIO DE PRUEBA"

echo "Registrando usuario: $TEST_EMAIL"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\",
        \"firstName\": \"Cart\",
        \"lastName\": \"Test\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 201 ]; then
    echo -e "${GREEN}✓ Usuario registrado${NC}"
else
    echo -e "${RED}✗ Error al registrar usuario: $HTTP_CODE${NC}"
    exit 1
fi

echo ""
echo "Haciendo login..."
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
    echo -e "${GREEN}✓ Login exitoso, token obtenido${NC}"
else
    echo -e "${RED}✗ Error al hacer login: $HTTP_CODE${NC}"
    exit 1
fi

echo ""
echo "Obteniendo producto de prueba..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=1")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
PRODUCT_ID=$(echo "$BODY" | jq -r '.content[0].id' 2>/dev/null)
PRODUCT_NAME=$(echo "$BODY" | jq -r '.content[0].name' 2>/dev/null)
PRODUCT_PRICE=$(echo "$BODY" | jq -r '.content[0].price' 2>/dev/null)

if [ -n "$PRODUCT_ID" ] && [ "$PRODUCT_ID" != "null" ]; then
    echo -e "${GREEN}✓ Producto obtenido: ID=$PRODUCT_ID, Name='$PRODUCT_NAME', Price=$PRODUCT_PRICE${NC}"
else
    echo -e "${RED}✗ Error al obtener producto${NC}"
    exit 1
fi

echo ""

# ============================================
# TEST 1: OBTENER CARRITO VACÍO INICIAL
# ============================================
print_header "TEST 1: OBTENER CARRITO VACÍO INICIAL"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/cart" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.'
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

validate_cart_response "$BODY" || VALIDATION_PASSED=false

# Validar que esté vacío
TOTAL_ITEMS=$(echo "$BODY" | jq -r '.totalItems' 2>/dev/null)
ITEMS_COUNT=$(echo "$BODY" | jq '.items | length' 2>/dev/null)

if [ "$TOTAL_ITEMS" -eq 0 ]; then
    echo -e "${GREEN}   ✓ totalItems = 0 (carrito vacío)${NC}"
else
    echo -e "${RED}   ✗ totalItems: esperado 0, obtenido $TOTAL_ITEMS${NC}"
    VALIDATION_PASSED=false
fi

if [ "$ITEMS_COUNT" -eq 0 ]; then
    echo -e "${GREEN}   ✓ items array vacío${NC}"
else
    echo -e "${RED}   ✗ items: esperado array vacío, tiene $ITEMS_COUNT elementos${NC}"
    VALIDATION_PASSED=false
fi

TOTAL_AMOUNT=$(echo "$BODY" | jq -r '.totalAmount' 2>/dev/null)
# Convertir a número y verificar que sea 0
if [ "$(echo "$TOTAL_AMOUNT" | awk '{print ($1 == 0)}')" -eq 1 ]; then
    echo -e "${GREEN}   ✓ totalAmount = 0${NC}"
else
    echo -e "${RED}   ✗ totalAmount: esperado 0, obtenido $TOTAL_AMOUNT${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Carrito vacío retorna estructura correcta"
else
    mark_test_failed "Carrito vacío" "Validación falló"
fi

# ============================================
# TEST 2: ACCESO SIN TOKEN - VALIDAR 401/403
# ============================================
print_header "TEST 2: ACCESO AL CARRITO SIN TOKEN"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/cart")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: $HTTP_CODE (Acceso denegado)${NC}"
    mark_test_passed "Acceso sin token bloqueado correctamente"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 401 o 403, obtenido $HTTP_CODE${NC}"
    mark_test_failed "Seguridad sin token" "Acceso no bloqueado"
fi

# ============================================
# TEST 3: AGREGAR PRODUCTO AL CARRITO
# ============================================
print_header "TEST 3: AGREGAR PRODUCTO AL CARRITO"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"productId\": $PRODUCT_ID,
        \"quantity\": 2
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Request: productId=$PRODUCT_ID, quantity=2"
echo "Response:"
echo "$BODY" | jq '.'
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

validate_cart_response "$BODY" || VALIDATION_PASSED=false

# Validar que ahora tiene items
TOTAL_ITEMS=$(echo "$BODY" | jq -r '.totalItems' 2>/dev/null)
if [ "$TOTAL_ITEMS" -eq 2 ]; then
    echo -e "${GREEN}   ✓ totalItems = 2${NC}"
else
    echo -e "${RED}   ✗ totalItems: esperado 2, obtenido $TOTAL_ITEMS${NC}"
    VALIDATION_PASSED=false
fi

ITEMS_COUNT=$(echo "$BODY" | jq '.items | length' 2>/dev/null)
if [ "$ITEMS_COUNT" -eq 1 ]; then
    echo -e "${GREEN}   ✓ items tiene 1 producto${NC}"

    # Validar el item agregado
    echo ""
    echo "   Validando estructura del item:"
    FIRST_ITEM=$(echo "$BODY" | jq '.items[0]')
    validate_cart_item "$FIRST_ITEM" || VALIDATION_PASSED=false

    # Validar datos específicos
    ITEM_PRODUCT_ID=$(echo "$FIRST_ITEM" | jq -r '.productId' 2>/dev/null)
    if [ "$ITEM_PRODUCT_ID" = "$PRODUCT_ID" ]; then
        echo -e "${GREEN}   ✓ productId correcto: $PRODUCT_ID${NC}"
    else
        echo -e "${RED}   ✗ productId: esperado $PRODUCT_ID, obtenido $ITEM_PRODUCT_ID${NC}"
        VALIDATION_PASSED=false
    fi

    ITEM_QUANTITY=$(echo "$FIRST_ITEM" | jq -r '.quantity' 2>/dev/null)
    if [ "$ITEM_QUANTITY" = "2" ]; then
        echo -e "${GREEN}   ✓ quantity = 2${NC}"
    else
        echo -e "${RED}   ✗ quantity: esperado 2, obtenido $ITEM_QUANTITY${NC}"
        VALIDATION_PASSED=false
    fi

    # Validar cálculo de subtotal
    UNIT_PRICE=$(echo "$FIRST_ITEM" | jq -r '.unitPrice' 2>/dev/null)
    SUBTOTAL=$(echo "$FIRST_ITEM" | jq -r '.subtotal' 2>/dev/null)
    EXPECTED_SUBTOTAL=$(echo "$UNIT_PRICE * 2" | bc 2>/dev/null)

    if [ "$(echo "$SUBTOTAL == $EXPECTED_SUBTOTAL" | bc 2>/dev/null)" -eq 1 ]; then
        echo -e "${GREEN}   ✓ subtotal calculado correctamente: $SUBTOTAL${NC}"
    else
        echo -e "${RED}   ✗ subtotal: esperado $EXPECTED_SUBTOTAL, obtenido $SUBTOTAL${NC}"
        VALIDATION_PASSED=false
    fi

else
    echo -e "${RED}   ✗ items: esperado 1 elemento, obtenido $ITEMS_COUNT${NC}"
    VALIDATION_PASSED=false
fi

# Validar totalAmount
TOTAL_AMOUNT=$(echo "$BODY" | jq -r '.totalAmount' 2>/dev/null)
if [ "$(echo "$TOTAL_AMOUNT > 0" | bc -l 2>/dev/null)" -eq 1 ]; then
    echo -e "${GREEN}   ✓ totalAmount > 0: $TOTAL_AMOUNT${NC}"
else
    echo -e "${RED}   ✗ totalAmount debería ser > 0: $TOTAL_AMOUNT${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Producto agregado correctamente con estructura completa"
else
    mark_test_failed "Agregar producto" "Validación falló"
fi

# ============================================
# TEST 4: AGREGAR MISMO PRODUCTO (DEBE ACTUALIZAR CANTIDAD)
# ============================================
print_header "TEST 4: AGREGAR MISMO PRODUCTO (ACTUALIZAR CANTIDAD)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"productId\": $PRODUCT_ID,
        \"quantity\": 3
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Request: productId=$PRODUCT_ID, quantity=3 (agregar más)"
echo "Total items esperado: 2 + 3 = 5"
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

# Validar que la cantidad se actualizó
TOTAL_ITEMS=$(echo "$BODY" | jq -r '.totalItems' 2>/dev/null)
if [ "$TOTAL_ITEMS" -eq 5 ]; then
    echo -e "${GREEN}   ✓ totalItems = 5 (2 + 3)${NC}"
else
    echo -e "${RED}   ✗ totalItems: esperado 5, obtenido $TOTAL_ITEMS${NC}"
    VALIDATION_PASSED=false
fi

# Verificar que sigue siendo 1 producto (no duplicado)
ITEMS_COUNT=$(echo "$BODY" | jq '.items | length' 2>/dev/null)
if [ "$ITEMS_COUNT" -eq 1 ]; then
    echo -e "${GREEN}   ✓ Sigue siendo 1 producto (no duplicado)${NC}"

    ITEM_QUANTITY=$(echo "$BODY" | jq -r '.items[0].quantity' 2>/dev/null)
    if [ "$ITEM_QUANTITY" = "5" ]; then
        echo -e "${GREEN}   ✓ Cantidad actualizada a 5${NC}"
    else
        echo -e "${RED}   ✗ Cantidad: esperado 5, obtenido $ITEM_QUANTITY${NC}"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${RED}   ✗ items: esperado 1, obtenido $ITEMS_COUNT (se duplicó el producto)${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Cantidad actualizada correctamente (no duplica producto)"
else
    mark_test_failed "Actualizar cantidad al agregar" "Validación falló"
fi

# ============================================
# TEST 5: AGREGAR PRODUCTO SIN TOKEN
# ============================================
print_header "TEST 5: AGREGAR PRODUCTO SIN TOKEN (DEBE FALLAR)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Content-Type: application/json" \
    -d "{
        \"productId\": $PRODUCT_ID,
        \"quantity\": 1
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: $HTTP_CODE (Acceso denegado)${NC}"
    mark_test_passed "Agregar sin token bloqueado"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 401 o 403, obtenido $HTTP_CODE${NC}"
    mark_test_failed "Seguridad agregar sin token" "Acceso no bloqueado"
fi

# ============================================
# TEST 6: AGREGAR PRODUCTO INEXISTENTE
# ============================================
print_header "TEST 6: AGREGAR PRODUCTO INEXISTENTE (DEBE FALLAR)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"productId\": 99999,
        \"quantity\": 1
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -eq 404 ] || [ "$HTTP_CODE" -eq 400 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: $HTTP_CODE (Error esperado)${NC}"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 404 o 400, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
fi

# Si retorna error, validar estructura
if [ "$HTTP_CODE" -ge 400 ] && [ "$HTTP_CODE" -lt 500 ]; then
    validate_error_response "$BODY" "$HTTP_CODE" || VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Producto inexistente rechazado con error apropiado"
else
    mark_test_failed "Producto inexistente" "Validación falló"
fi

# ============================================
# TEST 7: AGREGAR CON CANTIDAD INVÁLIDA (0 o negativa)
# ============================================
print_header "TEST 7: AGREGAR CON CANTIDAD 0 (DEBE FALLAR)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"productId\": $PRODUCT_ID,
        \"quantity\": 0
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null
echo ""

if [ "$HTTP_CODE" -eq 400 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: 400 Bad Request${NC}"
    validate_error_response "$BODY" "400"
    mark_test_passed "Cantidad 0 rechazada con 400"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 400, obtenido $HTTP_CODE${NC}"
    mark_test_failed "Validación cantidad 0" "No rechazado apropiadamente"
fi

# ============================================
# TEST 8: AGREGAR CON STOCK INSUFICIENTE
# ============================================
print_header "TEST 8: AGREGAR CON CANTIDAD MAYOR AL STOCK (DEBE FALLAR)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"productId\": $PRODUCT_ID,
        \"quantity\": 999999
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
    if [[ "$MESSAGE" =~ "stock" ]] || [[ "$MESSAGE" =~ "Stock" ]]; then
        echo -e "${GREEN}   ✓ Mensaje menciona stock${NC}"
    else
        echo -e "${YELLOW}   ⚠ Mensaje no menciona stock: $MESSAGE${NC}"
    fi
else
    echo -e "${RED}   ✗ HTTP Code: esperado 400, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Stock insuficiente rechazado con 400"
else
    mark_test_failed "Validación stock" "Error no apropiado"
fi

# ============================================
# TEST 9: ACTUALIZAR CANTIDAD DE PRODUCTO
# ============================================
print_header "TEST 9: ACTUALIZAR CANTIDAD DE PRODUCTO EN CARRITO"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/cart/items/$PRODUCT_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"quantity\": 3
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Request: Actualizar cantidad a 3"
echo "Response:"
echo "$BODY" | jq '.'
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

validate_cart_response "$BODY" || VALIDATION_PASSED=false

# Validar que la cantidad se actualizó
TOTAL_ITEMS=$(echo "$BODY" | jq -r '.totalItems' 2>/dev/null)
if [ "$TOTAL_ITEMS" -eq 3 ]; then
    echo -e "${GREEN}   ✓ totalItems = 3${NC}"
else
    echo -e "${RED}   ✗ totalItems: esperado 3, obtenido $TOTAL_ITEMS${NC}"
    VALIDATION_PASSED=false
fi

ITEM_QUANTITY=$(echo "$BODY" | jq -r '.items[0].quantity' 2>/dev/null)
if [ "$ITEM_QUANTITY" = "3" ]; then
    echo -e "${GREEN}   ✓ Cantidad del item actualizada a 3${NC}"
else
    echo -e "${RED}   ✗ Cantidad: esperado 3, obtenido $ITEM_QUANTITY${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Cantidad actualizada correctamente"
else
    mark_test_failed "Actualizar cantidad" "Validación falló"
fi

# ============================================
# TEST 10: ACTUALIZAR PRODUCTO QUE NO ESTÁ EN CARRITO
# ============================================
print_header "TEST 10: ACTUALIZAR PRODUCTO QUE NO ESTÁ EN CARRITO (DEBE FALLAR)"
((TOTAL_TESTS++))

# Buscar otro producto diferente
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=10")
OTHER_PRODUCT_ID=$(echo "$RESPONSE" | sed '$d' | jq -r '.content[] | select(.id != '$PRODUCT_ID') | .id' 2>/dev/null | head -1)

if [ -n "$OTHER_PRODUCT_ID" ] && [ "$OTHER_PRODUCT_ID" != "null" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/cart/items/$OTHER_PRODUCT_ID" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"quantity\": 1
        }")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Intentando actualizar producto ID=$OTHER_PRODUCT_ID (no está en carrito)"
    echo ""

    if [ "$HTTP_CODE" -eq 404 ] || [ "$HTTP_CODE" -eq 400 ]; then
        echo -e "${GREEN}   ✓ HTTP Code: $HTTP_CODE (Error esperado)${NC}"
        mark_test_passed "Producto no en carrito rechazado apropiadamente"
    else
        echo -e "${RED}   ✗ HTTP Code: esperado 404 o 400, obtenido $HTTP_CODE${NC}"
        mark_test_failed "Validación producto no en carrito" "Error no apropiado"
    fi
else
    echo -e "${YELLOW}⚠ Saltando test: No hay otro producto disponible${NC}"
    ((TOTAL_TESTS--))
fi

# ============================================
# TEST 11: ELIMINAR PRODUCTO DEL CARRITO
# ============================================
print_header "TEST 11: ELIMINAR PRODUCTO DEL CARRITO"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/cart/items/$PRODUCT_ID" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Request: Eliminar producto ID=$PRODUCT_ID"
echo "Response:"
echo "$BODY" | jq '.'
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

validate_cart_response "$BODY" || VALIDATION_PASSED=false

# Validar que el carrito está vacío
TOTAL_ITEMS=$(echo "$BODY" | jq -r '.totalItems' 2>/dev/null)
if [ "$TOTAL_ITEMS" -eq 0 ]; then
    echo -e "${GREEN}   ✓ totalItems = 0 (carrito vacío)${NC}"
else
    echo -e "${RED}   ✗ totalItems: esperado 0, obtenido $TOTAL_ITEMS${NC}"
    VALIDATION_PASSED=false
fi

ITEMS_COUNT=$(echo "$BODY" | jq '.items | length' 2>/dev/null)
if [ "$ITEMS_COUNT" -eq 0 ]; then
    echo -e "${GREEN}   ✓ items array vacío${NC}"
else
    echo -e "${RED}   ✗ items: esperado vacío, tiene $ITEMS_COUNT elementos${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Producto eliminado correctamente"
else
    mark_test_failed "Eliminar producto" "Validación falló"
fi

# ============================================
# TEST 12: ELIMINAR PRODUCTO QUE NO ESTÁ EN CARRITO
# ============================================
print_header "TEST 12: ELIMINAR PRODUCTO QUE NO ESTÁ EN CARRITO (DEBE FALLAR)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/cart/items/99999" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -eq 404 ] || [ "$HTTP_CODE" -eq 400 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: $HTTP_CODE (Error esperado)${NC}"
    mark_test_passed "Eliminar producto inexistente manejado correctamente"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 404 o 400, obtenido $HTTP_CODE${NC}"
    mark_test_failed "Eliminar inexistente" "Error no apropiado"
fi

# ============================================
# TEST 13: VACIAR CARRITO
# ============================================
print_header "TEST 13: VACIAR CARRITO COMPLETO"
((TOTAL_TESTS++))

# Primero agregar productos
echo "Preparando: Agregando productos al carrito..."
curl -s -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"productId\": $PRODUCT_ID, \"quantity\": 2}" > /dev/null
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/cart/clear" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY"
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

# Verificar que el carrito quedó vacío
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/cart" \
    -H "Authorization: Bearer $TOKEN")
BODY=$(echo "$RESPONSE" | sed '$d')
TOTAL_ITEMS=$(echo "$BODY" | jq -r '.totalItems' 2>/dev/null)

if [ "$TOTAL_ITEMS" -eq 0 ]; then
    echo -e "${GREEN}   ✓ Carrito vaciado correctamente (totalItems = 0)${NC}"
else
    echo -e "${RED}   ✗ Carrito NO vacío: totalItems = $TOTAL_ITEMS${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Carrito vaciado correctamente"
else
    mark_test_failed "Vaciar carrito" "Validación falló"
fi

# ============================================
# TEST 14: VALIDACIÓN DE CAMPOS REQUERIDOS
# ============================================
print_header "TEST 14: AGREGAR SIN PRODUCTID (DEBE FALLAR)"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"quantity\": 1
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -eq 400 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: 400 Bad Request${NC}"
    validate_error_response "$BODY" "400"
    mark_test_passed "Campo requerido validado"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 400, obtenido $HTTP_CODE${NC}"
    mark_test_failed "Validación campo requerido" "No validado apropiadamente"
fi

# ============================================
# TEST 15: MÚLTIPLES PRODUCTOS EN CARRITO
# ============================================
print_header "TEST 15: AGREGAR MÚLTIPLES PRODUCTOS DIFERENTES"
((TOTAL_TESTS++))

# Obtener varios productos
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=3")
BODY=$(echo "$RESPONSE" | sed '$d')
PRODUCTS=$(echo "$BODY" | jq -r '.content[].id' 2>/dev/null)

echo "Agregando múltiples productos al carrito..."
PRODUCT_COUNT=0
for pid in $PRODUCTS; do
    curl -s -X POST "$BASE_URL/cart/items" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"productId\": $pid, \"quantity\": 1}" > /dev/null
    ((PRODUCT_COUNT++))
    if [ $PRODUCT_COUNT -ge 3 ]; then break; fi
done
echo ""

# Obtener carrito y validar
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/cart" \
    -H "Authorization: Bearer $TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Carrito con múltiples productos:"
echo "$BODY" | jq '{totalItems, itemsCount: (.items | length), totalAmount}'
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

ITEMS_COUNT=$(echo "$BODY" | jq '.items | length' 2>/dev/null)
if [ "$ITEMS_COUNT" -ge 2 ]; then
    echo -e "${GREEN}   ✓ Carrito tiene $ITEMS_COUNT productos diferentes${NC}"
else
    echo -e "${RED}   ✗ items: esperado >= 2, obtenido $ITEMS_COUNT${NC}"
    VALIDATION_PASSED=false
fi

# Validar que no hay duplicados de productId
UNIQUE_IDS=$(echo "$BODY" | jq '[.items[].productId] | unique | length' 2>/dev/null)
if [ "$UNIQUE_IDS" -eq "$ITEMS_COUNT" ]; then
    echo -e "${GREEN}   ✓ No hay productos duplicados${NC}"
else
    echo -e "${RED}   ✗ Hay productos duplicados${NC}"
    VALIDATION_PASSED=false
fi

# Validar que totalAmount es la suma de subtotales
CALCULATED_TOTAL=$(echo "$BODY" | jq '[.items[].subtotal] | add' 2>/dev/null)
CART_TOTAL=$(echo "$BODY" | jq -r '.totalAmount' 2>/dev/null)

if [ "$(echo "$CALCULATED_TOTAL == $CART_TOTAL" | bc -l 2>/dev/null)" -eq 1 ]; then
    echo -e "${GREEN}   ✓ totalAmount calculado correctamente${NC}"
else
    echo -e "${YELLOW}   ⚠ totalAmount: calculado=$CALCULATED_TOTAL, carrito=$CART_TOTAL${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Múltiples productos manejados correctamente"
else
    mark_test_failed "Múltiples productos" "Validación falló"
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
echo "✅ Estructura CartResponse completa"
echo "✅ Estructura CartItemResponse completa"
echo "✅ Campos obligatorios presentes"
echo "✅ Valores correctos (quantity, totalItems, etc.)"
echo "✅ Cálculos correctos (subtotal, totalAmount)"
echo "✅ Seguridad JWT funcionando"
echo "✅ Validaciones de negocio (stock, cantidad)"
echo "✅ ErrorResponse estandarizado"
echo "✅ Operaciones CRUD completas"
echo "✅ Múltiples productos sin duplicados"
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

