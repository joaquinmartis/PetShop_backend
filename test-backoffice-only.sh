#!/bin/bash

# Script para probar SOLO los endpoints de BACKOFFICE
# Asegúrate de haber ejecutado: UPDATE user_management.users SET role_id = (SELECT id FROM user_management.roles WHERE name = 'WAREHOUSE') WHERE email = 'prueba@test.com';

BASE_URL="http://localhost:8080/api"

echo "=========================================="
echo "PRUEBAS DE BACKOFFICE - ORDER MANAGEMENT"
echo "=========================================="
echo ""

# Verificar aplicación
echo "🔍 Verificando aplicación..."
if ! curl -s -f "${BASE_URL}/categories" > /dev/null 2>&1; then
    echo "❌ ERROR: La aplicación no está corriendo"
    echo ""
    echo "⚠️  IMPORTANTE: Si cambiaste el rol en la BD, debes:"
    echo "   1. Detener la aplicación (Ctrl+C)"
    echo "   2. Volver a arrancarla: ./mvnw spring-boot:run"
    echo "   3. Ejecutar este script nuevamente"
    exit 1
fi
echo "✅ Aplicación corriendo"
echo ""

# Login como WAREHOUSE (debe ser login NUEVO después de cambiar el rol)
echo "🔐 Login como WAREHOUSE (usuario: prueba@test.com)..."
echo ""

LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "prueba@test.com",
    "password": "password123"
  }')

echo "Respuesta del login:"
echo "$LOGIN_RESPONSE"
echo ""

# Verificar el rol en la respuesta
ROLE=$(echo "$LOGIN_RESPONSE" | grep -o '"role":"[^"]*"' | sed 's/"role":"//;s/"$//')
echo "Rol detectado: $ROLE"

if [ "$ROLE" != "WAREHOUSE" ]; then
    echo ""
    echo "❌ ERROR: El usuario NO tiene rol WAREHOUSE"
    echo ""
    echo "Soluciones posibles:"
    echo ""
    echo "1. Verificar que ejecutaste el UPDATE en PostgreSQL:"
    echo "   UPDATE user_management.users"
    echo "   SET role_id = (SELECT id FROM user_management.roles WHERE name = 'WAREHOUSE')"
    echo "   WHERE email = 'prueba@test.com';"
    echo ""
    echo "2. REINICIAR la aplicación Spring Boot:"
    echo "   - Detener con Ctrl+C"
    echo "   - Arrancar: ./mvnw spring-boot:run"
    echo ""
    echo "3. Verificar en la BD que el cambio se guardó:"
    echo "   SELECT email, (SELECT name FROM user_management.roles WHERE id = role_id) as role"
    echo "   FROM user_management.users WHERE email = 'prueba@test.com';"
    exit 1
fi

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | sed 's/"accessToken":"//;s/"$//')

if [ -z "$TOKEN" ]; then
    echo "❌ ERROR: No se pudo obtener token"
    exit 1
fi

echo "✅ Token de WAREHOUSE obtenido correctamente"
echo ""
sleep 1

# Crear un pedido primero (necesario para probar backoffice)
echo "🛒 Preparando datos de prueba..."

# Login como cliente para crear pedido
CLIENT_LOGIN=$(curl -s -X POST "${BASE_URL}/users/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "cliente-temp@test.com",
    "password": "password123",
    "firstName": "Cliente",
    "lastName": "Temporal",
    "phone": "123456789",
    "address": "Calle Test 123"
  }')

CLIENT_TOKEN=$(curl -s -X POST "${BASE_URL}/users/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"cliente-temp@test.com","password":"password123"}' | grep -o '"accessToken":"[^"]*"' | sed 's/"accessToken":"//;s/"$//')

if [ -z "$CLIENT_TOKEN" ]; then
    # Intentar con usuario existente
    CLIENT_TOKEN=$(curl -s -X POST "${BASE_URL}/users/login" \
      -H "Content-Type: application/json" \
      -d '{"email":"cliente@test.com","password":"password123"}' | grep -o '"accessToken":"[^"]*"' | sed 's/"accessToken":"//;s/"$//')
fi

# Agregar productos al carrito
curl -s -X DELETE "${BASE_URL}/cart/clear" -H "Authorization: Bearer ${CLIENT_TOKEN}" > /dev/null
curl -s -X POST "${BASE_URL}/cart/items" \
  -H "Authorization: Bearer ${CLIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"productId": 1, "quantity": 1}' > /dev/null

# Crear pedido
ORDER=$(curl -s -X POST "${BASE_URL}/orders" \
  -H "Authorization: Bearer ${CLIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"shippingAddress": "Test Backoffice"}')

ORDER_ID=$(echo "$ORDER" | grep -o '"id":[0-9]*' | head -1 | sed 's/"id"://')

if [ -z "$ORDER_ID" ]; then
    echo "⚠️  No se pudo crear pedido de prueba, usando ID existente"
    ORDER_ID=1
else
    echo "✅ Pedido de prueba creado con ID: $ORDER_ID"
fi
echo ""
sleep 1

# ============================================
# PRUEBAS DE BACKOFFICE
# ============================================

echo "=========================================="
echo "INICIANDO PRUEBAS DE BACKOFFICE"
echo "=========================================="
echo ""

# TEST 1: Listar todos los pedidos
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 1: GET /api/backoffice/orders"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ALL_ORDERS=$(curl -s -X GET "${BASE_URL}/backoffice/orders?page=0&size=5" \
  -H "Authorization: Bearer ${TOKEN}")

echo "$ALL_ORDERS" | head -30

if echo "$ALL_ORDERS" | grep -q '"totalElements"'; then
    TOTAL=$(echo "$ALL_ORDERS" | grep -o '"totalElements":[0-9]*' | sed 's/"totalElements"://')
    echo ""
    echo "✅ PASÓ: Se listaron $TOTAL pedidos"
else
    echo ""
    echo "❌ FALLÓ: No se pudo listar pedidos"
    echo "Respuesta completa:"
    echo "$ALL_ORDERS"
fi
echo ""
sleep 1

# TEST 2: Filtrar por estado
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 2: GET /api/backoffice/orders?status=CONFIRMED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
CONFIRMED=$(curl -s -X GET "${BASE_URL}/backoffice/orders?status=CONFIRMED&page=0&size=5" \
  -H "Authorization: Bearer ${TOKEN}")

echo "$CONFIRMED" | head -30

if echo "$CONFIRMED" | grep -q '"status":"CONFIRMED"'; then
    echo ""
    echo "✅ PASÓ: Filtrado por CONFIRMED funciona"
else
    echo ""
    echo "❌ FALLÓ: No se pudo filtrar por estado"
fi
echo ""
sleep 1

# TEST 3: Ver detalle de pedido
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 3: GET /api/backoffice/orders/${ORDER_ID}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
DETAIL=$(curl -s -X GET "${BASE_URL}/backoffice/orders/${ORDER_ID}" \
  -H "Authorization: Bearer ${TOKEN}")

echo "$DETAIL" | head -30

if echo "$DETAIL" | grep -q '"id":'${ORDER_ID}; then
    echo ""
    echo "✅ PASÓ: Detalle del pedido obtenido"
else
    echo ""
    echo "❌ FALLÓ: No se pudo obtener detalle"
fi
echo ""
sleep 1

# TEST 4: Marcar como listo para enviar
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 4: PATCH /api/backoffice/orders/${ORDER_ID}/ready-to-ship"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
READY=$(curl -s -X PATCH "${BASE_URL}/backoffice/orders/${ORDER_ID}/ready-to-ship" \
  -H "Authorization: Bearer ${TOKEN}")

echo "$READY" | head -30

if echo "$READY" | grep -q '"status":"READY_TO_SHIP"'; then
    echo ""
    echo "✅ PASÓ: Estado cambió a READY_TO_SHIP"
else
    echo ""
    echo "❌ FALLÓ: No se pudo cambiar el estado"
    echo "Respuesta:"
    echo "$READY"
fi
echo ""
sleep 1

# TEST 5: Asignar método de envío
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 5: PATCH /api/backoffice/orders/${ORDER_ID}/shipping-method"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SHIPPING=$(curl -s -X PATCH "${BASE_URL}/backoffice/orders/${ORDER_ID}/shipping-method" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"shippingMethod": "OWN_TEAM"}')

echo "$SHIPPING" | head -30

if echo "$SHIPPING" | grep -q '"shippingMethod":"OWN_TEAM"'; then
    echo ""
    echo "✅ PASÓ: Método de envío asignado"
else
    echo ""
    echo "⚠️  Puede fallar si el pedido no está en estado correcto"
fi
echo ""
sleep 1

# TEST 6: Marcar como despachado
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 6: PATCH /api/backoffice/orders/${ORDER_ID}/ship"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SHIPPED=$(curl -s -X PATCH "${BASE_URL}/backoffice/orders/${ORDER_ID}/ship" \
  -H "Authorization: Bearer ${TOKEN}")

echo "$SHIPPED" | head -30

if echo "$SHIPPED" | grep -q '"status":"SHIPPED"'; then
    echo ""
    echo "✅ PASÓ: Estado cambió a SHIPPED"
else
    echo ""
    echo "⚠️  Puede fallar si el pedido no está en estado READY_TO_SHIP"
fi
echo ""
sleep 1

# TEST 7: Marcar como entregado
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 7: PATCH /api/backoffice/orders/${ORDER_ID}/deliver"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
DELIVERED=$(curl -s -X PATCH "${BASE_URL}/backoffice/orders/${ORDER_ID}/deliver" \
  -H "Authorization: Bearer ${TOKEN}")

echo "$DELIVERED" | head -30

if echo "$DELIVERED" | grep -q '"status":"DELIVERED"'; then
    echo ""
    echo "✅ PASÓ: Estado cambió a DELIVERED"
else
    echo ""
    echo "⚠️  Puede fallar si el pedido no está en estado SHIPPED"
fi
echo ""

# Crear otro pedido para rechazar
echo "🛒 Creando pedido para probar rechazo..."
curl -s -X DELETE "${BASE_URL}/cart/clear" -H "Authorization: Bearer ${CLIENT_TOKEN}" > /dev/null
curl -s -X POST "${BASE_URL}/cart/items" \
  -H "Authorization: Bearer ${CLIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"productId": 2, "quantity": 1}' > /dev/null

ORDER2=$(curl -s -X POST "${BASE_URL}/orders" \
  -H "Authorization: Bearer ${CLIENT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"shippingAddress": "Test Reject"}')

ORDER2_ID=$(echo "$ORDER2" | grep -o '"id":[0-9]*' | head -1 | sed 's/"id"://')
echo "✅ Pedido para rechazar creado con ID: $ORDER2_ID"
echo ""

# TEST 8: Rechazar pedido
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 8: PATCH /api/backoffice/orders/${ORDER2_ID}/reject"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
REJECTED=$(curl -s -X PATCH "${BASE_URL}/backoffice/orders/${ORDER2_ID}/reject" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Producto descontinuado"}')

echo "$REJECTED" | head -30

if echo "$REJECTED" | grep -q '"status":"CANCELLED"' && echo "$REJECTED" | grep -q '"cancelledBy":"WAREHOUSE"'; then
    echo ""
    echo "✅ PASÓ: Pedido rechazado por WAREHOUSE"
else
    echo ""
    echo "❌ FALLÓ: No se pudo rechazar el pedido"
fi
echo ""

echo "=========================================="
echo "✅ PRUEBAS DE BACKOFFICE COMPLETADAS"
echo "=========================================="
echo ""
echo "Si todos los tests pasaron, el módulo está funcionando al 100%"
echo "Si alguno falló, revisa los mensajes de error arriba"

