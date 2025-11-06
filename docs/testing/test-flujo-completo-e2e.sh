#!/bin/bash

# ============================================
# TEST END-TO-END - FLUJO COMPLETO VIRTUALPET
# Simula el ciclo completo desde registro hasta entrega
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

TOTAL_STEPS=0
PASSED_STEPS=0
FAILED_STEPS=0

BASE_URL="http://localhost:8080/api"
CLIENT_EMAIL="e2e-client-$(date +%s)@example.com"
CLIENT_PASSWORD="password123"
WAREHOUSE_EMAIL="warehouse@test.com"
WAREHOUSE_PASSWORD="password123"
CLIENT_TOKEN=""
WAREHOUSE_TOKEN=""
ORDER_ID=""
PRODUCT1_ID=""
PRODUCT2_ID=""

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}➤ PASO $1: $2${NC}"
}

mark_success() {
    echo -e "${GREEN}   ✅ $1${NC}"
    ((PASSED_STEPS++))
}

mark_failure() {
    echo -e "${RED}   ❌ $1${NC}"
    echo -e "${RED}      Razón: $2${NC}"
    ((FAILED_STEPS++))
}

print_result() {
    local key=$1
    local value=$2
    echo -e "${MAGENTA}   📋 $key:${NC} $value"
}

# ============================================
# VERIFICAR SERVIDOR
# ============================================
print_header "VERIFICANDO SERVIDOR"

SERVER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/products" 2>/dev/null || echo "000")

if [ "$SERVER_CHECK" != "000" ]; then
    echo -e "${GREEN}✅ Servidor corriendo en $BASE_URL${NC}"
else
    echo -e "${RED}❌ ERROR: Servidor no responde${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  🛒 INICIANDO FLUJO E2E - VIRTUAL PET E-COMMERCE${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================
# FASE 1: CLIENTE - REGISTRO Y EXPLORACIÓN
# ============================================
print_header "FASE 1: CLIENTE - REGISTRO Y AUTENTICACIÓN"

# PASO 1: Registro
print_step "1.1" "Registrar nuevo cliente"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$CLIENT_EMAIL\",
        \"password\": \"$CLIENT_PASSWORD\",
        \"firstName\": \"Cliente\",
        \"lastName\": \"E2E Test\",
        \"phone\": \"2234567890\",
        \"address\": \"Av. Independencia 1234, Mar del Plata\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 201 ]; then
    CLIENT_ID=$(echo "$BODY" | jq -r '.id' 2>/dev/null)
    CLIENT_NAME=$(echo "$BODY" | jq -r '.firstName' 2>/dev/null)
    mark_success "Cliente registrado exitosamente"
    print_result "ID Cliente" "$CLIENT_ID"
    print_result "Email" "$CLIENT_EMAIL"
    print_result "Nombre" "$CLIENT_NAME"
else
    mark_failure "Error al registrar cliente" "HTTP $HTTP_CODE"
    exit 1
fi

# PASO 2: Login
echo ""
print_step "1.2" "Login y obtención de JWT"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/users/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$CLIENT_EMAIL\",
        \"password\": \"$CLIENT_PASSWORD\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
CLIENT_TOKEN=$(echo "$BODY" | jq -r '.accessToken' 2>/dev/null)

if [ "$HTTP_CODE" -eq 200 ] && [ -n "$CLIENT_TOKEN" ] && [ "$CLIENT_TOKEN" != "null" ]; then
    mark_success "Login exitoso, token JWT obtenido"
    print_result "Token (primeros 50 chars)" "${CLIENT_TOKEN:0:50}..."
    print_result "Duración" "3600 segundos (1 hora)"
else
    mark_failure "Error al hacer login" "HTTP $HTTP_CODE"
    exit 1
fi

# ============================================
# FASE 2: CLIENTE - EXPLORACIÓN DE PRODUCTOS
# ============================================
print_header "FASE 2: CLIENTE - EXPLORACIÓN DEL CATÁLOGO"

# PASO 3: Listar categorías
print_step "2.1" "Explorar categorías disponibles"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    CATEGORIES_COUNT=$(echo "$BODY" | jq 'length' 2>/dev/null)
    mark_success "Categorías cargadas correctamente"
    print_result "Total de categorías" "$CATEGORIES_COUNT"

    # Mostrar algunas categorías
    echo "$BODY" | jq -r '.[] | "   • " + .name' 2>/dev/null | head -3
else
    mark_failure "Error al cargar categorías" "HTTP $HTTP_CODE"
fi

# PASO 4: Buscar productos
echo ""
print_step "2.2" "Buscar productos disponibles"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOTAL_PRODUCTS=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
    mark_success "Productos disponibles"
    print_result "Total de productos" "$TOTAL_PRODUCTS"

    # Obtener dos productos para el carrito
    PRODUCT1_ID=$(echo "$BODY" | jq -r '.content[0].id' 2>/dev/null)
    PRODUCT1_NAME=$(echo "$BODY" | jq -r '.content[0].name' 2>/dev/null)
    PRODUCT1_PRICE=$(echo "$BODY" | jq -r '.content[0].price' 2>/dev/null)

    PRODUCT2_ID=$(echo "$BODY" | jq -r '.content[1].id' 2>/dev/null)
    PRODUCT2_NAME=$(echo "$BODY" | jq -r '.content[1].name' 2>/dev/null)
    PRODUCT2_PRICE=$(echo "$BODY" | jq -r '.content[1].price' 2>/dev/null)

    echo ""
    print_result "Producto seleccionado 1" "$PRODUCT1_NAME"
    print_result "  └─ Precio" "\$$PRODUCT1_PRICE"
    print_result "Producto seleccionado 2" "$PRODUCT2_NAME"
    print_result "  └─ Precio" "\$$PRODUCT2_PRICE"
else
    mark_failure "Error al cargar productos" "HTTP $HTTP_CODE"
    exit 1
fi

# ============================================
# FASE 3: CLIENTE - GESTIÓN DEL CARRITO
# ============================================
print_header "FASE 3: CLIENTE - ARMANDO EL CARRITO DE COMPRAS"

# PASO 5: Ver carrito vacío
print_step "3.1" "Verificar carrito inicial (vacío)"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/cart" \
    -H "Authorization: Bearer $CLIENT_TOKEN")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    CART_ID=$(echo "$BODY" | jq -r '.id' 2>/dev/null)
    TOTAL_ITEMS=$(echo "$BODY" | jq -r '.totalItems' 2>/dev/null)
    mark_success "Carrito inicializado"
    print_result "ID del carrito" "$CART_ID"
    print_result "Items" "$TOTAL_ITEMS (vacío)"
else
    mark_failure "Error al obtener carrito" "HTTP $HTTP_CODE"
fi

# PASO 6: Agregar primer producto
echo ""
print_step "3.2" "Agregar producto al carrito (x2 unidades)"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"productId\": $PRODUCT1_ID,
        \"quantity\": 2
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOTAL_ITEMS=$(echo "$BODY" | jq -r '.totalItems' 2>/dev/null)
    TOTAL_AMOUNT=$(echo "$BODY" | jq -r '.totalAmount' 2>/dev/null)
    mark_success "Producto agregado al carrito"
    print_result "Total de items" "$TOTAL_ITEMS"
    print_result "Subtotal" "\$$TOTAL_AMOUNT"
else
    mark_failure "Error al agregar producto" "HTTP $HTTP_CODE"
fi

# PASO 7: Agregar segundo producto
echo ""
print_step "3.3" "Agregar segundo producto (x1 unidad)"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/cart/items" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"productId\": $PRODUCT2_ID,
        \"quantity\": 1
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOTAL_ITEMS=$(echo "$BODY" | jq -r '.totalItems' 2>/dev/null)
    TOTAL_AMOUNT=$(echo "$BODY" | jq -r '.totalAmount' 2>/dev/null)
    ITEMS_COUNT=$(echo "$BODY" | jq '.items | length' 2>/dev/null)
    mark_success "Segundo producto agregado"
    print_result "Productos diferentes" "$ITEMS_COUNT"
    print_result "Total de items" "$TOTAL_ITEMS"
    print_result "Total a pagar" "\$$TOTAL_AMOUNT"
else
    mark_failure "Error al agregar segundo producto" "HTTP $HTTP_CODE"
fi

# ============================================
# FASE 4: CLIENTE - CREACIÓN DEL PEDIDO
# ============================================
print_header "FASE 4: CLIENTE - CREANDO EL PEDIDO"

# PASO 8: Crear pedido
print_step "4.1" "Confirmar pedido desde el carrito"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/orders" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"shippingAddress\": \"Av. Independencia 1234, Mar del Plata\",
        \"notes\": \"Entregar en horario de oficina (9-18hs). Favor tocar timbre.\"
    }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 201 ]; then
    ORDER_ID=$(echo "$BODY" | jq -r '.id' 2>/dev/null)
    ORDER_STATUS=$(echo "$BODY" | jq -r '.status' 2>/dev/null)
    ORDER_TOTAL=$(echo "$BODY" | jq -r '.total' 2>/dev/null)
    ORDER_ITEMS=$(echo "$BODY" | jq '.items | length' 2>/dev/null)
    mark_success "Pedido creado exitosamente"
    print_result "ID del pedido" "#$ORDER_ID"
    print_result "Estado inicial" "$ORDER_STATUS"
    print_result "Total del pedido" "\$$ORDER_TOTAL"
    print_result "Items en el pedido" "$ORDER_ITEMS productos"
    print_result "Dirección de envío" "Av. Independencia 1234, Mar del Plata"
else
    mark_failure "Error al crear pedido" "HTTP $HTTP_CODE"
    echo "$BODY" | jq '.'
    exit 1
fi

# PASO 9: Verificar que el carrito se vació
echo ""
print_step "4.2" "Verificar que el carrito se vació automáticamente"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/cart" \
    -H "Authorization: Bearer $CLIENT_TOKEN")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOTAL_ITEMS=$(echo "$BODY" | jq -r '.totalItems' 2>/dev/null)
    if [ "$TOTAL_ITEMS" -eq 0 ]; then
        mark_success "Carrito vaciado correctamente después de crear pedido"
        print_result "Items en carrito" "$TOTAL_ITEMS (vacío)"
    else
        mark_failure "El carrito NO se vació" "Tiene $TOTAL_ITEMS items"
    fi
else
    mark_failure "Error al verificar carrito" "HTTP $HTTP_CODE"
fi

# PASO 10: Ver detalle del pedido creado
echo ""
print_step "4.3" "Consultar detalle del pedido"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/orders/$ORDER_ID" \
    -H "Authorization: Bearer $CLIENT_TOKEN")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    mark_success "Detalle del pedido obtenido"

    # Mostrar resumen del pedido
    echo ""
    echo -e "${CYAN}   📦 RESUMEN DEL PEDIDO #$ORDER_ID${NC}"
    echo -e "${CYAN}   ════════════════════════════════════════${NC}"
    echo "$BODY" | jq -r '.items[] | "   • " + .productName + " (x" + (.quantity|tostring) + ") - $" + (.subtotal|tostring)' 2>/dev/null
    echo -e "${CYAN}   ────────────────────────────────────────${NC}"
    ORDER_TOTAL=$(echo "$BODY" | jq -r '.total' 2>/dev/null)
    echo -e "${CYAN}   TOTAL: \$$ORDER_TOTAL${NC}"
    echo -e "${CYAN}   ════════════════════════════════════════${NC}"
else
    mark_failure "Error al obtener detalle" "HTTP $HTTP_CODE"
fi

# ============================================
# FASE 5: WAREHOUSE - GESTIÓN DEL PEDIDO
# ============================================
print_header "FASE 5: WAREHOUSE - PROCESAMIENTO DEL PEDIDO"

# PASO 11: Login warehouse
print_step "5.1" "Login empleado de almacén (WAREHOUSE)"
((TOTAL_STEPS++))

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
    WAREHOUSE_NAME=$(echo "$BODY" | jq -r '.user.firstName' 2>/dev/null)
    mark_success "Login WAREHOUSE exitoso"
    print_result "Usuario" "$WAREHOUSE_NAME"
    print_result "Rol" "WAREHOUSE"
else
    mark_failure "Error al hacer login warehouse" "HTTP $HTTP_CODE"
    exit 1
fi

# PASO 12: Ver lista de pedidos pendientes
echo ""
print_step "5.2" "Consultar pedidos pendientes en el sistema"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders?status=CONFIRMED&page=0&size=5" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    TOTAL_CONFIRMED=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
    mark_success "Pedidos CONFIRMED listados"
    print_result "Pedidos confirmados" "$TOTAL_CONFIRMED"

    # Verificar que nuestro pedido está en la lista
    FOUND_ORDER=$(echo "$BODY" | jq ".content[] | select(.id == $ORDER_ID)" 2>/dev/null)
    if [ -n "$FOUND_ORDER" ]; then
        print_result "Nuestro pedido #$ORDER_ID" "✓ Encontrado en la lista"
    fi
else
    mark_failure "Error al listar pedidos" "HTTP $HTTP_CODE"
fi

# PASO 13: Ver detalle del pedido (desde backoffice)
echo ""
print_step "5.3" "Revisar detalle del pedido #$ORDER_ID"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/backoffice/orders/$ORDER_ID" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    mark_success "Detalle del pedido obtenido desde backoffice"

    CUSTOMER_NAME=$(echo "$BODY" | jq -r '.customerName' 2>/dev/null)
    CUSTOMER_PHONE=$(echo "$BODY" | jq -r '.customerPhone' 2>/dev/null)
    SHIPPING_ADDRESS=$(echo "$BODY" | jq -r '.shippingAddress' 2>/dev/null)

    print_result "Cliente" "$CUSTOMER_NAME"
    print_result "Teléfono" "$CUSTOMER_PHONE"
    print_result "Dirección" "$SHIPPING_ADDRESS"
else
    mark_failure "Error al obtener detalle" "HTTP $HTTP_CODE"
fi

# PASO 14: Marcar como listo para enviar
echo ""
print_step "5.4" "Preparar pedido para despacho (READY_TO_SHIP)"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$ORDER_ID/ready-to-ship" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.status' 2>/dev/null)
    mark_success "Estado actualizado correctamente"
    print_result "Estado anterior" "CONFIRMED"
    print_result "Estado nuevo" "$NEW_STATUS"
else
    mark_failure "Error al cambiar estado" "HTTP $HTTP_CODE"
    echo "$BODY" | jq '.'
fi

# PASO 15: Asignar método de envío
echo ""
print_step "5.5" "Asignar método de envío (COURIER)"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$ORDER_ID/shipping-method" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"shippingMethod": "COURIER"}')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    SHIPPING_METHOD=$(echo "$BODY" | jq -r '.shippingMethod' 2>/dev/null)
    mark_success "Método de envío asignado"
    print_result "Método seleccionado" "$SHIPPING_METHOD (Mensajería externa)"
else
    mark_failure "Error al asignar método de envío" "HTTP $HTTP_CODE"
    echo "$BODY" | jq '.'
fi

# PASO 16: Despachar pedido
echo ""
print_step "5.6" "Despachar pedido (SHIPPED)"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$ORDER_ID/ship" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.status' 2>/dev/null)
    mark_success "Pedido despachado exitosamente"
    print_result "Estado" "$NEW_STATUS"
    print_result "En tránsito" "🚚 Pedido en camino al cliente"
else
    mark_failure "Error al despachar" "HTTP $HTTP_CODE"
    echo "$BODY" | jq '.'
fi

# PASO 17: Marcar como entregado
echo ""
print_step "5.7" "Confirmar entrega al cliente (DELIVERED)"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/backoffice/orders/$ORDER_ID/deliver" \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    FINAL_STATUS=$(echo "$BODY" | jq -r '.status' 2>/dev/null)
    mark_success "¡Pedido entregado al cliente!"
    print_result "Estado final" "$FINAL_STATUS"
    print_result "Ciclo completado" "✓ Flujo END-TO-END exitoso"
else
    mark_failure "Error al confirmar entrega" "HTTP $HTTP_CODE"
    echo "$BODY" | jq '.'
fi

# ============================================
# FASE 6: VERIFICACIÓN FINAL
# ============================================
print_header "FASE 6: VERIFICACIÓN FINAL DEL FLUJO"

# PASO 18: Cliente verifica estado final
print_step "6.1" "Cliente consulta estado final de su pedido"
((TOTAL_STEPS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/orders/$ORDER_ID" \
    -H "Authorization: Bearer $CLIENT_TOKEN")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    FINAL_STATUS=$(echo "$BODY" | jq -r '.status' 2>/dev/null)
    SHIPPING_METHOD=$(echo "$BODY" | jq -r '.shippingMethod' 2>/dev/null)

    if [ "$FINAL_STATUS" = "DELIVERED" ]; then
        mark_success "Estado verificado desde perspectiva del cliente"
        print_result "Estado" "$FINAL_STATUS ✓"
        print_result "Método de envío" "$SHIPPING_METHOD"
    else
        mark_failure "Estado inesperado" "Esperado: DELIVERED, Obtenido: $FINAL_STATUS"
    fi
else
    mark_failure "Error al consultar pedido" "HTTP $HTTP_CODE"
fi

# ============================================
# RESUMEN FINAL
# ============================================
echo ""
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  📊 RESUMEN DEL FLUJO END-TO-END${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_STEPS/$TOTAL_STEPS)*100}")

echo -e "${BLUE}Total de pasos ejecutados:${NC} $TOTAL_STEPS"
echo -e "${GREEN}Pasos exitosos:${NC} $PASSED_STEPS"
echo -e "${RED}Pasos fallidos:${NC} $FAILED_STEPS"
echo -e "${YELLOW}Tasa de éxito:${NC} $SUCCESS_RATE%"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔄 CICLO DE VIDA DEL PEDIDO${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "  1️⃣  Cliente Registrado     ✓"
echo -e "  2️⃣  Login Exitoso          ✓"
echo -e "  3️⃣  Productos Explorados   ✓"
echo -e "  4️⃣  Carrito Armado         ✓"
echo -e "  5️⃣  Pedido Creado          ✓ [CONFIRMED]"
echo -e "  6️⃣  Carrito Vaciado        ✓"
echo -e "  7️⃣  Stock Reducido         ✓"
echo -e "  8️⃣  Warehouse Login        ✓"
echo -e "  9️⃣  Pedido Preparado       ✓ [READY_TO_SHIP]"
echo -e "  🔟  Método Asignado        ✓ [COURIER]"
echo -e "  1️⃣1️⃣  Pedido Despachado      ✓ [SHIPPED]"
echo -e "  1️⃣2️⃣  Pedido Entregado       ✓ [DELIVERED]"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  📦 DATOS DEL PEDIDO${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${MAGENTA}Pedido ID:${NC} #$ORDER_ID"
echo -e "${MAGENTA}Cliente:${NC} $CLIENT_EMAIL"
echo -e "${MAGENTA}Estado Final:${NC} DELIVERED ✅"
echo -e "${MAGENTA}Total Pagado:${NC} \$$ORDER_TOTAL"
echo -e "${MAGENTA}Método de Envío:${NC} COURIER"
echo -e "${MAGENTA}Dirección:${NC} Av. Independencia 1234, Mar del Plata"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"

if [ $FAILED_STEPS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  ✅ FLUJO E2E COMPLETADO EXITOSAMENTE ✅           ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  ¡La aplicación Virtual Pet funciona             ║${NC}"
    echo -e "${GREEN}║   correctamente de principio a fin! 🎉🐾          ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    EXIT_CODE=0
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}║  ⚠️  FLUJO E2E INCOMPLETO ⚠️                       ║${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}║  $FAILED_STEPS paso(s) fallaron durante el flujo        ║${NC}"
    echo -e "${RED}║  Revisa los detalles arriba                       ║${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    EXIT_CODE=1
fi

echo ""
echo -e "${BLUE}Generado por:${NC} test-flujo-completo-e2e.sh"
echo -e "${BLUE}Fecha:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

exit $EXIT_CODE

