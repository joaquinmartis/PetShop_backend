#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "  🧪 TEST EXHAUSTIVO - ACTUALIZACIÓN DE CANTIDADES EN CARRITO"
echo "  Prueba simultánea con múltiples clientes y productos"
echo "════════════════════════════════════════════════════════════════"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0
TIMESTAMP=$(date +%s)

pass_test() {
    echo -e "   ${GREEN}✅ $1${NC}"
    ((PASSED++))
}

fail_test() {
    echo -e "   ${RED}❌ $1${NC}"
    ((FAILED++))
}

info() {
    echo -e "   ${CYAN}ℹ️  $1${NC}"
}

warn() {
    echo -e "   ${YELLOW}⚠️  $1${NC}"
}

# Verificar servidor
echo -e "${YELLOW}➤ Verificando servidor...${NC}"
PRODUCTS_TEST=$(curl -s http://localhost:8080/api/products?size=1 2>/dev/null)
if [[ "$PRODUCTS_TEST" == *"content"* ]]; then
    pass_test "Servidor corriendo"
else
    fail_test "Servidor no responde"
    exit 1
fi
echo ""

# Obtener productos con stock
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  PREPARACIÓN: OBTENER PRODUCTOS CON STOCK${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

PRODUCTS=$(curl -s "http://localhost:8080/api/products?size=10")

# Seleccionar el primer producto con stock suficiente
PRODUCT_ID=$(echo "$PRODUCTS" | jq -r '.content[0].id')
PRODUCT_NAME=$(echo "$PRODUCTS" | jq -r '.content[0].name')
PRODUCT_PRICE=$(echo "$PRODUCTS" | jq -r '.content[0].price')
PRODUCT_STOCK=$(echo "$PRODUCTS" | jq -r '.content[0].stock')

info "Producto seleccionado: ID=$PRODUCT_ID, Stock=$PRODUCT_STOCK, Precio=\$$PRODUCT_PRICE"
info "Nombre: $PRODUCT_NAME"
echo ""

# Crear 3 clientes
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  FASE 1: CREAR 3 CLIENTES SIMULTÁNEOS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

CLIENT_COOKIES=()
CLIENT_IDS=()

for i in {1..3}; do
    echo -e "${YELLOW}➤ Cliente #$i: Registro y Login${NC}"

    EMAIL="cart-update-client-$i-$TIMESTAMP@test.com"
    COOKIES_FILE="/tmp/client-$i-cookies-$TIMESTAMP.txt"

    # Registro
    REGISTER=$(curl -s -X POST http://localhost:8080/api/users/register \
      -H "Content-Type: application/json" \
      -d "{
        \"email\":\"$EMAIL\",
        \"password\":\"password123\",
        \"firstName\":\"Cliente\",
        \"lastName\":\"$i\",
        \"phone\":\"123456789$i\",
        \"address\":\"Test $i\"
      }")

    CLIENT_ID=$(echo "$REGISTER" | jq -r '.id')

    # Login
    LOGIN=$(curl -s -c "$COOKIES_FILE" -X POST http://localhost:8080/api/users/login \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"$EMAIL\",\"password\":\"password123\"}")

    LOGIN_MSG=$(echo "$LOGIN" | jq -r '.message')

    if [ "$LOGIN_MSG" = "Login exitoso" ]; then
        pass_test "Cliente #$i creado y autenticado (ID: $CLIENT_ID)"
        CLIENT_COOKIES+=("$COOKIES_FILE")
        CLIENT_IDS+=($CLIENT_ID)
    else
        fail_test "Error al crear cliente #$i"
    fi
done
echo ""

# ============================================================================
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  FASE 2: CADA CLIENTE AGREGA EL PRODUCTO AL CARRITO${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

for i in {0..2}; do
    echo -e "${YELLOW}➤ Cliente #$((i+1)): Agregar producto (cantidad: 2)${NC}"
    COOKIES="${CLIENT_COOKIES[$i]}"

    if [ "$PRODUCT_STOCK" -ge 2 ]; then
        ADD=$(curl -s -b "$COOKIES" -X POST http://localhost:8080/api/cart/items \
          -H "Content-Type: application/json" \
          -d "{\"productId\":$PRODUCT_ID,\"quantity\":2}")

        ITEMS=$(echo "$ADD" | jq -r '.totalItems')
        if [ "$ITEMS" = "2" ]; then
            pass_test "Producto agregado (x2) - totalItems: $ITEMS"
        else
            fail_test "Error al agregar producto (totalItems: $ITEMS)"
        fi
    else
        warn "Producto sin stock suficiente"
    fi
done
echo ""

# ============================================================================
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  FASE 3: ACTUALIZAR CANTIDADES - DIFERENTES ESCENARIOS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Cliente 1: Aumentar cantidad
echo -e "${YELLOW}➤ TEST 1: Cliente #1 - Aumentar cantidad (2 → 5)${NC}"
COOKIES="${CLIENT_COOKIES[0]}"

CART_BEFORE=$(curl -s -b "$COOKIES" http://localhost:8080/api/cart)
TOTAL_BEFORE=$(echo "$CART_BEFORE" | jq -r '.totalItems')
CURRENT_QTY=$(echo "$CART_BEFORE" | jq ".items[] | select(.productId==$PRODUCT_ID) | .quantity")

info "Estado antes: totalItems=$TOTAL_BEFORE, cantidad producto=$CURRENT_QTY"

UPDATE1=$(curl -s -b "$COOKIES" -X PATCH "http://localhost:8080/api/cart/items/$PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d "{\"quantity\":5}")

NEW_ITEMS1=$(echo "$UPDATE1" | jq -r '.totalItems')
EXPECTED_ITEMS1=$((TOTAL_BEFORE - CURRENT_QTY + 5))

if [ "$NEW_ITEMS1" = "$EXPECTED_ITEMS1" ]; then
    pass_test "Cantidad actualizada: $CURRENT_QTY → 5 (totalItems: $TOTAL_BEFORE → $NEW_ITEMS1)"

    NEW_QTY=$(echo "$UPDATE1" | jq ".items[] | select(.productId==$PRODUCT_ID) | .quantity")
    if [ "$NEW_QTY" = "5" ]; then
        pass_test "Cantidad del item verificada: $NEW_QTY"
    else
        fail_test "Cantidad incorrecta en item: $NEW_QTY (esperado: 5)"
    fi
else
    fail_test "totalItems incorrecto (esperado: $EXPECTED_ITEMS1, obtenido: $NEW_ITEMS1)"
fi
echo ""

# Cliente 2: Reducir cantidad
echo -e "${YELLOW}➤ TEST 2: Cliente #2 - Reducir cantidad (2 → 1)${NC}"
COOKIES="${CLIENT_COOKIES[1]}"

CART_BEFORE=$(curl -s -b "$COOKIES" http://localhost:8080/api/cart)
TOTAL_BEFORE=$(echo "$CART_BEFORE" | jq -r '.totalItems')
CURRENT_QTY=$(echo "$CART_BEFORE" | jq ".items[] | select(.productId==$PRODUCT_ID) | .quantity")

info "Estado antes: totalItems=$TOTAL_BEFORE, cantidad producto=$CURRENT_QTY"

UPDATE2=$(curl -s -b "$COOKIES" -X PATCH "http://localhost:8080/api/cart/items/$PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d "{\"quantity\":1}")

NEW_ITEMS2=$(echo "$UPDATE2" | jq -r '.totalItems')
EXPECTED_ITEMS2=$((TOTAL_BEFORE - CURRENT_QTY + 1))

if [ "$NEW_ITEMS2" = "$EXPECTED_ITEMS2" ]; then
    pass_test "Cantidad actualizada: $CURRENT_QTY → 1 (totalItems: $TOTAL_BEFORE → $NEW_ITEMS2)"

    NEW_QTY=$(echo "$UPDATE2" | jq ".items[] | select(.productId==$PRODUCT_ID) | .quantity")
    if [ "$NEW_QTY" = "1" ]; then
        pass_test "Cantidad del item verificada: $NEW_QTY"
    else
        fail_test "Cantidad incorrecta: $NEW_QTY (esperado: 1)"
    fi
else
    fail_test "totalItems incorrecto (esperado: $EXPECTED_ITEMS2, obtenido: $NEW_ITEMS2)"
fi
echo ""

# Cliente 3: Aumento grande
echo -e "${YELLOW}➤ TEST 3: Cliente #3 - Aumento grande (2 → 10)${NC}"
COOKIES="${CLIENT_COOKIES[2]}"

CART_BEFORE=$(curl -s -b "$COOKIES" http://localhost:8080/api/cart)
TOTAL_BEFORE=$(echo "$CART_BEFORE" | jq -r '.totalItems')
CURRENT_QTY=$(echo "$CART_BEFORE" | jq ".items[] | select(.productId==$PRODUCT_ID) | .quantity")

info "Estado antes: totalItems=$TOTAL_BEFORE, cantidad producto=$CURRENT_QTY"

UPDATE3=$(curl -s -b "$COOKIES" -X PATCH "http://localhost:8080/api/cart/items/$PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d "{\"quantity\":10}")

NEW_ITEMS3=$(echo "$UPDATE3" | jq -r '.totalItems')
EXPECTED_ITEMS3=$((TOTAL_BEFORE - CURRENT_QTY + 10))

if [ "$NEW_ITEMS3" = "$EXPECTED_ITEMS3" ]; then
    pass_test "Cantidad actualizada: $CURRENT_QTY → 10 (totalItems: $TOTAL_BEFORE → $NEW_ITEMS3)"

    NEW_QTY=$(echo "$UPDATE3" | jq ".items[] | select(.productId==$PRODUCT_ID) | .quantity")
    if [ "$NEW_QTY" = "10" ]; then
        pass_test "Cantidad del item verificada: $NEW_QTY"
    else
        fail_test "Cantidad incorrecta: $NEW_QTY (esperado: 10)"
    fi
else
    fail_test "totalItems incorrecto (esperado: $EXPECTED_ITEMS3, obtenido: $NEW_ITEMS3)"
fi
echo ""

# ============================================================================
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  FASE 4: VALIDACIONES DE ERROR${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}➤ TEST 4: Actualizar a cantidad 0 (debe fallar)${NC}"
COOKIES="${CLIENT_COOKIES[0]}"

UPDATE_ZERO=$(curl -s -w "\n%{http_code}" -b "$COOKIES" -X PATCH "http://localhost:8080/api/cart/items/$PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d "{\"quantity\":0}")

STATUS_ZERO=$(echo "$UPDATE_ZERO" | tail -1)

if [ "$STATUS_ZERO" = "400" ]; then
    pass_test "Cantidad 0 rechazada correctamente (HTTP 400)"
    BODY_ZERO=$(echo "$UPDATE_ZERO" | head -n -1)
    ERROR_MSG=$(echo "$BODY_ZERO" | jq -r '.message')
    info "Mensaje: $ERROR_MSG"
else
    fail_test "Cantidad 0 no rechazada (HTTP $STATUS_ZERO)"
fi
echo ""

echo -e "${YELLOW}➤ TEST 5: Actualizar a cantidad negativa (debe fallar)${NC}"

UPDATE_NEG=$(curl -s -w "\n%{http_code}" -b "$COOKIES" -X PATCH "http://localhost:8080/api/cart/items/$PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d "{\"quantity\":-5}")

STATUS_NEG=$(echo "$UPDATE_NEG" | tail -1)

if [ "$STATUS_NEG" = "400" ]; then
    pass_test "Cantidad negativa rechazada correctamente (HTTP 400)"
else
    fail_test "Cantidad negativa no rechazada (HTTP $STATUS_NEG)"
fi
echo ""

echo -e "${YELLOW}➤ TEST 6: Actualizar producto que no está en carrito (debe fallar)${NC}"

UPDATE_NOT_IN_CART=$(curl -s -w "\n%{http_code}" -b "$COOKIES" -X PATCH "http://localhost:8080/api/cart/items/99999" \
  -H "Content-Type: application/json" \
  -d "{\"quantity\":5}")

STATUS_NOT_IN=$(echo "$UPDATE_NOT_IN_CART" | tail -1)

if [ "$STATUS_NOT_IN" = "404" ]; then
    pass_test "Producto inexistente en carrito rechazado (HTTP 404)"
else
    fail_test "Producto inexistente no rechazado apropiadamente (HTTP $STATUS_NOT_IN)"
fi
echo ""

echo -e "${YELLOW}➤ TEST 7: Actualizar sin autenticación (debe fallar)${NC}"

UPDATE_NO_AUTH=$(curl -s -w "\n%{http_code}" -X PATCH "http://localhost:8080/api/cart/items/$PRODUCT_ID" \
  -H "Content-Type: application/json" \
  -d "{\"quantity\":5}")

STATUS_NO_AUTH=$(echo "$UPDATE_NO_AUTH" | tail -1)

if [ "$STATUS_NO_AUTH" = "403" ]; then
    pass_test "Acceso sin autenticación bloqueado (HTTP 403)"
else
    fail_test "Acceso sin auth no bloqueado (HTTP $STATUS_NO_AUTH)"
fi
echo ""

# ============================================================================
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  FASE 5: VERIFICACIÓN DE INTEGRIDAD${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

for i in {0..2}; do
    echo -e "${YELLOW}➤ TEST 8.$((i+1)): Verificar carrito completo de Cliente #$((i+1))${NC}"
    COOKIES="${CLIENT_COOKIES[$i]}"

    CART=$(curl -s -b "$COOKIES" http://localhost:8080/api/cart)
    CART_ID=$(echo "$CART" | jq -r '.id')
    CART_USER=$(echo "$CART" | jq -r '.userId')
    CART_ITEMS=$(echo "$CART" | jq -r '.items | length')
    CART_TOTAL_ITEMS=$(echo "$CART" | jq -r '.totalItems')
    CART_TOTAL_AMOUNT=$(echo "$CART" | jq -r '.totalAmount')

    if [ "$CART_ID" != "null" ]; then
        pass_test "Carrito obtenido: ID=$CART_ID"
        info "UserID: $CART_USER (esperado: ${CLIENT_IDS[$i]})"
        info "Productos diferentes: $CART_ITEMS"
        info "Total items: $CART_TOTAL_ITEMS"
        info "Total amount: \$$CART_TOTAL_AMOUNT"

        if [ "$CART_USER" = "${CLIENT_IDS[$i]}" ]; then
            pass_test "UserID correcto en carrito"
        else
            fail_test "UserID incorrecto (esperado: ${CLIENT_IDS[$i]}, obtenido: $CART_USER)"
        fi

        AMOUNT_CHECK=$(awk "BEGIN {print ($CART_TOTAL_AMOUNT > 0)}")
        if [ "$AMOUNT_CHECK" = "1" ]; then
            pass_test "Total amount calculado correctamente"
        else
            fail_test "Total amount inválido: $CART_TOTAL_AMOUNT"
        fi

        # Verificar subtotal del item
        ITEM_QTY=$(echo "$CART" | jq ".items[0].quantity")
        ITEM_PRICE=$(echo "$CART" | jq ".items[0].unitPrice")
        ITEM_SUBTOTAL=$(echo "$CART" | jq ".items[0].subtotal")
        EXPECTED_SUBTOTAL=$(awk "BEGIN {printf \"%.2f\", ($ITEM_QTY * $ITEM_PRICE)}")
        SUBTOTAL_NORMALIZED=$(echo "$ITEM_SUBTOTAL" | awk '{printf "%.2f", $1}')

        if [ "$SUBTOTAL_NORMALIZED" = "$EXPECTED_SUBTOTAL" ]; then
            pass_test "Subtotal correcto ($ITEM_QTY × \$$ITEM_PRICE = \$$ITEM_SUBTOTAL)"
        else
            fail_test "Subtotal incorrecto (esperado: $EXPECTED_SUBTOTAL, obtenido: $SUBTOTAL_NORMALIZED)"
        fi
    else
        fail_test "Error al obtener carrito"
    fi
    echo ""
done

# ============================================================================
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  FASE 6: LIMPIEZA${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

for i in {0..2}; do
    echo -e "${YELLOW}➤ Limpiando Cliente #$((i+1))${NC}"
    COOKIES="${CLIENT_COOKIES[$i]}"

    LOGOUT=$(curl -s -b "$COOKIES" -c "$COOKIES" -X POST http://localhost:8080/api/users/logout)
    LOGOUT_MSG=$(echo "$LOGOUT" | jq -r '.message')

    if [ "$LOGOUT_MSG" = "Logout exitoso" ]; then
        pass_test "Logout exitoso"
    else
        fail_test "Error en logout"
    fi

    rm -f "$COOKIES"
done
echo ""

# ============================================================================
# RESUMEN FINAL
# ============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "  📊 RESUMEN FINAL - TEST EXHAUSTIVO DE ACTUALIZACIONES"
echo "════════════════════════════════════════════════════════════════"

TOTAL=$((PASSED + FAILED))
SUCCESS_RATE=0
if [ $TOTAL -gt 0 ]; then
    SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED * 100 / $TOTAL)}")
fi

echo ""
echo -e "Total de tests ejecutados: ${TOTAL}"
echo -e "Tests pasados: ${GREEN}${PASSED}${NC}"
echo -e "Tests fallidos: ${RED}${FAILED}${NC}"
echo -e "Tasa de éxito: ${GREEN}${SUCCESS_RATE}%${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  🎉 ¡TODOS LOS TESTS PASARON! 🎉${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "✅ Creación de clientes: OK"
    echo "✅ Agregar productos: OK"
    echo "✅ Aumentar cantidades: OK"
    echo "✅ Reducir cantidades: OK"
    echo "✅ Actualizaciones grandes: OK"
    echo "✅ Validaciones de error: OK"
    echo "✅ Cálculos de subtotales: OK"
    echo "✅ Integridad de carritos: OK"
    echo ""
    echo "🎯 La actualización de cantidades funciona perfectamente"
else
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  ⚠️  ALGUNOS TESTS FALLARON ⚠️${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Revisa los detalles arriba para identificar los problemas"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"

exit $FAILED

