#!/bin/bash

# Script de prueba para el módulo Product Catalog
# Virtual Pet E-commerce

BASE_URL="http://localhost:8080/api"

echo "======================================"
echo "PRUEBAS DEL MÓDULO PRODUCT CATALOG"
echo "======================================"
echo ""

# 1. Listar todas las categorías
echo "1. GET /api/categories - Listar categorías"
curl -s -X GET "${BASE_URL}/categories" | jq '.'
echo ""
echo ""

# 2. Obtener detalle de una categoría
echo "2. GET /api/categories/1 - Detalle de categoría ID 1"
curl -s -X GET "${BASE_URL}/categories/1" | jq '.'
echo ""
echo ""

# 3. Listar todos los productos (primera página)
echo "3. GET /api/products - Listar productos (página 1, 5 items)"
curl -s -X GET "${BASE_URL}/products?page=0&size=5" | jq '.'
echo ""
echo ""

# 4. Obtener detalle de un producto
echo "4. GET /api/products/1 - Detalle de producto ID 1"
curl -s -X GET "${BASE_URL}/products/1" | jq '.'
echo ""
echo ""

# 5. Buscar productos por categoría
echo "5. GET /api/products?categoryId=1 - Productos de categoría 1"
curl -s -X GET "${BASE_URL}/products?categoryId=1&size=5" | jq '.'
echo ""
echo ""

# 6. Buscar productos por nombre
echo "6. GET /api/products?name=gato - Búsqueda por nombre"
curl -s -X GET "${BASE_URL}/products?name=gato" | jq '.'
echo ""
echo ""

# 7. Productos con stock disponible
echo "7. GET /api/products?inStock=true - Solo productos con stock"
curl -s -X GET "${BASE_URL}/products?inStock=true&size=5" | jq '.'
echo ""
echo ""

# 8. Productos de una categoría específica
echo "8. GET /api/categories/4/products - Productos de categoría 4"
curl -s -X GET "${BASE_URL}/categories/4/products?size=5" | jq '.'
echo ""
echo ""

# 9. Verificar disponibilidad de stock (check-availability)
echo "9. POST /api/products/check-availability - Verificar stock de productos"
curl -s -X POST "${BASE_URL}/products/check-availability" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"productId": 1, "quantity": 2},
      {"productId": 3, "quantity": 1},
      {"productId": 5, "quantity": 3}
    ]
  }' | jq '.'
echo ""
echo ""

# 10. Verificar disponibilidad con stock insuficiente
echo "10. POST /api/products/check-availability - Con stock insuficiente"
curl -s -X POST "${BASE_URL}/products/check-availability" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"productId": 1, "quantity": 999},
      {"productId": 3, "quantity": 1}
    ]
  }' | jq '.'
echo ""
echo ""

echo "======================================"
echo "PRUEBAS COMPLETADAS"
echo "======================================"

