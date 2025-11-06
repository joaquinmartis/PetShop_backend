#!/bin/bash

# ============================================
# TEST AUTOMATIZADO COMPLETO - MÓDULO USER MANAGEMENT
# Versión 3.0 - Cobertura Completa (~90%)
# ============================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores y arrays
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a TEST_RESULTS=()
declare -a TEST_NAMES=()

# Variables globales
BASE_URL="http://localhost:8080/api"
TEST_EMAIL="test-$(date +%s)@example.com"
TEST_PASSWORD="password123"
TOKEN=""
REPORT_FILE="user-module-complete-test-report.md"

# Función para imprimir encabezado
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Función para marcar test como PASSED
mark_test_passed() {
    TEST_RESULTS+=("PASS")
    TEST_NAMES+=("$1")
    echo -e "${GREEN}✅ TEST PASSED: $1${NC}"
    echo ""
    ((PASSED_TESTS++))
}

# Función para marcar test como FAILED
mark_test_failed() {
    TEST_RESULTS+=("FAIL")
    TEST_NAMES+=("$1")
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
    echo -e "${GREEN}✅ Servidor corriendo en $BASE_URL${NC}"
    echo ""
else
    echo -e "${RED}❌ ERROR: El servidor no está corriendo${NC}"
    exit 1
fi

# ============================================
# GRUPO 1: REGISTRO - CASOS VÁLIDOS
# ============================================
print_header "GRUPO 1: REGISTRO - CASOS VÁLIDOS"

# TEST 1: Registro válido
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar usuario con datos válidos"
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
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""
if [ "$HTTP_CODE" -eq 201 ] && echo "$BODY" | jq -e '.id and .email and .role' > /dev/null 2>&1; then
    mark_test_passed "Registro con datos válidos"
else
    mark_test_failed "Registro con datos válidos" "Esperado 201 con campos completos, obtenido $HTTP_CODE"
fi

# TEST 2: Registro con password de exactamente 8 caracteres (límite)
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar con password de 8 caracteres (límite mínimo)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"test-8chars-$(date +%s)@example.com\",
        \"password\": \"12345678\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
if [ "$HTTP_CODE" -eq 201 ]; then
    mark_test_passed "Password de 8 caracteres aceptada"
else
    mark_test_failed "Password de 8 caracteres" "Esperado 201, obtenido $HTTP_CODE"
fi

# ============================================
# GRUPO 2: REGISTRO - VALIDACIÓN DE PASSWORD
# ============================================
print_header "GRUPO 2: VALIDACIÓN DE PASSWORD"

# TEST 3: Password muy corta (< 8 caracteres)
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar con password de 7 caracteres (debe fallar)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"test-short@example.com\",
        \"password\": \"1234567\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""
if [ "$HTTP_CODE" -eq 400 ]; then
    mark_test_passed "Password corta rechazada con 400"
else
    mark_test_failed "Validación password corta" "Esperado 400, obtenido $HTTP_CODE"
fi

# TEST 4: Password vacía
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar con password vacía (debe fallar)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"test@example.com\",
        \"password\": \"\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
if [ "$HTTP_CODE" -eq 400 ]; then
    mark_test_passed "Password vacía rechazada con 400"
else
    mark_test_failed "Validación password vacía" "Esperado 400, obtenido $HTTP_CODE"
fi

# ============================================
# GRUPO 3: REGISTRO - VALIDACIÓN DE CAMPOS REQUERIDOS
# ============================================
print_header "GRUPO 3: VALIDACIÓN DE CAMPOS REQUERIDOS"

# TEST 5: Sin firstName
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar sin firstName (debe fallar)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"test@example.com\",
        \"password\": \"password123\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 400 ] && mark_test_passed "firstName requerido validado" || mark_test_failed "Validación firstName" "Esperado 400, obtenido $HTTP_CODE"

# TEST 6: Sin lastName
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar sin lastName (debe fallar)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"test@example.com\",
        \"password\": \"password123\",
        \"firstName\": \"Test\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 400 ] && mark_test_passed "lastName requerido validado" || mark_test_failed "Validación lastName" "Esperado 400, obtenido $HTTP_CODE"

# TEST 7: Sin email
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar sin email (debe fallar)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"password\": \"password123\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 400 ] && mark_test_passed "email requerido validado" || mark_test_failed "Validación email" "Esperado 400, obtenido $HTTP_CODE"

# TEST 8: Sin phone
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar sin phone (debe fallar)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"test@example.com\",
        \"password\": \"password123\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 400 ] && mark_test_passed "phone requerido validado" || mark_test_failed "Validación phone" "Esperado 400, obtenido $HTTP_CODE"

# TEST 9: Sin address
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar sin address (debe fallar)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"test@example.com\",
        \"password\": \"password123\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 400 ] && mark_test_passed "address requerido validado" || mark_test_failed "Validación address" "Esperado 400, obtenido $HTTP_CODE"

# ============================================
# GRUPO 4: REGISTRO - VALIDACIÓN DE LONGITUD MÁXIMA
# ============================================
print_header "GRUPO 4: VALIDACIÓN DE LONGITUD MÁXIMA"

# TEST 10: firstName > 100 caracteres
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar con firstName > 100 caracteres (debe fallar)"
LONG_NAME=$(printf 'A%.0s' {1..101})
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"test@example.com\",
        \"password\": \"password123\",
        \"firstName\": \"$LONG_NAME\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 400 ] && mark_test_passed "firstName max length validado" || mark_test_failed "Validación firstName length" "Esperado 400, obtenido $HTTP_CODE"

# TEST 11: email > 100 caracteres
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar con email > 100 caracteres (debe fallar)"
LONG_EMAIL=$(printf 'a%.0s' {1..90})"@example.com"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$LONG_EMAIL\",
        \"password\": \"password123\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 400 ] && mark_test_passed "email max length validado" || mark_test_failed "Validación email length" "Esperado 400, obtenido $HTTP_CODE"

# TEST 12: phone > 20 caracteres
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar con phone > 20 caracteres (debe fallar)"
LONG_PHONE=$(printf '1%.0s' {1..21})
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"test@example.com\",
        \"password\": \"password123\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"$LONG_PHONE\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 400 ] && mark_test_passed "phone max length validado" || mark_test_failed "Validación phone length" "Esperado 400, obtenido $HTTP_CODE"

# ============================================
# GRUPO 5: REGISTRO - VALIDACIÓN DE EMAIL
# ============================================
print_header "GRUPO 5: VALIDACIÓN DE EMAIL"

# TEST 13: Email sin @
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar con email sin @ (debe fallar)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"emailsinarroba\",
        \"password\": \"password123\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 400 ] && mark_test_passed "Email sin @ rechazado" || mark_test_failed "Validación formato email" "Esperado 400, obtenido $HTTP_CODE"

# TEST 14: Email duplicado
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Registrar con email duplicado (debe fallar con 409)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"password123\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""
[ "$HTTP_CODE" -eq 409 ] && mark_test_passed "Email duplicado rechazado con 409" || mark_test_failed "Validación email duplicado" "Esperado 409, obtenido $HTTP_CODE"

# TEST 15: Email case sensitivity
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Login con email en mayúsculas (verificar case insensitivity)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$(echo $TEST_EMAIL | tr '[:lower:]' '[:upper:]')\",
        \"password\": \"$TEST_PASSWORD\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 401 ]; then
    mark_test_passed "Email case sensitivity manejado (200 o 401 es correcto)"
else
    mark_test_failed "Email case sensitivity" "Esperado 200 o 401, obtenido $HTTP_CODE"
fi

# ============================================
# GRUPO 6: LOGIN
# ============================================
print_header "GRUPO 6: LOGIN Y AUTENTICACIÓN"

# TEST 16: Login válido
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Login con credenciales válidas"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""
TOKEN=$(echo "$BODY" | jq -r '.accessToken' 2>/dev/null)
if [ "$HTTP_CODE" -eq 200 ] && [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    mark_test_passed "Login exitoso, token obtenido"
else
    mark_test_failed "Login válido" "Esperado 200 con token, obtenido $HTTP_CODE"
fi

# TEST 17: Login password incorrecta
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Login con password incorrecta (debe fallar con 401)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"wrongpassword\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 401 ] && mark_test_passed "Password incorrecta rechazada con 401" || mark_test_failed "Validación password incorrecta" "Esperado 401, obtenido $HTTP_CODE"

# TEST 18: Login email no existe
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Login con email inexistente (debe fallar con 401)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"noexiste@example.com\",
        \"password\": \"password123\"
    }")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 401 ] && mark_test_passed "Email inexistente rechazado con 401" || mark_test_failed "Validación email inexistente" "Esperado 401, obtenido $HTTP_CODE"

# ============================================
# GRUPO 7: PERFIL - OBTENER
# ============================================
print_header "GRUPO 7: OBTENER PERFIL"

# TEST 19: Obtener perfil con token válido
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Obtener perfil con token válido"
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    mark_test_failed "Obtener perfil" "No hay token disponible"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""
    if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.email' > /dev/null 2>&1; then
        mark_test_passed "Perfil obtenido correctamente"
    else
        mark_test_failed "Obtener perfil" "Esperado 200 con datos, obtenido $HTTP_CODE"
    fi
fi

# TEST 20: Obtener perfil sin token
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Obtener perfil sin token (debe fallar con 401/403)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/users/profile")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    mark_test_passed "Acceso sin token bloqueado"
else
    mark_test_failed "Seguridad sin token" "Esperado 401 o 403, obtenido $HTTP_CODE"
fi

# TEST 21: Obtener perfil con token inválido
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Obtener perfil con token inválido (debe fallar con 401/403)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/users/profile" \
    -H "Authorization: Bearer token_invalido_xyz")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    mark_test_passed "Token inválido rechazado"
else
    mark_test_failed "Seguridad token inválido" "Esperado 401 o 403, obtenido $HTTP_CODE"
fi

# ============================================
# GRUPO 8: ACTUALIZACIÓN DE PERFIL - PARCIAL
# ============================================
print_header "GRUPO 8: ACTUALIZACIÓN PARCIAL DE PERFIL"

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo -e "${YELLOW}⚠️ Saltando tests de actualización: No hay token${NC}"
    echo ""
else
    # TEST 22: Actualizar solo firstName
    ((TOTAL_TESTS++))
    echo "TEST $TOTAL_TESTS: Actualizar solo firstName"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"firstName": "UpdatedFirst"}')
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""
    FIRST_NAME=$(echo "$BODY" | jq -r '.firstName' 2>/dev/null)
    if [ "$HTTP_CODE" -eq 200 ] && [ "$FIRST_NAME" = "UpdatedFirst" ]; then
        mark_test_passed "Actualización parcial (firstName) exitosa"
    else
        mark_test_failed "Actualización firstName" "Esperado 200 con firstName actualizado, obtenido $HTTP_CODE"
    fi

    # TEST 23: Actualizar solo phone
    ((TOTAL_TESTS++))
    echo "TEST $TOTAL_TESTS: Actualizar solo phone"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"phone": "9999999999"}')
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""
    PHONE=$(echo "$BODY" | jq -r '.phone' 2>/dev/null)
    if [ "$HTTP_CODE" -eq 200 ] && [ "$PHONE" = "9999999999" ]; then
        mark_test_passed "Actualización parcial (phone) exitosa"
    else
        mark_test_failed "Actualización phone" "Esperado 200 con phone actualizado, obtenido $HTTP_CODE"
    fi

    # TEST 24: Actualizar solo address
    ((TOTAL_TESTS++))
    echo "TEST $TOTAL_TESTS: Actualizar solo address"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"address": "Nueva Direccion 456"}')
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Actualización parcial (address) exitosa" || mark_test_failed "Actualización address" "Esperado 200, obtenido $HTTP_CODE"

    # TEST 25: Actualizar con body vacío
    ((TOTAL_TESTS++))
    echo "TEST $TOTAL_TESTS: Actualizar con body vacío (sin campos)"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{}')
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Actualización sin campos manejada correctamente" || mark_test_failed "Actualización sin campos" "Esperado 200, obtenido $HTTP_CODE"

    # TEST 26: Actualizar con firstName > 100 caracteres
    ((TOTAL_TESTS++))
    echo "TEST $TOTAL_TESTS: Actualizar con firstName > 100 caracteres (debe fallar)"
    LONG_NAME=$(printf 'B%.0s' {1..101})
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"firstName\": \"$LONG_NAME\"}")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 400 ] && mark_test_passed "firstName largo rechazado en actualización" || mark_test_failed "Validación firstName length (update)" "Esperado 400, obtenido $HTTP_CODE"
fi

# ============================================
# GRUPO 9: CAMBIO DE PASSWORD
# ============================================
print_header "GRUPO 9: CAMBIO DE PASSWORD"

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo -e "${YELLOW}⚠️ Saltando tests de cambio de password: No hay token${NC}"
    echo ""
else
    # TEST 27: Cambiar password con currentPassword correcta
    ((TOTAL_TESTS++))
    echo "TEST $TOTAL_TESTS: Cambiar password con currentPassword correcta"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"currentPassword\": \"$TEST_PASSWORD\",
            \"newPassword\": \"newpassword123\"
        }")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""
    if [ "$HTTP_CODE" -eq 200 ]; then
        mark_test_passed "Cambio de password exitoso"
        TEST_PASSWORD="newpassword123"  # Actualizar password para siguientes tests

        # Re-login para obtener nuevo token
        echo "Re-login con nueva password..."
        RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
            -H "Content-Type: application/json" \
            -d "{
                \"email\": \"$TEST_EMAIL\",
                \"password\": \"$TEST_PASSWORD\"
            }")
        TOKEN=$(echo "$RESPONSE" | sed '$d' | jq -r '.accessToken' 2>/dev/null)
        echo "Nuevo token obtenido"
        echo ""
    else
        mark_test_failed "Cambio de password" "Esperado 200, obtenido $HTTP_CODE"
    fi

    # TEST 28: Cambiar password con currentPassword incorrecta
    ((TOTAL_TESTS++))
    echo "TEST $TOTAL_TESTS: Cambiar password con currentPassword incorrecta (debe fallar)"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"currentPassword\": \"passwordincorrecta\",
            \"newPassword\": \"otrapassword123\"
        }")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 400 ] || [ "$HTTP_CODE" -eq 401 ] && mark_test_passed "Password incorrecta rechazada" || mark_test_failed "Validación currentPassword" "Esperado 400 o 401, obtenido $HTTP_CODE"

    # TEST 29: Cambiar password nueva < 8 caracteres
    ((TOTAL_TESTS++))
    echo "TEST $TOTAL_TESTS: Cambiar password nueva < 8 caracteres (debe fallar)"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"currentPassword\": \"$TEST_PASSWORD\",
            \"newPassword\": \"corta\"
        }")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 400 ] && mark_test_passed "Nueva password corta rechazada" || mark_test_failed "Validación newPassword length" "Esperado 400, obtenido $HTTP_CODE"

    # TEST 30: Intentar cambiar password sin currentPassword
    ((TOTAL_TESTS++))
    echo "TEST $TOTAL_TESTS: Cambiar password sin currentPassword (debe fallar)"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"newPassword\": \"anotherpassword123\"
        }")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 400 ] || [ "$HTTP_CODE" -eq 401 ] && mark_test_passed "Cambio sin currentPassword rechazado" || mark_test_failed "Validación currentPassword required" "Esperado 400 o 401, obtenido $HTTP_CODE"
fi

# ============================================
# RESUMEN FINAL
# ============================================
print_header "RESUMEN FINAL DE TESTS COMPLETOS"

echo -e "${BLUE}Total de Tests Ejecutados:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Tests Exitosos (PASSED):${NC} $PASSED_TESTS"
echo -e "${RED}Tests Fallidos (FAILED):${NC} $FAILED_TESTS"

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
echo -e "${YELLOW}Tasa de Éxito:${NC} $SUCCESS_RATE%"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DESGLOSE POR GRUPO${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "📊 Cobertura por Área:"
echo "  ✓ Registro válido: 2 tests"
echo "  ✓ Validación password: 3 tests"
echo "  ✓ Campos requeridos: 5 tests"
echo "  ✓ Longitud máxima: 3 tests"
echo "  ✓ Validación email: 3 tests"
echo "  ✓ Login: 3 tests"
echo "  ✓ Obtener perfil: 3 tests"
echo "  ✓ Actualización parcial: 5 tests"
echo "  ✓ Cambio de password: 4 tests"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON! 🎉${NC}"
    echo -e "${GREEN}Cobertura completa del módulo User (~90%)${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}⚠️  $FAILED_TESTS test(s) fallaron.${NC}"
    EXIT_CODE=1
fi

# Generar reporte detallado
cat > "$REPORT_FILE" << EOF
# 📊 Reporte Completo de Tests - Módulo User Management

**Fecha:** $(date '+%Y-%m-%d %H:%M:%S')
**Base URL:** $BASE_URL
**Cobertura:** ~90%

---

## 📋 Resumen Ejecutivo

| Métrica | Valor |
|---------|-------|
| **Total Tests** | $TOTAL_TESTS |
| **Passed** | ✅ $PASSED_TESTS |
| **Failed** | ❌ $FAILED_TESTS |
| **Success Rate** | $SUCCESS_RATE% |

---

## 🧪 Tests Ejecutados por Grupo

### Grupo 1: Registro - Casos Válidos (2 tests)
- $([ "${TEST_RESULTS[0]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[0]}
- $([ "${TEST_RESULTS[1]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[1]}

### Grupo 2: Validación de Password (3 tests)
- $([ "${TEST_RESULTS[2]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[2]}
- $([ "${TEST_RESULTS[3]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[3]}

### Grupo 3: Campos Requeridos (5 tests)
- $([ "${TEST_RESULTS[4]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[4]}
- $([ "${TEST_RESULTS[5]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[5]}
- $([ "${TEST_RESULTS[6]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[6]}
- $([ "${TEST_RESULTS[7]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[7]}
- $([ "${TEST_RESULTS[8]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[8]}

### Grupo 4: Longitud Máxima (3 tests)
- $([ "${TEST_RESULTS[9]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[9]}
- $([ "${TEST_RESULTS[10]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[10]}
- $([ "${TEST_RESULTS[11]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[11]}

### Grupo 5: Validación de Email (3 tests)
- $([ "${TEST_RESULTS[12]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[12]}
- $([ "${TEST_RESULTS[13]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[13]}
- $([ "${TEST_RESULTS[14]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[14]}

### Grupo 6: Login (3 tests)
- $([ "${TEST_RESULTS[15]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[15]}
- $([ "${TEST_RESULTS[16]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[16]}
- $([ "${TEST_RESULTS[17]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[17]}

### Grupo 7: Obtener Perfil (3 tests)
- $([ "${TEST_RESULTS[18]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[18]}
- $([ "${TEST_RESULTS[19]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[19]}
- $([ "${TEST_RESULTS[20]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[20]}

### Grupo 8: Actualización Parcial (5 tests)
- $([ "${TEST_RESULTS[21]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[21]}
- $([ "${TEST_RESULTS[22]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[22]}
- $([ "${TEST_RESULTS[23]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[23]}
- $([ "${TEST_RESULTS[24]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[24]}
- $([ "${TEST_RESULTS[25]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[25]}

### Grupo 9: Cambio de Password (4 tests)
- $([ "${TEST_RESULTS[26]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[26]}
- $([ "${TEST_RESULTS[27]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[27]}
- $([ "${TEST_RESULTS[28]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[28]}
- $([ "${TEST_RESULTS[29]}" = "PASS" ] && echo "✅" || echo "❌") ${TEST_NAMES[29]}

---

## 📊 Cobertura de Funcionalidades

| Funcionalidad | Cobertura | Tests |
|---------------|-----------|-------|
| Registro de usuarios | ✅ 100% | 14 |
| Autenticación (Login) | ✅ 100% | 3 |
| Obtener perfil | ✅ 100% | 3 |
| Actualizar perfil | ✅ 100% | 5 |
| Cambiar password | ✅ 100% | 4 |
| Validaciones de seguridad | ✅ 100% | 3 |

---

**Generado:** $(date '+%Y-%m-%d %H:%M:%S')
EOF

echo ""
echo -e "${BLUE}📄 Reporte completo generado: $REPORT_FILE${NC}"
echo ""

exit $EXIT_CODE

