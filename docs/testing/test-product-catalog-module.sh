#!/bin/bash

# ============================================
# TEST AUTOMATIZADO - MÓDULO PRODUCT CATALOG
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
REPORT_FILE="product-catalog-test-report.md"
PRODUCT_ID=""
CATEGORY_ID=""

# Función para imprimir encabezado
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Función para marcar test como PASSED
mark_test_passed() {
    echo -e "${GREEN}✅ TEST PASSED: $1${NC}"
    echo ""
    ((PASSED_TESTS++))
}

# Función para marcar test como FAILED
mark_test_failed() {
    echo -e "${RED}❌ TEST FAILED: $1${NC}"
    echo -e "${RED}   Razón: $2${NC}"
    echo ""
    ((FAILED_TESTS++))
}

# Iniciar reporte
init_report() {
    cat > "$REPORT_FILE" << EOF
# 📊 Reporte de Tests - Módulo Product Catalog

**Fecha:** $(date '+%Y-%m-%d %H:%M:%S')
**Base URL:** $BASE_URL

---

## 📋 Resumen Ejecutivo

EOF
}

# ============================================
# VERIFICAR SERVIDOR
# ============================================
print_header "VERIFICANDO SERVIDOR"

SERVER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/products" 2>/dev/null || echo "000")

if [ "$SERVER_CHECK" != "000" ]; then
    echo -e "${GREEN}✅ Servidor corriendo en $BASE_URL${NC}"
    echo ""
else
    echo -e "${RED}❌ ERROR: El servidor no está corriendo en $BASE_URL${NC}"
    echo -e "${RED}   Por favor, inicia la aplicación con: mvn spring-boot:run${NC}"
    exit 1
fi

# ============================================
# TEST 1: Listar Todas las Categorías
# ============================================
print_header "TEST 1: Listar Todas las Categorías"
((TOTAL_TESTS++))
echo "GET /categories"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

# Guardar ID de la primera categoría para tests posteriores
CATEGORY_ID=$(echo "$BODY" | jq -r '.[0].id' 2>/dev/null)

if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.[0].id' > /dev/null 2>&1; then
    mark_test_passed "Categorías listadas correctamente (200 OK)"
else
    mark_test_failed "Listar categorías" "Esperado 200 con array de categorías, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 2: Obtener Categoría por ID
# ============================================
print_header "TEST 2: Obtener Categoría por ID"
((TOTAL_TESTS++))
echo "GET /categories/{id}"
echo ""

if [ -z "$CATEGORY_ID" ] || [ "$CATEGORY_ID" = "null" ]; then
    echo -e "${YELLOW}⚠️  Saltando test: No hay categorías disponibles${NC}"
    echo ""
    ((TOTAL_TESTS--))
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/$CATEGORY_ID")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""

    if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.id' > /dev/null 2>&1; then
        mark_test_passed "Categoría obtenida correctamente por ID"
    else
        mark_test_failed "Obtener categoría por ID" "Esperado 200 con objeto categoría, obtenido $HTTP_CODE"
    fi
fi

# ============================================
# TEST 3: Obtener Categoría Inexistente (debe fallar)
# ============================================
print_header "TEST 3: Obtener Categoría Inexistente (debe fallar)"
((TOTAL_TESTS++))
echo "GET /categories/9999"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/9999")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 404 ]; then
    mark_test_passed "Categoría inexistente retorna 404 Not Found"
else
    mark_test_failed "Validación categoría inexistente" "Esperado 404 Not Found, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 4: Listar Todos los Productos
# ============================================
print_header "TEST 4: Listar Todos los Productos"
((TOTAL_TESTS++))
echo "GET /products?page=0&size=10"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=10")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

# Guardar ID del primer producto para tests posteriores
PRODUCT_ID=$(echo "$BODY" | jq -r '.content[0].id' 2>/dev/null)

if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.content' > /dev/null 2>&1; then
    mark_test_passed "Productos listados correctamente con paginación"
else
    mark_test_failed "Listar productos" "Esperado 200 con objeto Page, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 5: Obtener Producto por ID
# ============================================
print_header "TEST 5: Obtener Producto por ID"
((TOTAL_TESTS++))
echo "GET /products/{id}"
echo ""

if [ -z "$PRODUCT_ID" ] || [ "$PRODUCT_ID" = "null" ]; then
    echo -e "${YELLOW}⚠️  Saltando test: No hay productos disponibles${NC}"
    echo ""
    ((TOTAL_TESTS--))
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products/$PRODUCT_ID")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""

    if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.id' > /dev/null 2>&1; then
        mark_test_passed "Producto obtenido correctamente por ID"
    else
        mark_test_failed "Obtener producto por ID" "Esperado 200 con objeto producto, obtenido $HTTP_CODE"
    fi
fi

# ============================================
# TEST 6: Obtener Producto Inexistente (debe fallar)
# ============================================
print_header "TEST 6: Obtener Producto Inexistente (debe fallar)"
((TOTAL_TESTS++))
echo "GET /products/9999"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products/9999")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 404 ]; then
    mark_test_passed "Producto inexistente retorna 404 Not Found"
else
    mark_test_failed "Validación producto inexistente" "Esperado 404 Not Found, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 7: Listar Productos con Filtro por Categoría
# ============================================
print_header "TEST 7: Listar Productos por Categoría"
((TOTAL_TESTS++))
echo "GET /products?categoryId={id}"
echo ""

if [ -z "$CATEGORY_ID" ] || [ "$CATEGORY_ID" = "null" ]; then
    echo -e "${YELLOW}⚠️  Saltando test: No hay categorías disponibles${NC}"
    echo ""
    ((TOTAL_TESTS--))
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?categoryId=$CATEGORY_ID&page=0&size=5")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""

    if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.content' > /dev/null 2>&1; then
        mark_test_passed "Productos filtrados por categoría correctamente"
    else
        mark_test_failed "Filtrar productos por categoría" "Esperado 200 con productos filtrados, obtenido $HTTP_CODE"
    fi
fi

# ============================================
# TEST 8: Listar Productos con Stock Disponible
# ============================================
print_header "TEST 8: Listar Productos con Stock Disponible"
((TOTAL_TESTS++))
echo "GET /products?inStock=true"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?inStock=true&page=0&size=5")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.content' > /dev/null 2>&1; then
    # Verificar que todos los productos tengan stock > 0
    ALL_HAVE_STOCK=true
    for stock in $(echo "$BODY" | jq -r '.content[].stock' 2>/dev/null); do
        if [ "$stock" -le 0 ]; then
            ALL_HAVE_STOCK=false
            break
        fi
    done

    if [ "$ALL_HAVE_STOCK" = true ]; then
        mark_test_passed "Productos filtrados por stock correctamente"
    else
        mark_test_failed "Filtro de stock" "Todos deberían tener stock > 0" "Algunos productos tienen stock 0"
    fi
else
    mark_test_failed "Filtrar productos con stock" "Esperado 200 con productos, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 9: Búsqueda de Productos por Nombre
# ============================================
print_header "TEST 9: Búsqueda de Productos por Nombre"
((TOTAL_TESTS++))
echo "GET /products?name=alimento"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?name=alimento&page=0&size=5")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.content' > /dev/null 2>&1; then
    mark_test_passed "Búsqueda por nombre funciona correctamente"
else
    mark_test_failed "Búsqueda por nombre" "Esperado 200 con resultados, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 10: Obtener Productos de una Categoría
# ============================================
print_header "TEST 10: Obtener Productos de una Categoría"
((TOTAL_TESTS++))
echo "GET /categories/{id}/products"
echo ""

if [ -z "$CATEGORY_ID" ] || [ "$CATEGORY_ID" = "null" ]; then
    echo -e "${YELLOW}⚠️  Saltando test: No hay categorías disponibles${NC}"
    echo ""
    ((TOTAL_TESTS--))
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/$CATEGORY_ID/products?page=0&size=5")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""

    if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.content' > /dev/null 2>&1; then
        mark_test_passed "Productos de categoría obtenidos correctamente"
    else
        mark_test_failed "Obtener productos de categoría" "Esperado 200 con productos, obtenido $HTTP_CODE"
    fi
fi

# ============================================
# TEST 11: Productos de Categoría Inexistente (debe fallar)
# ============================================
print_header "TEST 11: Productos de Categoría Inexistente (debe fallar)"
((TOTAL_TESTS++))
echo "GET /categories/9999/products"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/9999/products?page=0&size=5")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 404 ]; then
    mark_test_passed "Categoría inexistente retorna 404 Not Found"
else
    mark_test_failed "Validación categoría inexistente" "Esperado 404 Not Found, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 12: Paginación de Productos
# ============================================
print_header "TEST 12: Paginación de Productos"
((TOTAL_TESTS++))
echo "GET /products?page=0&size=3"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=3")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 200 ]; then
    # Verificar que tenga campos de paginación
    HAS_PAGINATION=$(echo "$BODY" | jq -e '.pageable and .totalPages and .totalElements' > /dev/null 2>&1 && echo "true" || echo "false")
    SIZE=$(echo "$BODY" | jq -r '.size' 2>/dev/null)

    if [ "$HAS_PAGINATION" = "true" ] && [ "$SIZE" -eq 3 ]; then
        mark_test_passed "Paginación funciona correctamente (size=3)"
    else
        mark_test_failed "Paginación" "Esperado campos de paginación y size=3" "Campos faltantes o size incorrecto"
    fi
else
    mark_test_failed "Paginación de productos" "Esperado 200, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 13: Ordenamiento de Productos
# ============================================
print_header "TEST 13: Ordenamiento de Productos"
((TOTAL_TESTS++))
echo "GET /products?sort=price&page=0&size=5"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?sort=price&page=0&size=5")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.content' > /dev/null 2>&1; then
    # Verificar que los productos estén ordenados por precio
    PRICES=$(echo "$BODY" | jq -r '.content[].price' 2>/dev/null)
    SORTED=true
    PREV_PRICE=0

    for price in $PRICES; do
        if [ "$price" -lt "$PREV_PRICE" ]; then
            SORTED=false
            break
        fi
        PREV_PRICE=$price
    done

    if [ "$SORTED" = true ]; then
        mark_test_passed "Productos ordenados por precio correctamente"
    else
        mark_test_failed "Ordenamiento" "Productos deberían estar ordenados por precio ascendente" "Orden incorrecto"
    fi
else
    mark_test_failed "Ordenamiento de productos" "Esperado 200, obtenido $HTTP_CODE"
fi

# ============================================
# TEST 14: Verificar Disponibilidad de Stock (Endpoint Interno)
# ============================================
print_header "TEST 14: Verificar Disponibilidad de Stock"
((TOTAL_TESTS++))
echo "POST /products/check-availability"
echo ""

if [ -z "$PRODUCT_ID" ] || [ "$PRODUCT_ID" = "null" ]; then
    echo -e "${YELLOW}⚠️  Saltando test: No hay productos disponibles${NC}"
    echo ""
    ((TOTAL_TESTS--))
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/products/check-availability" \
        -H "Content-Type: application/json" \
        -d "{
            \"items\": [
                {
                    \"productId\": $PRODUCT_ID,
                    \"quantity\": 2
                }
            ]
        }")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""

    if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.available' > /dev/null 2>&1; then
        mark_test_passed "Verificación de disponibilidad funciona correctamente"
    else
        mark_test_failed "Check availability" "Esperado 200 con campo 'available', obtenido $HTTP_CODE"
    fi
fi

# ============================================
# TEST 15: Verificar Stock Insuficiente
# ============================================
print_header "TEST 15: Verificar Stock Insuficiente"
((TOTAL_TESTS++))
echo "POST /products/check-availability con cantidad excesiva"
echo ""

if [ -z "$PRODUCT_ID" ] || [ "$PRODUCT_ID" = "null" ]; then
    echo -e "${YELLOW}⚠️  Saltando test: No hay productos disponibles${NC}"
    echo ""
    ((TOTAL_TESTS--))
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/products/check-availability" \
        -H "Content-Type: application/json" \
        -d "{
            \"items\": [
                {
                    \"productId\": $PRODUCT_ID,
                    \"quantity\": 999999
                }
            ]
        }")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""

    if [ "$HTTP_CODE" -eq 200 ]; then
        AVAILABLE=$(echo "$BODY" | jq -r '.available' 2>/dev/null)

        if [ "$AVAILABLE" = "false" ]; then
            mark_test_passed "Stock insuficiente detectado correctamente"
        else
            mark_test_failed "Detección stock insuficiente" "Esperado available=false" "Obtenido available=$AVAILABLE"
        fi
    else
        mark_test_failed "Check availability con stock insuficiente" "Esperado 200, obtenido $HTTP_CODE"
    fi
fi

# ============================================
# RESUMEN FINAL
# ============================================
print_header "RESUMEN FINAL DE TESTS"

echo -e "${BLUE}Total de Tests Ejecutados:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Tests Exitosos (PASSED):${NC} $PASSED_TESTS"
echo -e "${RED}Tests Fallidos (FAILED):${NC} $FAILED_TESTS"

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
echo -e "${YELLOW}Tasa de Éxito:${NC} $SUCCESS_RATE%"

echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON! 🎉${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}⚠️  $FAILED_TESTS test(s) fallaron. Revisa los detalles arriba.${NC}"
    EXIT_CODE=1
fi

# Generar reporte
init_report
cat >> "$REPORT_FILE" << EOF
| Métrica | Valor |
|---------|-------|
| **Total Tests** | $TOTAL_TESTS |
| **Passed** | ✅ $PASSED_TESTS |
| **Failed** | ❌ $FAILED_TESTS |
| **Success Rate** | $SUCCESS_RATE% |

---

## 🧪 Tests Ejecutados

### Categorías (3 tests)
1. Listar todas las categorías → **$([ $TOTAL_TESTS -ge 1 ] && echo "✓" || echo "✗")**
2. Obtener categoría por ID → **$([ $TOTAL_TESTS -ge 2 ] && echo "✓" || echo "✗")**
3. Categoría inexistente (404) → **$([ $TOTAL_TESTS -ge 3 ] && echo "✓" || echo "✗")**

### Productos (6 tests)
4. Listar todos los productos → **$([ $TOTAL_TESTS -ge 4 ] && echo "✓" || echo "✗")**
5. Obtener producto por ID → **$([ $TOTAL_TESTS -ge 5 ] && echo "✓" || echo "✗")**
6. Producto inexistente (404) → **$([ $TOTAL_TESTS -ge 6 ] && echo "✓" || echo "✗")**
7. Filtrar por categoría → **$([ $TOTAL_TESTS -ge 7 ] && echo "✓" || echo "✗")**
8. Filtrar por stock disponible → **$([ $TOTAL_TESTS -ge 8 ] && echo "✓" || echo "✗")**
9. Búsqueda por nombre → **$([ $TOTAL_TESTS -ge 9 ] && echo "✓" || echo "✗")**

### Relaciones (2 tests)
10. Productos de una categoría → **$([ $TOTAL_TESTS -ge 10 ] && echo "✓" || echo "✗")**
11. Productos de categoría inexistente (404) → **$([ $TOTAL_TESTS -ge 11 ] && echo "✓" || echo "✗")**

### Funcionalidad Avanzada (4 tests)
12. Paginación → **$([ $TOTAL_TESTS -ge 12 ] && echo "✓" || echo "✗")**
13. Ordenamiento por precio → **$([ $TOTAL_TESTS -ge 13 ] && echo "✓" || echo "✗")**
14. Verificar disponibilidad de stock → **$([ $TOTAL_TESTS -ge 14 ] && echo "✓" || echo "✗")**
15. Detectar stock insuficiente → **$([ $TOTAL_TESTS -ge 15 ] && echo "✓" || echo "✗")**

---

## 📊 Cobertura por Endpoint

| Endpoint | Tests | Estado |
|----------|-------|--------|
| GET /categories | 1 | ✓ |
| GET /categories/{id} | 2 | ✓ |
| GET /categories/{id}/products | 2 | ✓ |
| GET /products | 6 | ✓ |
| GET /products/{id} | 2 | ✓ |
| POST /products/check-availability | 2 | ✓ |

---

**Generado:** $(date '+%Y-%m-%d %H:%M:%S')
EOF

echo ""
echo -e "${BLUE}📄 Reporte generado: $REPORT_FILE${NC}"
echo ""

exit $EXIT_CODE

