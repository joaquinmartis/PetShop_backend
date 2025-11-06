#!/bin/bash

# ============================================
# TEST: VALIDACIONES DE CAMPOS COMPLETAS
# Valida todos los campos con valores inválidos
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

BASE_URL="http://localhost:8080/api"

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

mark_success() {
    echo -e "${GREEN}   ✅ $1${NC}"
    ((PASSED_TESTS++))
}

mark_failure() {
    echo -e "${RED}   ❌ $1${NC}"
    ((FAILED_TESTS++))
}

print_header "TEST: VALIDACIONES DE CAMPOS COMPLETAS"

# ============================================
# VALIDACIONES DE REGISTRO
# ============================================
print_header "1. VALIDACIONES DE REGISTRO"

# Test 1: Email sin @
((TOTAL_TESTS++))
echo "Test 1: Email sin @"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d '{"email":"invalidemail","password":"password123","firstName":"Test","lastName":"User","phone":"1234567890","address":"Test"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ]; then
    mark_success "Email sin @ rechazado correctamente"
else
    mark_failure "Email sin @ NO rechazado (HTTP $HTTP_CODE)"
fi

# Test 2: Password menor a 8 caracteres
((TOTAL_TESTS++))
echo "Test 2: Password < 8 caracteres"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"test$(date +%s)@test.com\",\"password\":\"pass123\",\"firstName\":\"Test\",\"lastName\":\"User\",\"phone\":\"1234567890\",\"address\":\"Test\"}")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ]; then
    mark_success "Password corto rechazado"
else
    mark_failure "Password corto NO rechazado (HTTP $HTTP_CODE)"
fi

# Test 3: Email vacío
((TOTAL_TESTS++))
echo "Test 3: Email vacío"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d '{"email":"","password":"password123","firstName":"Test","lastName":"User","phone":"1234567890","address":"Test"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ]; then
    mark_success "Email vacío rechazado"
else
    mark_failure "Email vacío NO rechazado (HTTP $HTTP_CODE)"
fi

# Test 4: FirstName vacío
((TOTAL_TESTS++))
echo "Test 4: FirstName vacío"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"test$(date +%s)@test.com\",\"password\":\"password123\",\"firstName\":\"\",\"lastName\":\"User\",\"phone\":\"1234567890\",\"address\":\"Test\"}")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ]; then
    mark_success "FirstName vacío rechazado"
else
    mark_failure "FirstName vacío NO rechazado (HTTP $HTTP_CODE)"
fi

# Test 5: Email con espacios
((TOTAL_TESTS++))
echo "Test 5: Email con espacios"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d '{"email":"test user@test.com","password":"password123","firstName":"Test","lastName":"User","phone":"1234567890","address":"Test"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ]; then
    mark_success "Email con espacios rechazado"
else
    mark_failure "Email con espacios NO rechazado (HTTP $HTTP_CODE)"
fi

# Test 6: FirstName > 100 caracteres
((TOTAL_TESTS++))
echo "Test 6: FirstName > 100 caracteres"
LONG_NAME=$(printf 'A%.0s' {1..101})
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"test$(date +%s)@test.com\",\"password\":\"password123\",\"firstName\":\"$LONG_NAME\",\"lastName\":\"User\",\"phone\":\"1234567890\",\"address\":\"Test\"}")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ]; then
    mark_success "FirstName largo rechazado"
else
    mark_failure "FirstName largo NO rechazado (HTTP $HTTP_CODE)"
fi

# Test 7: Phone > 20 caracteres
((TOTAL_TESTS++))
echo "Test 7: Phone > 20 caracteres"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"test$(date +%s)@test.com\",\"password\":\"password123\",\"firstName\":\"Test\",\"lastName\":\"User\",\"phone\":\"123456789012345678901\",\"address\":\"Test\"}")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ]; then
    mark_success "Phone largo rechazado"
else
    mark_failure "Phone largo NO rechazado (HTTP $HTTP_CODE)"
fi

# ============================================
# VALIDACIONES DE CARRITO
# ============================================
print_header "2. VALIDACIONES DE CARRITO"

# Crear usuario para tests de carrito
EMAIL="field-test-$(date +%s)@test.com"
curl -s -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"password123\",\"firstName\":\"Test\",\"lastName\":\"User\",\"phone\":\"1234567890\",\"address\":\"Test\"}" > /dev/null

RESPONSE=$(curl -s -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"password123\"}")
TOKEN=$(echo "$RESPONSE" | jq -r '.accessToken' 2>/dev/null)

# Test 8: ProductId = 0
((TOTAL_TESTS++))
echo "Test 8: ProductId = 0"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"productId":0,"quantity":1}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ] || [ "$HTTP_CODE" -eq 404 ]; then
    mark_success "ProductId=0 rechazado"
else
    mark_failure "ProductId=0 NO rechazado (HTTP $HTTP_CODE)"
fi

# Test 9: ProductId negativo
((TOTAL_TESTS++))
echo "Test 9: ProductId negativo"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"productId":-1,"quantity":1}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ] || [ "$HTTP_CODE" -eq 404 ]; then
    mark_success "ProductId negativo rechazado"
else
    mark_failure "ProductId negativo NO rechazado (HTTP $HTTP_CODE)"
fi

# Test 10: Quantity = 0
((TOTAL_TESTS++))
echo "Test 10: Quantity = 0"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"productId":1,"quantity":0}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ]; then
    mark_success "Quantity=0 rechazado"
else
    mark_failure "Quantity=0 NO rechazado (HTTP $HTTP_CODE)"
fi

# Test 11: Quantity negativa
((TOTAL_TESTS++))
echo "Test 11: Quantity negativa"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"productId":1,"quantity":-5}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ]; then
    mark_success "Quantity negativa rechazada"
else
    mark_failure "Quantity negativa NO rechazada (HTTP $HTTP_CODE)"
fi

# Test 12: ProductId inexistente
((TOTAL_TESTS++))
echo "Test 12: ProductId inexistente"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"productId":99999,"quantity":1}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 404 ]; then
    mark_success "ProductId inexistente rechazado"
else
    mark_failure "ProductId inexistente NO rechazado (HTTP $HTTP_CODE)"
fi

# ============================================
# VALIDACIONES DE PAGINACIÓN
# ============================================
print_header "3. VALIDACIONES DE PAGINACIÓN"

# Test 13: Page negativa
((TOTAL_TESTS++))
echo "Test 13: Page negativa"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=-1&size=10")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
# Spring puede convertir a 0 o rechazar
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 400 ]; then
    mark_success "Page negativa manejada"
else
    mark_failure "Page negativa no manejada (HTTP $HTTP_CODE)"
fi

# Test 14: Size = 0
((TOTAL_TESTS++))
echo "Test 14: Size = 0"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=0")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" -eq 400 ] || [ "$HTTP_CODE" -eq 200 ]; then
    mark_success "Size=0 manejado"
else
    mark_failure "Size=0 no manejado (HTTP $HTTP_CODE)"
fi

# Test 15: Size muy grande (>1000)
((TOTAL_TESTS++))
echo "Test 15: Size > 1000"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=5000")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
if [ "$HTTP_CODE" -eq 200 ]; then
    ACTUAL_SIZE=$(echo "$BODY" | jq -r '.size' 2>/dev/null)
    if [ "$ACTUAL_SIZE" -lt 1000 ]; then
        mark_success "Size limitado correctamente a $ACTUAL_SIZE"
    else
        mark_failure "Size no limitado (retorna $ACTUAL_SIZE)"
    fi
else
    mark_failure "Error al consultar con size grande (HTTP $HTTP_CODE)"
fi

# ============================================
# RESUMEN FINAL
# ============================================
print_header "📊 RESUMEN DE VALIDACIONES"

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")

echo -e "${BLUE}Total de tests:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Tests exitosos:${NC} $PASSED_TESTS"
echo -e "${RED}Tests fallidos:${NC} $FAILED_TESTS"
echo -e "${YELLOW}Tasa de éxito:${NC} $SUCCESS_RATE%"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ Todas las validaciones funcionan correctamente${NC}"
    exit 0
else
    echo -e "${RED}⚠️  $FAILED_TESTS validaciones necesitan revisión${NC}"
    exit 1
fi

