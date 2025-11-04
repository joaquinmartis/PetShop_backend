#!/bin/bash

# Script simplificado para probar los 6 endpoints del módulo Product Catalog
# Ejecutar DESPUÉS de arrancar la aplicación: ./mvnw spring-boot:run

BASE_URL="http://localhost:8080/api"

echo "======================================"
echo "PRUEBA DE 6 ENDPOINTS - PRODUCT CATALOG"
echo "======================================"
echo ""

# Verificar que la aplicación esté corriendo
echo "Verificando conexión con la aplicación..."
if ! curl -s -f "${BASE_URL}/categories" > /dev/null 2>&1; then
    echo "❌ ERROR: La aplicación no está corriendo en ${BASE_URL}"
    echo "Por favor, arranca la aplicación primero con: ./mvnw spring-boot:run"
    exit 1
fi
echo "✅ Aplicación corriendo correctamente"
echo ""

# 1️⃣ GET /api/categories
echo "1️⃣ GET /api/categories"
echo "-----------------------------------"
curl -s -X GET "${BASE_URL}/categories" | jq -r '.[] | "\(.id). \(.name)"'
echo ""

# 2️⃣ GET /api/categories/1
echo "2️⃣ GET /api/categories/1"
echo "-----------------------------------"
curl -s -X GET "${BASE_URL}/categories/1" | jq '.'
echo ""

# 3️⃣ GET /api/categories/1/products
echo "3️⃣ GET /api/categories/1/products"
echo "-----------------------------------"
curl -s -X GET "${BASE_URL}/categories/1/products?size=3" | jq '.content[] | {id, name, price, stock}'
echo ""

# 4️⃣ GET /api/products
echo "4️⃣ GET /api/products"
echo "-----------------------------------"
curl -s -X GET "${BASE_URL}/products?size=5" | jq '.content[] | {id, name, price, stock}'
echo ""

# 5️⃣ GET /api/products/1
echo "5️⃣ GET /api/products/1"
echo "-----------------------------------"
curl -s -X GET "${BASE_URL}/products/1" | jq '{id, name, price, stock, category: .category.name}'
echo ""

# 6️⃣ POST /api/products/check-availability
echo "6️⃣ POST /api/products/check-availability (Stock disponible)"
echo "-----------------------------------"
curl -s -X POST "${BASE_URL}/products/check-availability" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"productId": 1, "quantity": 2},
      {"productId": 3, "quantity": 1}
    ]
  }' | jq '.'
echo ""

echo "6️⃣ POST /api/products/check-availability (Stock insuficiente)"
echo "-----------------------------------"
curl -s -X POST "${BASE_URL}/products/check-availability" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"productId": 1, "quantity": 999}
    ]
  }' | jq '.'
echo ""

echo "======================================"
echo "✅ TODOS LOS 6 ENDPOINTS PROBADOS"
echo "======================================"

