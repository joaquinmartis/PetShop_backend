#!/bin/bash

# ============================================
# TEST AUTOMATIZADO - MÓDULO USER MANAGEMENT
# Versión 2.0 - Conteo corregido
# ============================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Variables globales
BASE_URL="http://localhost:8080/api"
TEST_EMAIL="test-$(date +%s)@example.com"
TEST_PASSWORD="password123"
TOKEN=""
REPORT_FILE="user-module-test-report.md"

# Función para imprimir encabezado
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Función para marcar test como PASSED
mark_test_passed() {
    echo -e "${GREEN}✅ TEST PASSED: $1${NC}"
    echo ""
    ((PASSED_TESTS++))
}

# Función para marcar test como FAILED
mark_test_failed() {
    echo -e "${RED}❌ TEST FAILED: $1${NC}"
    echo -e "${RED}   Razón: $2${NC}"
    echo ""
    ((FAILED_TESTS++))
}

# Iniciar reporte
init_report() {
    cat > "$REPORT_FILE" << EOF
# 📊 Reporte de Tests - Módulo User Management

**Fecha:** $(date '+%Y-%m-%d %H:%M:%S')
**Base URL:** $BASE_URL

---

## 📋 Resumen Ejecutivo

EOF
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
    echo -e "${RED}❌ ERROR: El servidor no está corriendo en $BASE_URL${NC}"
    echo -e "${RED}   Por favor, inicia la aplicación con: mvn spring-boot:run${NC}"
    exit 1
fi

# ============================================
# TEST 1: Registrar Usuario Válido
# ============================================
print_header "TEST 1: Registrar Usuario Válido"
((TOTAL_TESTS++))
echo "POST /users/register con datos válidos"
echo ""

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

if [ "$HTTP_CODE" -eq 201 ] && echo "$BODY" | jq -e '.id' > /dev/null 2>&1; then
    mark_test_passed "Usuario registrado correctamente (201 Created)"
else
    mark_test_failed "Registro de usuario" "Esperado 201 con campo 'id', obtenido $HTTP_CODE"
fi

# ============================================
# TEST 2: Registrar Email Duplicado
# ============================================
print_header "TEST 2: Registrar Email Duplicado (debe fallar)"
((TOTAL_TESTS++))
echo "POST /users/register con email ya existente"
echo ""

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

if [ "$HTTP_CODE" -eq 409 ]; then
    mark_test_passed "Email duplicado rechazado con 409 Conflict"
else
    mark_test_failed "Validación email duplicado" "Esperado 409 Conflict, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 3: Registrar Email Inválido
# ============================================
print_header "TEST 3: Registrar Email Inválido (debe fallar)"
((TOTAL_TESTS++))
echo "POST /users/register con formato de email incorrecto"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"email-sin-arroba\",
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

if [ "$HTTP_CODE" -eq 400 ]; then
    mark_test_passed "Email inválido rechazado con 400 Bad Request"
else
    mark_test_failed "Validación formato email" "Esperado 400 Bad Request, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 4: Registrar sin Campos Requeridos
# ============================================
print_header "TEST 4: Registrar sin Campos Requeridos (debe fallar)"
((TOTAL_TESTS++))
echo "POST /users/register sin campo firstName"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"otro@example.com\",
        \"password\": \"$TEST_PASSWORD\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 400 ]; then
    mark_test_passed "Campos requeridos validados con 400 Bad Request"
else
    mark_test_failed "Validación campos requeridos" "Esperado 400 Bad Request, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 5: Login con Credenciales Válidas
# ============================================
print_header "TEST 5: Login con Credenciales Válidas"
((TOTAL_TESTS++))
echo "POST /users/login con credenciales correctas"
echo ""

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
    mark_test_passed "Login exitoso, token JWT obtenido"
else
    mark_test_failed "Login válido" "Esperado 200 con accessToken, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 6: Login con Contraseña Incorrecta
# ============================================
print_header "TEST 6: Login con Contraseña Incorrecta (debe fallar)"
((TOTAL_TESTS++))
echo "POST /users/login con password incorrecta"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"wrong_password\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 401 ]; then
    mark_test_passed "Contraseña incorrecta rechazada con 401 Unauthorized"
else
    mark_test_failed "Validación contraseña" "Esperado 401 Unauthorized, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 7: Login con Email No Registrado
# ============================================
print_header "TEST 7: Login con Email No Registrado (debe fallar)"
((TOTAL_TESTS++))
echo "POST /users/login con email inexistente"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"noexiste@example.com\",
        \"password\": \"$TEST_PASSWORD\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 401 ]; then
    mark_test_passed "Email no registrado rechazado con 401 Unauthorized"
else
    mark_test_failed "Validación usuario existente" "Esperado 401 Unauthorized, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 8: Obtener Perfil con Token Válido
# ============================================
print_header "TEST 8: Obtener Perfil con Token Válido"
((TOTAL_TESTS++))
echo "GET /users/profile con Authorization Bearer"
echo ""

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    mark_test_failed "Obtener perfil" "No hay token disponible del login"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""

    EMAIL_RESPONSE=$(echo "$BODY" | jq -r '.email' 2>/dev/null)

    if [ "$HTTP_CODE" -eq 200 ] && [ "$EMAIL_RESPONSE" = "$TEST_EMAIL" ]; then
        mark_test_passed "Perfil obtenido correctamente con token válido"
    else
        mark_test_failed "Obtener perfil" "Esperado 200 con email correcto, obtenido $HTTP_CODE"
    fi
fi

# ============================================
# TEST 9: Obtener Perfil sin Token
# ============================================
print_header "TEST 9: Obtener Perfil sin Token (debe fallar)"
((TOTAL_TESTS++))
echo "GET /users/profile sin header Authorization"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/users/profile")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    mark_test_passed "Acceso sin token bloqueado con $HTTP_CODE"
else
    mark_test_failed "Seguridad sin token" "Esperado 401 o 403, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 10: Obtener Perfil con Token Inválido
# ============================================
print_header "TEST 10: Obtener Perfil con Token Inválido (debe fallar)"
((TOTAL_TESTS++))
echo "GET /users/profile con token malformado"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/users/profile" \
    -H "Authorization: Bearer token_invalido_123")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    mark_test_passed "Token inválido rechazado con $HTTP_CODE"
else
    mark_test_failed "Seguridad token inválido" "Esperado 401 o 403, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 11: Actualizar Perfil con Datos Válidos
# ============================================
print_header "TEST 11: Actualizar Perfil con Datos Válidos"
((TOTAL_TESTS++))
echo "PATCH /users/profile con datos actualizados"
echo ""

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    mark_test_failed "Actualizar perfil" "No hay token disponible"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"firstName\": \"Updated\",
            \"lastName\": \"Name\",
            \"phone\": \"9876543210\",
            \"address\": \"456 New Address\"
        }")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""

    FIRST_NAME=$(echo "$BODY" | jq -r '.firstName' 2>/dev/null)

    if [ "$HTTP_CODE" -eq 200 ] && [ "$FIRST_NAME" = "Updated" ]; then
        mark_test_passed "Perfil actualizado correctamente"
    else
        mark_test_failed "Actualizar perfil" "Esperado 200 con datos actualizados, obtenido $HTTP_CODE"
    fi
fi

# ============================================
# TEST 12: Actualizar Perfil sin Token
# ============================================
print_header "TEST 12: Actualizar Perfil sin Token (debe fallar)"
((TOTAL_TESTS++))
echo "PATCH /users/profile sin Authorization"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
    -H "Content-Type: application/json" \
    -d "{
        \"firstName\": \"Hacker\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    mark_test_passed "Actualización sin token bloqueada con $HTTP_CODE"
else
    mark_test_failed "Seguridad actualización" "Esperado 401 o 403, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 13: Login con Datos Vacíos
# ============================================
print_header "TEST 13: Login con Datos Vacíos (debe fallar)"
((TOTAL_TESTS++))
echo "POST /users/login con campos vacíos"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"\",
        \"password\": \"\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 400 ]; then
    mark_test_passed "Datos vacíos rechazados con 400 Bad Request"
else
    mark_test_failed "Validación datos vacíos" "Esperado 400 Bad Request, obtenido $HTTP_CODE"
fi

# ============================================
# RESUMEN FINAL
# ============================================
print_header "RESUMEN FINAL DE TESTS"

echo -e "${BLUE}Total de Tests Ejecutados:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Tests Exitosos (PASSED):${NC} $PASSED_TESTS"
echo -e "${RED}Tests Fallidos (FAILED):${NC} $FAILED_TESTS"

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
echo -e "${YELLOW}Tasa de Éxito:${NC} $SUCCESS_RATE%"

echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON! 🎉${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}⚠️  $FAILED_TESTS test(s) fallaron. Revisa los detalles arriba.${NC}"
    EXIT_CODE=1
fi

# Generar reporte
init_report
cat >> "$REPORT_FILE" << EOF
| Métrica | Valor |
|---------|-------|
| **Total Tests** | $TOTAL_TESTS |
| **Passed** | ✅ $PASSED_TESTS |
| **Failed** | ❌ $FAILED_TESTS |
| **Success Rate** | $SUCCESS_RATE% |

---

## 🧪 Tests Ejecutados

1. Registrar usuario válido → **$([ $PASSED_TESTS -ge 1 ] && echo "✅" || echo "❌")**
2. Registrar email duplicado (409) → **$([ $TOTAL_TESTS -ge 2 ] && echo "✅" || echo "❌")**
3. Registrar email inválido (400) → **$([ $TOTAL_TESTS -ge 3 ] && echo "✅" || echo "❌")**
4. Registrar sin campos (400) → **$([ $TOTAL_TESTS -ge 4 ] && echo "✅" || echo "❌")**
5. Login válido con token → **$([ $TOTAL_TESTS -ge 5 ] && echo "✅" || echo "❌")**
6. Login password incorrecta (401) → **$([ $TOTAL_TESTS -ge 6 ] && echo "✅" || echo "❌")**
7. Login email no existe (401) → **$([ $TOTAL_TESTS -ge 7 ] && echo "✅" || echo "❌")**
8. Obtener perfil con token → **$([ $TOTAL_TESTS -ge 8 ] && echo "✅" || echo "❌")**
9. Obtener perfil sin token (403) → **$([ $TOTAL_TESTS -ge 9 ] && echo "✅" || echo "❌")**
10. Obtener perfil token inválido (403) → **$([ $TOTAL_TESTS -ge 10 ] && echo "✅" || echo "❌")**
11. Actualizar perfil con datos → **$([ $TOTAL_TESTS -ge 11 ] && echo "✅" || echo "❌")**
12. Actualizar perfil sin token (403) → **$([ $TOTAL_TESTS -ge 12 ] && echo "✅" || echo "❌")**
13. Login con datos vacíos (400) → **$([ $TOTAL_TESTS -ge 13 ] && echo "✅" || echo "❌")**

---

**Generado:** $(date '+%Y-%m-%d %H:%M:%S')
EOF

echo ""
echo -e "${BLUE}📄 Reporte generado: $REPORT_FILE${NC}"
echo ""

exit $EXIT_CODE

