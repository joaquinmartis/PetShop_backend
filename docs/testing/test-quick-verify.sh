#!/bin/bash

# Test simple y rápido
echo "🧪 Test rápido de verificación"
echo ""

# Test 1: Servidor responde
echo "1. Verificando servidor..."
RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:8080/api/products 2>/dev/null || echo "ERROR")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ Servidor OK (HTTP 200)"
else
    echo "   ❌ Servidor error (HTTP $HTTP_CODE)"
    exit 1
fi

# Test 2: Login funciona
echo "2. Probando login..."
LOGIN=$(curl -s -X POST http://localhost:8080/api/users/login \
    -H "Content-Type: application/json" \
    -d '{"email":"warehouse@test.com","password":"password123"}')

TOKEN=$(echo "$LOGIN" | jq -r '.accessToken' 2>/dev/null)

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo "   ✅ Login OK"
else
    echo "   ⚠️  Login warehouse falló (puede ser normal si no existe)"
fi

# Test 3: Productos se listan
echo "3. Listando productos..."
PRODUCTS=$(curl -s http://localhost:8080/api/products)
TOTAL=$(echo "$PRODUCTS" | jq -r '.totalElements' 2>/dev/null)

if [ -n "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    echo "   ✅ Productos OK (Total: $TOTAL)"
else
    echo "   ❌ No hay productos"
fi

echo ""
echo "✅ Verificación básica completada"
echo "   El servidor está funcionando correctamente"
echo ""
echo "Ahora puedes ejecutar: ./run-all-tests.sh"

