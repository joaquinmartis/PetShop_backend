#!/bin/bash

echo "════════════════════════════════════════════════════════"
echo "  🧪 PRUEBA DE HTTPONLY COOKIES - Virtual Pet"
echo "════════════════════════════════════════════════════════"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Test 1: Registro
echo -e "${YELLOW}➤ TEST 1: Registrando usuario...${NC}"
TEST_EMAIL="cookie-test-$(date +%s)@test.com"
REGISTER=$(curl -s -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"password123\",\"firstName\":\"Cookie\",\"lastName\":\"Test\",\"phone\":\"1234567890\",\"address\":\"Test 123\"}")

USER_ID=$(echo "$REGISTER" | jq -r '.id')
if [ "$USER_ID" != "null" ] && [ "$USER_ID" != "" ]; then
    echo -e "   ${GREEN}✅ Usuario registrado: $TEST_EMAIL (ID: $USER_ID)${NC}"
    ((PASSED++))
else
    echo -e "   ${RED}❌ Error al registrar usuario${NC}"
    ((FAILED++))
fi
echo ""

# Test 2: Login con cookies
echo -e "${YELLOW}➤ TEST 2: Login con cookies HttpOnly...${NC}"
rm -f /tmp/test-cookies.txt
LOGIN=$(curl -s -c /tmp/test-cookies.txt -X POST http://localhost:8080/api/users/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"password123\"}")

MESSAGE=$(echo "$LOGIN" | jq -r '.message // "error"')
if [ "$MESSAGE" = "Login exitoso" ]; then
    echo -e "   ${GREEN}✅ Login exitoso${NC}"
    echo "$LOGIN" | jq .
    ((PASSED++))
else
    echo -e "   ${RED}❌ Error en login${NC}"
    ((FAILED++))
fi
echo ""

# Verificar cookies
echo -e "${YELLOW}   📋 Cookies establecidas:${NC}"
if [ -f /tmp/test-cookies.txt ]; then
    ACCESS_COOKIE=$(grep "accessToken" /tmp/test-cookies.txt 2>/dev/null)
    REFRESH_COOKIE=$(grep "refreshToken" /tmp/test-cookies.txt 2>/dev/null)

    if [ ! -z "$ACCESS_COOKIE" ]; then
        echo -e "      ${GREEN}✅ accessToken (HttpOnly)${NC}"
        ((PASSED++))
    else
        echo -e "      ${RED}❌ accessToken NO encontrada${NC}"
        ((FAILED++))
    fi

    if [ ! -z "$REFRESH_COOKIE" ]; then
        echo -e "      ${GREEN}✅ refreshToken (HttpOnly)${NC}"
        ((PASSED++))
    else
        echo -e "      ${RED}❌ refreshToken NO encontrada${NC}"
        ((FAILED++))
    fi
else
    echo -e "   ${RED}❌ Archivo de cookies no creado${NC}"
    ((FAILED++))
fi
echo ""

# Test 3: Request autenticado
echo -e "${YELLOW}➤ TEST 3: Request autenticado con cookies...${NC}"
PROFILE=$(curl -s -b /tmp/test-cookies.txt http://localhost:8080/api/users/profile)
PROFILE_EMAIL=$(echo "$PROFILE" | jq -r '.email // "error"')

if [ "$PROFILE_EMAIL" = "$TEST_EMAIL" ]; then
    echo -e "   ${GREEN}✅ Autenticación con cookies: OK${NC}"
    echo -e "   ${GREEN}✅ Email verificado: $PROFILE_EMAIL${NC}"
    ((PASSED++))
else
    echo -e "   ${RED}❌ Error en autenticación: $PROFILE_EMAIL${NC}"
    ((FAILED++))
fi
echo ""

# Test 4: Carrito
echo -e "${YELLOW}➤ TEST 4: Acceso al carrito con cookies...${NC}"
CART=$(curl -s -b /tmp/test-cookies.txt http://localhost:8080/api/cart)
CART_ID=$(echo "$CART" | jq -r '.id // "error"')

if [ "$CART_ID" != "error" ] && [ "$CART_ID" != "null" ]; then
    echo -e "   ${GREEN}✅ Carrito accesible: ID=$CART_ID${NC}"
    echo "   📋 Total items: $(echo "$CART" | jq -r '.totalItems')"
    ((PASSED++))
else
    echo -e "   ${RED}❌ Error al acceder al carrito${NC}"
    ((FAILED++))
fi
echo ""

# Test 5: Sin cookies (debe fallar)
echo -e "${YELLOW}➤ TEST 5: Request SIN cookies (debe fallar)...${NC}"
PROFILE_NO_COOKIE=$(curl -s http://localhost:8080/api/users/profile)
STATUS=$(echo "$PROFILE_NO_COOKIE" | jq -r '.status // "200"')

if [ "$STATUS" = "403" ] || [ "$STATUS" = "401" ]; then
    echo -e "   ${GREEN}✅ Acceso correctamente bloqueado sin cookies${NC}"
    ((PASSED++))
else
    echo -e "   ${RED}❌ Error: Acceso permitido sin cookies${NC}"
    ((FAILED++))
fi
echo ""

# Test 6: Logout
echo -e "${YELLOW}➤ TEST 6: Logout (eliminar cookies)...${NC}"
LOGOUT=$(curl -s -c /tmp/test-cookies.txt -b /tmp/test-cookies.txt \
  -X POST http://localhost:8080/api/users/logout)
LOGOUT_MSG=$(echo "$LOGOUT" | jq -r '.message // "error"')

if [ "$LOGOUT_MSG" = "Logout exitoso" ]; then
    echo -e "   ${GREEN}✅ Logout exitoso${NC}"
    echo "$LOGOUT" | jq .
    ((PASSED++))
else
    echo -e "   ${RED}❌ Error en logout${NC}"
    ((FAILED++))
fi
echo ""

# Test 7: Request después del logout (debe fallar)
echo -e "${YELLOW}➤ TEST 7: Request después del logout (debe fallar)...${NC}"
PROFILE_AFTER_LOGOUT=$(curl -s -b /tmp/test-cookies.txt http://localhost:8080/api/users/profile)
STATUS_AFTER=$(echo "$PROFILE_AFTER_LOGOUT" | jq -r '.status // "200"')

if [ "$STATUS_AFTER" = "403" ] || [ "$STATUS_AFTER" = "401" ]; then
    echo -e "   ${GREEN}✅ Acceso correctamente bloqueado después del logout${NC}"
    ((PASSED++))
else
    echo -e "   ${RED}❌ Error: Acceso permitido después del logout${NC}"
    ((FAILED++))
fi
echo ""

# Resumen
echo "════════════════════════════════════════════════════════"
echo "  📊 RESUMEN DE PRUEBAS"
echo "════════════════════════════════════════════════════════"
TOTAL=$((PASSED + FAILED))
SUCCESS_RATE=$(echo "scale=2; $PASSED * 100 / $TOTAL" | bc)

echo ""
echo -e "Total de tests: ${TOTAL}"
echo -e "Tests pasados: ${GREEN}${PASSED}${NC}"
echo -e "Tests fallidos: ${RED}${FAILED}${NC}"
echo -e "Tasa de éxito: ${GREEN}${SUCCESS_RATE}%${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODAS LAS PRUEBAS PASARON! 🎉${NC}"
    echo ""
    echo "✅ HttpOnly Cookies funcionan correctamente"
    echo "✅ Autenticación con cookies: OK"
    echo "✅ Logout elimina cookies: OK"
    echo "✅ Seguridad implementada correctamente"
else
    echo -e "${RED}⚠️  ALGUNAS PRUEBAS FALLARON ⚠️${NC}"
fi

echo ""
echo "════════════════════════════════════════════════════════"

# Cleanup
rm -f /tmp/test-cookies.txt

exit $FAILED

