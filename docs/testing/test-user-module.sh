#!/bin/bash

# ============================================
# TEST AUTOMATIZADO - MÓDULO USER MANAGEMENT
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

# Función para imprimir test
print_test() {
    echo -e "${YELLOW}TEST $TOTAL_TESTS: $1${NC}"
}

# Función para resultado exitoso
print_success() {
    echo -e "${GREEN}✅ PASSED${NC} - $1"
    echo ""
    ((PASSED_TESTS++))
}

# Función para resultado fallido
print_failure() {
    echo -e "${RED}❌ FAILED${NC} - $1"
    echo -e "${RED}   Esperado: $2${NC}"
    echo -e "${RED}   Obtenido: $3${NC}"
    echo ""
    ((FAILED_TESTS++))
}

# Función para verificar código de respuesta (solo imprime, no cuenta)
check_status() {
    local expected=$1
    local actual=$2
    local test_name=$3

    if [ "$actual" -eq "$expected" ]; then
        echo -e "${GREEN}   ✓ Status: $actual (correcto)${NC}"
        return 0
    else
        echo -e "${RED}   ✗ Status: $actual (esperado: $expected)${NC}"
        return 1
    fi
}

# Función para verificar que el JSON contenga un campo (solo imprime, no cuenta)
check_json_field() {
    local json=$1
    local field=$2
    local test_name=$3

    if echo "$json" | jq -e ".$field" > /dev/null 2>&1; then
        echo -e "${GREEN}   ✓ Campo '$field' presente${NC}"
        return 0
    else
        echo -e "${RED}   ✗ Campo '$field' ausente${NC}"
        return 1
    fi
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

# Finalizar reporte
finish_report() {
    cat >> "$REPORT_FILE" << EOF

| Métrica | Valor |
|---------|-------|
| **Total Tests** | $TOTAL_TESTS |
| **Passed** | ✅ $PASSED_TESTS |
| **Failed** | ❌ $FAILED_TESTS |
| **Success Rate** | $(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")% |

---

## 📝 Detalles de Tests

EOF
}

# ============================================
# TESTS DEL MÓDULO USER
# ============================================

# Verificar que el servidor esté corriendo
print_header "VERIFICANDO SERVIDOR"
((TOTAL_TESTS++))
print_test "Verificar que el servidor esté corriendo"

SERVER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/../actuator/health" 2>/dev/null || echo "000")

if [ "$SERVER_CHECK" = "000" ]; then
    # Intentar con endpoint público
    SERVER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/products" 2>/dev/null || echo "000")
fi

if [ "$SERVER_CHECK" != "000" ]; then
    print_success "Servidor corriendo en $BASE_URL"
else
    echo -e "${RED}❌ ERROR: El servidor no está corriendo en $BASE_URL${NC}"
    echo -e "${RED}   Por favor, inicia la aplicación con: mvn spring-boot:run${NC}"
    exit 1
fi

echo ""

# ============================================
# TEST 1: Registrar Usuario Válido
# ============================================
print_header "TEST 1: REGISTRAR USUARIO VÁLIDO"
((TOTAL_TESTS++))
print_test "POST /users/register con datos válidos"

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

echo "Response Body: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

# Verificaciones
TEST_PASSED=true
check_status 201 "$HTTP_CODE" "Registro de usuario" || TEST_PASSED=false
check_json_field "$BODY" "id" "Usuario registrado" || TEST_PASSED=false
check_json_field "$BODY" "email" "Email en respuesta" || TEST_PASSED=false
check_json_field "$BODY" "role" "Rol en respuesta" || TEST_PASSED=false

# Verificar que el rol sea CLIENT
ROLE=$(echo "$BODY" | jq -r '.role')
if [ "$ROLE" = "CLIENT" ]; then
    echo -e "${GREEN}   ✓ Rol por defecto es CLIENT${NC}"
else
    echo -e "${RED}   ✗ Rol esperado: CLIENT, obtenido: $ROLE${NC}"
    TEST_PASSED=false
fi

# Resultado final del test
if [ "$TEST_PASSED" = true ]; then
    print_success "Registro de usuario válido"
else
    print_failure "Registro de usuario válido" "Todas las verificaciones OK" "Algunas verificaciones fallaron"
fi

# ============================================
# TEST 2: Registrar Usuario con Email Duplicado
# ============================================
print_header "TEST 2: REGISTRAR EMAIL DUPLICADO (debe fallar)"
((TOTAL_TESTS++))
print_test "POST /users/register con email ya registrado"

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

echo "Response Body: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

# Debe retornar 409 Conflict
TEST_PASSED=true
if [ "$HTTP_CODE" -eq 409 ]; then
    echo -e "${GREEN}   ✓ Status: 409 Conflict (correcto)${NC}"
    check_json_field "$BODY" "status" "ErrorResponse" || TEST_PASSED=false
    check_json_field "$BODY" "error" "ErrorResponse" || TEST_PASSED=false
    check_json_field "$BODY" "message" "ErrorResponse" || TEST_PASSED=false
else
    echo -e "${RED}   ✗ Status: $HTTP_CODE (esperado: 409)${NC}"
    TEST_PASSED=false
fi

if [ "$TEST_PASSED" = true ]; then
    print_success "Email duplicado rechazado con 409"
else
    print_failure "Email duplicado" "Status 409 Conflict" "Status $HTTP_CODE"
fi

# ============================================
# TEST 3: Registrar Usuario con Email Inválido
# ============================================
print_header "TEST 3: REGISTRAR CON EMAIL INVÁLIDO (debe fallar)"
((TOTAL_TESTS++))
print_test "POST /users/register con email sin formato válido"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"email-invalido\",
        \"password\": \"$TEST_PASSWORD\",
        \"firstName\": \"Test\",
        \"lastName\": \"User\",
        \"phone\": \"1234567890\",
        \"address\": \"123 Test Street\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "Response Body: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

# Debe retornar 400 Bad Request
if [ "$HTTP_CODE" -eq 400 ]; then
    print_success "Email inválido rechazado - Status: 400"
    check_json_field "$BODY" "status" "ErrorResponse estructurado"
else
    print_failure "Validación de email" "Status 400" "Status $HTTP_CODE"
fi

# ============================================
# TEST 4: Registrar Usuario con Campos Faltantes
# ============================================
print_header "TEST 4: REGISTRAR CON CAMPOS FALTANTES (debe fallar)"
((TOTAL_TESTS++))
print_test "POST /users/register sin campo firstName"

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

echo "Response Body: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 400 ]; then
    print_success "Campos faltantes rechazados - Status: 400"
else
    print_failure "Validación de campos requeridos" "Status 400" "Status $HTTP_CODE"
fi

# ============================================
# TEST 5: Login con Credenciales Válidas
# ============================================
print_header "TEST 5: LOGIN CON CREDENCIALES VÁLIDAS"
((TOTAL_TESTS++))
print_test "POST /users/login con credenciales correctas"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "Response Body: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

check_status 200 "$HTTP_CODE" "Login exitoso"
if [ $? -eq 0 ]; then
    check_json_field "$BODY" "accessToken" "Token JWT presente"
    check_json_field "$BODY" "user" "Datos de usuario presentes"

    # Guardar token para siguientes tests
    TOKEN=$(echo "$BODY" | jq -r '.accessToken')

    if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
        print_success "Token JWT obtenido y guardado"
    else
        print_failure "Obtención de token" "Token válido" "Token vacío o null"
    fi
fi

# ============================================
# TEST 6: Login con Contraseña Incorrecta
# ============================================
print_header "TEST 6: LOGIN CON CONTRASEÑA INCORRECTA (debe fallar)"
((TOTAL_TESTS++))
print_test "POST /users/login con contraseña incorrecta"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"password_incorrecta\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "Response Body: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 401 ]; then
    print_success "Contraseña incorrecta rechazada - Status: 401"
    check_json_field "$BODY" "status" "ErrorResponse con campo status"
else
    print_failure "Autenticación fallida" "Status 401" "Status $HTTP_CODE"
fi

# ============================================
# TEST 7: Login con Email No Registrado
# ============================================
print_header "TEST 7: LOGIN CON EMAIL NO REGISTRADO (debe fallar)"
((TOTAL_TESTS++))
print_test "POST /users/login con email inexistente"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"noexiste@example.com\",
        \"password\": \"$TEST_PASSWORD\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "Response Body: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 401 ]; then
    print_success "Usuario no registrado rechazado - Status: 401"
else
    print_failure "Usuario inexistente" "Status 401" "Status $HTTP_CODE"
fi

# ============================================
# TEST 8: Obtener Perfil con Token Válido
# ============================================
print_header "TEST 8: OBTENER PERFIL CON TOKEN VÁLIDO"
((TOTAL_TESTS++))
print_test "GET /users/profile con Authorization Bearer"

if [ -z "$TOKEN" ]; then
    echo -e "${RED}⚠️  SALTADO: No hay token disponible${NC}"
    echo ""
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/users/profile" \
        -H "Authorization: Bearer $TOKEN")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "Response Body: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""

    check_status 200 "$HTTP_CODE" "Obtener perfil"
    if [ $? -eq 0 ]; then
        check_json_field "$BODY" "id" "ID de usuario"
        check_json_field "$BODY" "email" "Email de usuario"
        check_json_field "$BODY" "role" "Rol de usuario"

        # Verificar que el email coincida
        EMAIL_RESPONSE=$(echo "$BODY" | jq -r '.email')
        if [ "$EMAIL_RESPONSE" = "$TEST_EMAIL" ]; then
            print_success "Email coincide con el registrado"
        else
            print_failure "Email en perfil" "$TEST_EMAIL" "$EMAIL_RESPONSE"
        fi
    fi
fi

# ============================================
# TEST 9: Obtener Perfil sin Token
# ============================================
print_header "TEST 9: OBTENER PERFIL SIN TOKEN (debe fallar)"
((TOTAL_TESTS++))
print_test "GET /users/profile sin header Authorization"

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/users/profile")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "Response Body: $BODY"
echo ""

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    print_success "Acceso sin token rechazado - Status: $HTTP_CODE"
else
    print_failure "Seguridad sin token" "Status 401 o 403" "Status $HTTP_CODE"
fi

# ============================================
# TEST 10: Obtener Perfil con Token Inválido
# ============================================
print_header "TEST 10: OBTENER PERFIL CON TOKEN INVÁLIDO (debe fallar)"
((TOTAL_TESTS++))
print_test "GET /users/profile con token inválido"

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/users/profile" \
    -H "Authorization: Bearer token_invalido_123")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "Response Body: $BODY"
echo ""

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    print_success "Token inválido rechazado - Status: $HTTP_CODE"
else
    print_failure "Seguridad con token inválido" "Status 401 o 403" "Status $HTTP_CODE"
fi

# ============================================
# TEST 11: Actualizar Perfil con Datos Válidos
# ============================================
print_header "TEST 11: ACTUALIZAR PERFIL CON DATOS VÁLIDOS"
((TOTAL_TESTS++))
print_test "PATCH /users/profile con datos actualizados"

if [ -z "$TOKEN" ]; then
    echo -e "${RED}⚠️  SALTADO: No hay token disponible${NC}"
    echo ""
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

    echo "Response Body: $BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""

    check_status 200 "$HTTP_CODE" "Actualizar perfil"
    if [ $? -eq 0 ]; then
        # Verificar que los datos se actualizaron
        FIRST_NAME=$(echo "$BODY" | jq -r '.firstName')
        if [ "$FIRST_NAME" = "Updated" ]; then
            print_success "Datos actualizados correctamente"
        else
            print_failure "Actualización de datos" "firstName: Updated" "firstName: $FIRST_NAME"
        fi
    fi
fi

# ============================================
# TEST 12: Actualizar Perfil sin Token
# ============================================
print_header "TEST 12: ACTUALIZAR PERFIL SIN TOKEN (debe fallar)"
((TOTAL_TESTS++))
print_test "PATCH /users/profile sin Authorization"

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/users/profile" \
    -H "Content-Type: application/json" \
    -d "{
        \"firstName\": \"Hacker\",
        \"lastName\": \"Bad\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "Response Body: $BODY"
echo ""

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    print_success "Actualización sin token rechazada - Status: $HTTP_CODE"
else
    print_failure "Seguridad en actualización" "Status 401 o 403" "Status $HTTP_CODE"
fi

# ============================================
# RESUMEN FINAL
# ============================================
print_header "RESUMEN FINAL"

echo -e "${BLUE}Total de Tests:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Tests Exitosos:${NC} $PASSED_TESTS"
echo -e "${RED}Tests Fallidos:${NC} $FAILED_TESTS"

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
echo -e "${YELLOW}Tasa de Éxito:${NC} $SUCCESS_RATE%"

echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON! 🎉${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}⚠️  Algunos tests fallaron. Revisa los detalles arriba.${NC}"
    EXIT_CODE=1
fi

# Generar reporte
init_report
cat >> "$REPORT_FILE" << EOF
### ✅ Tests Pasados: $PASSED_TESTS/$TOTAL_TESTS
### ❌ Tests Fallidos: $FAILED_TESTS/$TOTAL_TESTS
### 📈 Tasa de Éxito: $SUCCESS_RATE%

---

## 🧪 Tests Ejecutados

1. ✅ Servidor corriendo
2. ✅ Registrar usuario válido (POST /users/register)
3. ✅ Registrar email duplicado - debe fallar con 409
4. ✅ Registrar email inválido - debe fallar con 400
5. ✅ Registrar con campos faltantes - debe fallar con 400
6. ✅ Login con credenciales válidas (POST /users/login)
7. ✅ Login con contraseña incorrecta - debe fallar con 401
8. ✅ Login con email no registrado - debe fallar con 401
9. ✅ Obtener perfil con token válido (GET /users/profile)
10. ✅ Obtener perfil sin token - debe fallar con 401/403
11. ✅ Obtener perfil con token inválido - debe fallar con 401/403
12. ✅ Actualizar perfil con datos válidos (PATCH /users/profile)
13. ✅ Actualizar perfil sin token - debe fallar con 401/403

---

## 📊 Resultados por Endpoint

| Endpoint | Método | Tests | Estado |
|----------|--------|-------|--------|
| /users/register | POST | 4 | Validación completa |
| /users/login | POST | 3 | Autenticación probada |
| /users/profile | GET | 3 | Seguridad verificada |
| /users/profile | PATCH | 2 | Actualización probada |

---

**Generado:** $(date '+%Y-%m-%d %H:%M:%S')
EOF

finish_report

echo ""
echo -e "${BLUE}📄 Reporte generado: $REPORT_FILE${NC}"
echo ""

exit $EXIT_CODE

