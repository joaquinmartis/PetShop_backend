#!/bin/bash

# Script de prueba para el módulo Cart
# Virtual Pet E-commerce

BASE_URL="http://localhost:8080/api"

echo "======================================"
echo "PRUEBAS DEL MÓDULO CART"
echo "======================================"
echo ""

# Primero necesitamos un token JWT
echo "Paso 1: Login para obtener JWT"
echo "-----------------------------------"

LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "prueba@test.com",
    "password": "password123"
  }')

# Extraer token sin jq (usando grep y sed)
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | sed 's/"accessToken":"//;s/"$//')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
    echo "❌ ERROR: No se pudo obtener el token. Verifica que exista el usuario prueba@test.com"
    echo "Respuesta: $LOGIN_RESPONSE"
    echo ""
    echo "💡 Solución: Ejecuta este comando para crear el usuario:"
    echo "curl -X POST http://localhost:8080/api/users/register -H 'Content-Type: application/json' -d '{\"email\":\"prueba@test.com\",\"password\":\"password123\",\"firstName\":\"Usuario\",\"lastName\":\"Prueba\",\"phone\":\"2234567890\",\"address\":\"Calle Test 123\"}'"
    exit 1
fi

echo "✅ Token obtenido correctamente"
echo ""

# 1. GET /api/cart - Ver carrito (debería estar vacío)
echo "1️⃣ GET /api/cart - Ver carrito vacío"
echo "-----------------------------------"
curl -s -X GET "${BASE_URL}/cart" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'
echo ""

# 2. POST /api/cart/items - Agregar primer producto
echo "2️⃣ POST /api/cart/items - Agregar producto ID 1 (cantidad: 2)"
echo "-----------------------------------"
curl -s -X POST "${BASE_URL}/cart/items" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": 1,
    "quantity": 2
  }' | jq '.'
echo ""

# 3. POST /api/cart/items - Agregar segundo producto
echo "3️⃣ POST /api/cart/items - Agregar producto ID 3 (cantidad: 1)"
echo "-----------------------------------"
curl -s -X POST "${BASE_URL}/cart/items" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": 3,
    "quantity": 1
  }' | jq '.'
echo ""

# 4. POST /api/cart/items - Agregar más del mismo producto
echo "4️⃣ POST /api/cart/items - Agregar más del producto ID 1 (cantidad: 1)"
echo "-----------------------------------"
curl -s -X POST "${BASE_URL}/cart/items" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": 1,
    "quantity": 1
  }' | jq '.'
echo ""

# 5. GET /api/cart - Ver carrito con productos
echo "5️⃣ GET /api/cart - Ver carrito con productos"
echo "-----------------------------------"
curl -s -X GET "${BASE_URL}/cart" \
  -H "Authorization: Bearer ${TOKEN}" | jq '{totalItems, totalAmount, items: .items | map({productName, quantity, unitPrice, subtotal})}'
echo ""

# 6. PATCH /api/cart/items/{productId} - Actualizar cantidad
echo "6️⃣ PATCH /api/cart/items/1 - Actualizar cantidad a 5"
echo "-----------------------------------"
curl -s -X PATCH "${BASE_URL}/cart/items/1" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 5
  }' | jq '{totalItems, totalAmount, items: .items | map({productName, quantity, subtotal})}'
echo ""

# 7. DELETE /api/cart/items/{productId} - Eliminar un producto
echo "7️⃣ DELETE /api/cart/items/3 - Eliminar producto ID 3"
echo "-----------------------------------"
curl -s -X DELETE "${BASE_URL}/cart/items/3" \
  -H "Authorization: Bearer ${TOKEN}" | jq '{totalItems, totalAmount, items: .items | map({productName, quantity})}'
echo ""

# 8. Intentar agregar con stock insuficiente
echo "8️⃣ POST /api/cart/items - Intentar agregar cantidad mayor al stock"
echo "-----------------------------------"
curl -s -X POST "${BASE_URL}/cart/items" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "productId": 4,
    "quantity": 9999
  }' | jq '.'
echo ""

# 9. DELETE /api/cart/clear - Vaciar carrito
echo "9️⃣ DELETE /api/cart/clear - Vaciar carrito completo"
echo "-----------------------------------"
curl -s -X DELETE "${BASE_URL}/cart/clear" \
  -H "Authorization: Bearer ${TOKEN}" | jq '.'
echo ""

# 10. GET /api/cart - Verificar que el carrito esté vacío
echo "🔟 GET /api/cart - Verificar carrito vacío"
echo "-----------------------------------"
curl -s -X GET "${BASE_URL}/cart" \
  -H "Authorization: Bearer ${TOKEN}" | jq '{totalItems, totalAmount, items: .items}'
echo ""

echo "======================================"
echo "✅ PRUEBAS COMPLETADAS"
echo "======================================"

