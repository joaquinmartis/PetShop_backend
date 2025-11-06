#!/bin/bash

# ============================================
# TEST EXHAUSTIVO - MÓDULO USER MANAGEMENT
# Validación completa de JSON + Códigos HTTP
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
TEST_EMAIL="test-exhaustive-$(date +%s)@example.com"
TEST_PASSWORD="password123"
TOKEN=""

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
        # Solo verificar que existe
        if echo "$json" | jq -e ".$field" > /dev/null 2>&1; then
            echo -e "${GREEN}   ✓ Campo '$field' presente${NC}"
            return 0
        else
            echo -e "${RED}   ✗ Campo '$field' AUSENTE${NC}"
            return 1
        fi
    else
        # Verificar valor específico
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
# TEST 1: REGISTRO VÁLIDO - VALIDACIÓN COMPLETA
# ============================================
print_header "TEST 1: REGISTRO VÁLIDO CON VALIDACIÓN COMPLETA"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.'
echo ""

# Validación exhaustiva
VALIDATION_PASSED=true

# 1. Código HTTP
if [ "$HTTP_CODE" -ne 201 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 201, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 201 Created${NC}"
fi

# 2. Campos obligatorios
validate_field "$BODY" "id" || VALIDATION_PASSED=false
validate_field "$BODY" "email" "$TEST_EMAIL" || VALIDATION_PASSED=false
validate_field "$BODY" "firstName" "Test" || VALIDATION_PASSED=false
validate_field "$BODY" "lastName" "User" || VALIDATION_PASSED=false
validate_field "$BODY" "phone" "1234567890" || VALIDATION_PASSED=false
validate_field "$BODY" "address" "123 Test Street" || VALIDATION_PASSED=false
validate_field "$BODY" "role" "CLIENT" || VALIDATION_PASSED=false
validate_field "$BODY" "isActive" "true" || VALIDATION_PASSED=false
validate_field "$BODY" "createdAt" || VALIDATION_PASSED=false
validate_field "$BODY" "updatedAt" || VALIDATION_PASSED=false

# 3. Verificar que NO contenga password
if echo "$BODY" | jq -e '.password' > /dev/null 2>&1; then
    echo -e "${RED}   ✗ SEGURIDAD: El password NO debe estar en la respuesta${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ SEGURIDAD: Password no expuesto${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Registro válido con todos los campos correctos"
else
    mark_test_failed "Registro válido" "Validación de campos falló"
fi

# ============================================
# TEST 2: EMAIL DUPLICADO - VALIDAR ERROR
# ============================================
print_header "TEST 2: EMAIL DUPLICADO - VALIDAR ESTRUCTURA DE ERROR"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.'
echo ""

VALIDATION_PASSED=true

# Validar estructura de ErrorResponse
if [ "$HTTP_CODE" -ne 409 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 409 Conflict, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 409 Conflict${NC}"
fi

validate_field "$BODY" "status" "409" || VALIDATION_PASSED=false
validate_field "$BODY" "error" "Conflict" || VALIDATION_PASSED=false
validate_field "$BODY" "message" || VALIDATION_PASSED=false
validate_field "$BODY" "path" "/api/users/register" || VALIDATION_PASSED=false
validate_field "$BODY" "timestamp" || VALIDATION_PASSED=false

# Verificar que el mensaje contenga "email"
MESSAGE=$(echo "$BODY" | jq -r '.message' 2>/dev/null)
if [[ "$MESSAGE" =~ "email" ]] || [[ "$MESSAGE" =~ "Email" ]]; then
    echo -e "${GREEN}   ✓ Mensaje de error menciona 'email'${NC}"
else
    echo -e "${RED}   ✗ Mensaje no menciona 'email': $MESSAGE${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Email duplicado retorna ErrorResponse correcto"
else
    mark_test_failed "Email duplicado" "Estructura de error incorrecta"
fi

# ============================================
# TEST 3: LOGIN VÁLIDO - VALIDAR TOKEN
# ============================================
print_header "TEST 3: LOGIN VÁLIDO - VALIDAR ESTRUCTURA COMPLETA"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response (primeros campos):"
echo "$BODY" | jq '{accessToken: .accessToken[0:50], tokenType, expiresIn, user: .user | {id, email, role}}' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

# Validar LoginResponse
validate_field "$BODY" "accessToken" || VALIDATION_PASSED=false
validate_field "$BODY" "refreshToken" || VALIDATION_PASSED=false
validate_field "$BODY" "tokenType" "Bearer" || VALIDATION_PASSED=false
validate_field "$BODY" "expiresIn" "3600" || VALIDATION_PASSED=false
validate_field "$BODY" "user" || VALIDATION_PASSED=false

# Validar UserResponse dentro de LoginResponse
validate_field "$BODY" "user.id" || VALIDATION_PASSED=false
validate_field "$BODY" "user.email" "$TEST_EMAIL" || VALIDATION_PASSED=false
validate_field "$BODY" "user.role" "CLIENT" || VALIDATION_PASSED=false

# Verificar formato JWT del token
TOKEN=$(echo "$BODY" | jq -r '.accessToken' 2>/dev/null)
if [[ "$TOKEN" =~ ^eyJ.+\..+\..+$ ]]; then
    echo -e "${GREEN}   ✓ Token tiene formato JWT válido (3 partes separadas por .)${NC}"
else
    echo -e "${RED}   ✗ Token no parece ser JWT válido: ${TOKEN:0:20}...${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Login retorna estructura completa y token JWT válido"
else
    mark_test_failed "Login válido" "Validación de respuesta falló"
fi

# ============================================
# TEST 4: LOGIN FALLIDO - VALIDAR ERROR 401
# ============================================
print_header "TEST 4: LOGIN CON PASSWORD INCORRECTA - VALIDAR 401"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"wrongpassword\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 401 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 401 Unauthorized, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 401 Unauthorized${NC}"
fi

validate_field "$BODY" "status" "401" || VALIDATION_PASSED=false
validate_field "$BODY" "error" "Unauthorized" || VALIDATION_PASSED=false
validate_field "$BODY" "message" || VALIDATION_PASSED=false

MESSAGE=$(echo "$BODY" | jq -r '.message' 2>/dev/null)
if [[ "$MESSAGE" =~ "credencial" ]] || [[ "$MESSAGE" =~ "Credencial" ]] || [[ "$MESSAGE" =~ "password" ]]; then
    echo -e "${GREEN}   ✓ Mensaje indica error de credenciales${NC}"
else
    echo -e "${YELLOW}   ⚠ Mensaje no específico: $MESSAGE${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Login fallido retorna 401 con ErrorResponse"
else
    mark_test_failed "Login fallido" "Estructura de error incorrecta"
fi

# ============================================
# TEST 5: OBTENER PERFIL - VALIDAR RESPUESTA
# ============================================
print_header "TEST 5: OBTENER PERFIL CON TOKEN - VALIDAR DATOS"
((TOTAL_TESTS++))

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    mark_test_failed "Obtener perfil" "No hay token disponible del login"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/users/profile" \
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

    # Validar que los datos coincidan con el registro
    validate_field "$BODY" "email" "$TEST_EMAIL" || VALIDATION_PASSED=false
    validate_field "$BODY" "firstName" "Test" || VALIDATION_PASSED=false
    validate_field "$BODY" "lastName" "User" || VALIDATION_PASSED=false
    validate_field "$BODY" "role" "CLIENT" || VALIDATION_PASSED=false

    # Verificar que NO tenga password
    if echo "$BODY" | jq -e '.password or .passwordHash' > /dev/null 2>&1; then
        echo -e "${RED}   ✗ SEGURIDAD: Password expuesto en perfil${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ SEGURIDAD: Password no expuesto${NC}"
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Perfil retorna datos correctos sin exponer password"
    else
        mark_test_failed "Obtener perfil" "Validación de datos falló"
    fi
fi

# ============================================
# TEST 6: ACCESO SIN TOKEN - VALIDAR 403
# ============================================
print_header "TEST 6: ACCESO SIN TOKEN - VALIDAR RECHAZO"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/users/profile")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
if [ -n "$BODY" ]; then
    echo "Response:"
    echo "$BODY"
fi
echo ""

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    echo -e "${GREEN}   ✓ HTTP Code: $HTTP_CODE (Acceso denegado)${NC}"
    mark_test_passed "Acceso sin token correctamente bloqueado"
else
    echo -e "${RED}   ✗ HTTP Code: esperado 401 o 403, obtenido $HTTP_CODE${NC}"
    mark_test_failed "Seguridad sin token" "Acceso permitido sin autenticación"
fi

# ============================================
# TEST 7: VALIDACIÓN DE CAMPO REQUERIDO
# ============================================
print_header "TEST 7: REGISTRO SIN FIRSTNAME - VALIDAR ERROR 400"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"otro@example.com\",
        \"password\": \"password123\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 400 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 400 Bad Request, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 400 Bad Request${NC}"
fi

validate_field "$BODY" "status" "400" || VALIDATION_PASSED=false
validate_field "$BODY" "error" "Bad Request" || VALIDATION_PASSED=false
validate_field "$BODY" "field" "firstName" || VALIDATION_PASSED=false

MESSAGE=$(echo "$BODY" | jq -r '.message' 2>/dev/null)
if [[ "$MESSAGE" =~ "firstName" ]] || [[ "$MESSAGE" =~ "nombre" ]]; then
    echo -e "${GREEN}   ✓ Mensaje indica campo firstName${NC}"
else
    echo -e "${YELLOW}   ⚠ Mensaje no menciona firstName: $MESSAGE${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Campo requerido validado con ErrorResponse completo"
else
    mark_test_failed "Validación firstName" "Estructura de error incorrecta"
fi

# ============================================
# TEST 8: PASSWORD CORTA - VALIDAR ERROR
# ============================================
print_header "TEST 8: PASSWORD < 8 CARACTERES - VALIDAR ERROR"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"short@example.com\",
        \"password\": \"1234567\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 400 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 400, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 400 Bad Request${NC}"
fi

validate_field "$BODY" "status" "400" || VALIDATION_PASSED=false
validate_field "$BODY" "field" "password" || VALIDATION_PASSED=false

MESSAGE=$(echo "$BODY" | jq -r '.message' 2>/dev/null)
if [[ "$MESSAGE" =~ "8" ]] && [[ "$MESSAGE" =~ "caracter" ]]; then
    echo -e "${GREEN}   ✓ Mensaje indica mínimo 8 caracteres${NC}"
else
    echo -e "${YELLOW}   ⚠ Mensaje no específico sobre longitud: $MESSAGE${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Password corta validada con mensaje apropiado"
else
    mark_test_failed "Validación password" "Estructura de error incorrecta"
fi

# ============================================
# TEST 9: ACTUALIZACIÓN PARCIAL
# ============================================
print_header "TEST 9: ACTUALIZACIÓN PARCIAL - SOLO FIRSTNAME"
((TOTAL_TESTS++))

if [ -z "$TOKEN" ]; then
    mark_test_failed "Actualización parcial" "No hay token"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"firstName": "UpdatedName"}')

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

    # Validar que firstName cambió
    validate_field "$BODY" "firstName" "UpdatedName" || VALIDATION_PASSED=false

    # Validar que otros campos NO cambiaron
    validate_field "$BODY" "lastName" "User" || VALIDATION_PASSED=false
    validate_field "$BODY" "email" "$TEST_EMAIL" || VALIDATION_PASSED=false

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Actualización parcial aplicada correctamente"
    else
        mark_test_failed "Actualización parcial" "Campos incorrectos"
    fi
fi

# ============================================
# TEST 10: LONGITUD MÁXIMA
# ============================================
print_header "TEST 10: FIRSTNAME > 100 CARACTERES - VALIDAR ERROR"
((TOTAL_TESTS++))

LONG_NAME=$(printf 'A%.0s' {1..101})

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"long@example.com\",
        \"password\": \"password123\",
        \"firstName\": \"$LONG_NAME\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 400 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 400, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 400 Bad Request${NC}"
fi

validate_field "$BODY" "status" "400" || VALIDATION_PASSED=false
validate_field "$BODY" "field" "firstName" || VALIDATION_PASSED=false

MESSAGE=$(echo "$BODY" | jq -r '.message' 2>/dev/null)
if [[ "$MESSAGE" =~ "100" ]]; then
    echo -e "${GREEN}   ✓ Mensaje indica límite de 100 caracteres${NC}"
else
    echo -e "${YELLOW}   ⚠ Mensaje no menciona límite: $MESSAGE${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Longitud máxima validada correctamente"
else
    mark_test_failed "Validación longitud" "Estructura de error incorrecta"
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
echo "✅ Estructura JSON completa"
echo "✅ Campos obligatorios presentes"
echo "✅ Valores de campos correctos"
echo "✅ Mensajes de error descriptivos"
echo "✅ Seguridad (password no expuesto)"
echo "✅ Formato JWT válido"
echo "✅ ErrorResponse estandarizado"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON CON VALIDACIÓN COMPLETA! 🎉${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}⚠️  $FAILED_TESTS test(s) fallaron en validación exhaustiva${NC}"
    EXIT_CODE=1
fi

exit $EXIT_CODE

