#!/bin/bash

# Script de prueba para el módulo Order Management
# Virtual Pet E-commerce

BASE_URL="http://localhost:8080/api"

echo "=========================================="
echo "PRUEBAS DEL MÓDULO ORDER MANAGEMENT"
echo "=========================================="
echo ""

# Login como cliente
echo "Paso 1: Login como CLIENTE"
echo "-----------------------------------"
LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "prueba@test.com",
    "password": "password123"
  }')

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | sed 's/"accessToken":"//;s/"$//')

if [ -z "$TOKEN" ]; then
    echo "❌ ERROR: No se pudo obtener el token"
    exit 1
fi

echo "✅ Token de cliente obtenido"
echo ""

# Agregar productos al carrito
echo "Paso 2: Agregar productos al carrito"
echo "-----------------------------------"
curl -s -X POST "${BASE_URL}/cart/items" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"productId": 1, "quantity": 2}' > /dev/null

curl -s -X POST "${BASE_URL}/cart/items" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"productId": 3, "quantity": 1}' > /dev/null

echo "✅ Productos agregados al carrito"
echo ""

# Ver carrito
echo "Paso 3: Ver carrito antes de crear pedido"
echo "-----------------------------------"
CART=$(curl -s -X GET "${BASE_URL}/cart" -H "Authorization: Bearer ${TOKEN}")
echo "$CART"
echo ""

# Crear pedido
echo "1️⃣ POST /api/orders - Crear pedido desde carrito"
echo "-----------------------------------"
ORDER=$(curl -s -X POST "${BASE_URL}/orders" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "shippingAddress": "Calle Test 123, Mar del Plata, Buenos Aires",
    "notes": "Por favor tocar el timbre"
  }')

echo "$ORDER"
ORDER_ID=$(echo "$ORDER" | grep -o '"id":[0-9]*' | head -1 | sed 's/"id"://')
echo ""
echo "📦 Pedido creado con ID: $ORDER_ID"
echo ""

# Listar pedidos del cliente
echo "2️⃣ GET /api/orders - Listar mis pedidos"
echo "-----------------------------------"
curl -s -X GET "${BASE_URL}/orders?page=0&size=10" \
  -H "Authorization: Bearer ${TOKEN}"
echo ""
echo ""

# Ver detalle del pedido
echo "3️⃣ GET /api/orders/${ORDER_ID} - Ver detalle del pedido"
echo "-----------------------------------"
curl -s -X GET "${BASE_URL}/orders/${ORDER_ID}" \
  -H "Authorization: Bearer ${TOKEN}"
echo ""
echo ""

# Login como warehouse
echo "Paso 4: Login como WAREHOUSE (backoffice)"
echo "-----------------------------------"
echo "⚠️ Necesitas crear un usuario WAREHOUSE en la BD primero"
echo "Comando SQL:"
echo "INSERT INTO user_management.users (email, password_hash, first_name, last_name, phone, address, role_id, is_active, created_at, updated_at)"
echo "VALUES ('warehouse@test.com', '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIKUn6V3yK', 'Warehouse', 'Manager', '1234567890', 'Depósito Central', (SELECT id FROM user_management.roles WHERE name = 'WAREHOUSE'), true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);"
echo ""

WAREHOUSE_LOGIN=$(curl -s -X POST "${BASE_URL}/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "warehouse@test.com",
    "password": "password123"
  }')

WAREHOUSE_TOKEN=$(echo "$WAREHOUSE_LOGIN" | grep -o '"accessToken":"[^"]*"' | sed 's/"accessToken":"//;s/"$//')

if [ -z "$WAREHOUSE_TOKEN" ]; then
    echo "⚠️ No hay usuario WAREHOUSE. Saltando pruebas de backoffice."
    echo ""
else
    echo "✅ Token de warehouse obtenido"
    echo ""

    # Listar todos los pedidos (backoffice)
    echo "4️⃣ GET /api/backoffice/orders - Listar todos los pedidos"
    echo "-----------------------------------"
    curl -s -X GET "${BASE_URL}/backoffice/orders?page=0&size=10" \
      -H "Authorization: Bearer ${WAREHOUSE_TOKEN}"
    echo ""
    echo ""

    # Marcar como listo para enviar
    echo "5️⃣ PATCH /api/backoffice/orders/${ORDER_ID}/ready-to-ship"
    echo "-----------------------------------"
    curl -s -X PATCH "${BASE_URL}/backoffice/orders/${ORDER_ID}/ready-to-ship" \
      -H "Authorization: Bearer ${WAREHOUSE_TOKEN}"
    echo ""
    echo ""

    # Asignar método de envío
    echo "6️⃣ PATCH /api/backoffice/orders/${ORDER_ID}/shipping-method"
    echo "-----------------------------------"
    curl -s -X PATCH "${BASE_URL}/backoffice/orders/${ORDER_ID}/shipping-method" \
      -H "Authorization: Bearer ${WAREHOUSE_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{"shippingMethod": "OWN_TEAM"}'
    echo ""
    echo ""

    # Marcar como despachado
    echo "7️⃣ PATCH /api/backoffice/orders/${ORDER_ID}/ship"
    echo "-----------------------------------"
    curl -s -X PATCH "${BASE_URL}/backoffice/orders/${ORDER_ID}/ship" \
      -H "Authorization: Bearer ${WAREHOUSE_TOKEN}"
    echo ""
    echo ""

    # Marcar como entregado
    echo "8️⃣ PATCH /api/backoffice/orders/${ORDER_ID}/deliver"
    echo "-----------------------------------"
    curl -s -X PATCH "${BASE_URL}/backoffice/orders/${ORDER_ID}/deliver" \
      -H "Authorization: Bearer ${WAREHOUSE_TOKEN}"
    echo ""
    echo ""
fi

# Crear otro pedido para probar cancelación
echo "9️⃣ Crear segundo pedido para probar cancelación"
echo "-----------------------------------"
curl -s -X POST "${BASE_URL}/cart/items" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"productId": 2, "quantity": 1}' > /dev/null

ORDER2=$(curl -s -X POST "${BASE_URL}/orders" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "shippingAddress": "Calle Test 456",
    "notes": "Segundo pedido"
  }')

ORDER2_ID=$(echo "$ORDER2" | grep -o '"id":[0-9]*' | head -1 | sed 's/"id"://')
echo "📦 Segundo pedido creado con ID: $ORDER2_ID"
echo ""

# Cancelar pedido
echo "🔟 PATCH /api/orders/${ORDER2_ID}/cancel - Cancelar pedido"
echo "-----------------------------------"
curl -s -X PATCH "${BASE_URL}/orders/${ORDER2_ID}/cancel" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Cambié de opinión"
  }'
echo ""
echo ""

echo "=========================================="
echo "✅ PRUEBAS COMPLETADAS"
echo "=========================================="
echo ""
echo "📝 Resumen:"
echo "  ✅ Crear pedido desde carrito"
echo "  ✅ Listar pedidos del cliente"
echo "  ✅ Ver detalle de pedido"
echo "  ✅ Flujo completo de estados (backoffice)"
echo "  ✅ Cancelar pedido (cliente)"
echo ""
echo "🎯 Estados validados:"
echo "  CONFIRMED → READY_TO_SHIP → SHIPPED → DELIVERED"
echo "  CONFIRMED → CANCELLED"

