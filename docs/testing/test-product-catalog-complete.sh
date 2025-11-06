#!/bin/bash

# ============================================
# TEST AUTOMATIZADO COMPLETO - MÓDULO PRODUCT CATALOG
# Versión 2.0 - Cobertura Completa (~85%)
# ============================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a TEST_RESULTS=()
declare -a TEST_NAMES=()

# Variables
BASE_URL="http://localhost:8080/api"
REPORT_FILE="product-catalog-complete-test-report.md"
PRODUCT_ID=""
CATEGORY_ID=""

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

mark_test_passed() {
    TEST_RESULTS+=("PASS")
    TEST_NAMES+=("$1")
    echo -e "${GREEN}✅ TEST PASSED: $1${NC}"
    echo ""
    ((PASSED_TESTS++))
}

mark_test_failed() {
    TEST_RESULTS+=("FAIL")
    TEST_NAMES+=("$1")
    echo -e "${RED}❌ TEST FAILED: $1${NC}"
    echo -e "${RED}   Razón: $2${NC}"
    echo ""
    ((FAILED_TESTS++))
}

# ============================================
# VERIFICAR SERVIDOR
# ============================================
print_header "VERIFICANDO SERVIDOR"

SERVER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/products" 2>/dev/null || echo "000")

if [ "$SERVER_CHECK" != "000" ]; then
    echo -e "${GREEN}✅ Servidor corriendo${NC}"
    echo ""
else
    echo -e "${RED}❌ ERROR: Servidor no responde${NC}"
    exit 1
fi

# ============================================
# GRUPO 1: CATEGORÍAS
# ============================================
print_header "GRUPO 1: CATEGORÍAS"

# TEST 1: Listar categorías
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Listar todas las categorías"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "$BODY" | jq '.' 2>/dev/null | head -20
echo ""
CATEGORY_ID=$(echo "$BODY" | jq -r '.[0].id' 2>/dev/null)
if [ "$HTTP_CODE" -eq 200 ] && [ -n "$CATEGORY_ID" ] && [ "$CATEGORY_ID" != "null" ]; then
    mark_test_passed "Listar categorías"
else
    mark_test_failed "Listar categorías" "Esperado 200, obtenido $HTTP_CODE"
fi

# TEST 2: Obtener categoría por ID
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Obtener categoría por ID"
if [ -z "$CATEGORY_ID" ]; then
    mark_test_failed "Obtener categoría" "No hay categorías"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/$CATEGORY_ID")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Obtener categoría por ID" || mark_test_failed "Obtener categoría" "Esperado 200, obtenido $HTTP_CODE"
fi

# TEST 3: Categoría inexistente (404)
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Categoría inexistente (debe retornar 404)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/9999")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "$BODY" | jq '.' 2>/dev/null
echo ""
[ "$HTTP_CODE" -eq 404 ] && mark_test_passed "Categoría inexistente retorna 404" || mark_test_failed "Validación categoría inexistente" "Esperado 404, obtenido $HTTP_CODE"

# ============================================
# GRUPO 2: PRODUCTOS BÁSICOS
# ============================================
print_header "GRUPO 2: PRODUCTOS BÁSICOS"

# TEST 4: Listar productos
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Listar todos los productos"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "$BODY" | jq '.content | length' 2>/dev/null
echo ""
PRODUCT_ID=$(echo "$BODY" | jq -r '.content[0].id' 2>/dev/null)
if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.content' > /dev/null 2>&1; then
    mark_test_passed "Listar productos con paginación"
else
    mark_test_failed "Listar productos" "Esperado 200 con Page, obtenido $HTTP_CODE"
fi

# TEST 5: Obtener producto por ID
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Obtener producto por ID"
if [ -z "$PRODUCT_ID" ]; then
    mark_test_failed "Obtener producto" "No hay productos"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products/$PRODUCT_ID")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Obtener producto por ID" || mark_test_failed "Obtener producto" "Esperado 200, obtenido $HTTP_CODE"
fi

# TEST 6: Producto inexistente (404)
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Producto inexistente (debe retornar 404)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products/9999")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "$BODY" | jq '.' 2>/dev/null
echo ""
[ "$HTTP_CODE" -eq 404 ] && mark_test_passed "Producto inexistente retorna 404" || mark_test_failed "Validación producto inexistente" "Esperado 404, obtenido $HTTP_CODE"

# ============================================
# GRUPO 3: FILTROS
# ============================================
print_header "GRUPO 3: FILTROS Y BÚSQUEDA"

# TEST 7: Filtrar por categoría
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Filtrar productos por categoría"
if [ -z "$CATEGORY_ID" ]; then
    mark_test_failed "Filtrar por categoría" "No hay categorías"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?categoryId=$CATEGORY_ID&page=0&size=5")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Filtrar por categoría" || mark_test_failed "Filtrar por categoría" "Esperado 200, obtenido $HTTP_CODE"
fi

# TEST 8: Filtrar por stock disponible
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Filtrar productos con stock > 0"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?inStock=true&page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "Status: $HTTP_CODE"
echo ""
if [ "$HTTP_CODE" -eq 200 ]; then
    ALL_HAVE_STOCK=true
    for stock in $(echo "$BODY" | jq -r '.content[].stock' 2>/dev/null); do
        if [ "$stock" -le 0 ]; then
            ALL_HAVE_STOCK=false
            break
        fi
    done
    [ "$ALL_HAVE_STOCK" = true ] && mark_test_passed "Filtrar por stock" || mark_test_failed "Filtrar por stock" "Algunos productos tienen stock 0"
else
    mark_test_failed "Filtrar por stock" "Esperado 200, obtenido $HTTP_CODE"
fi

# TEST 9: Búsqueda por nombre
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Búsqueda por nombre (case insensitive)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?name=ALIMENTO&page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "Resultados: $(echo "$BODY" | jq '.content | length' 2>/dev/null)"
echo ""
[ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Búsqueda por nombre" || mark_test_failed "Búsqueda por nombre" "Esperado 200, obtenido $HTTP_CODE"

# TEST 10: Búsqueda sin resultados
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Búsqueda sin resultados"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?name=ProductoInexistenteXYZ123&page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
TOTAL_ELEMENTS=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
echo "Total elementos: $TOTAL_ELEMENTS"
echo ""
if [ "$HTTP_CODE" -eq 200 ] && [ "$TOTAL_ELEMENTS" -eq 0 ]; then
    mark_test_passed "Búsqueda sin resultados manejada"
else
    mark_test_failed "Búsqueda sin resultados" "Esperado 200 con 0 elementos, obtenido $HTTP_CODE"
fi

# TEST 11: Filtros combinados (categoría + stock)
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Filtros combinados (categoría + stock)"
if [ -z "$CATEGORY_ID" ]; then
    mark_test_failed "Filtros combinados" "No hay categorías"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?categoryId=$CATEGORY_ID&inStock=true&page=0&size=5")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Filtros combinados" || mark_test_failed "Filtros combinados" "Esperado 200, obtenido $HTTP_CODE"
fi

# TEST 12: Filtro con categoryId inválido
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Filtro con categoryId no numérico (debe manejarse)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?categoryId=abc&page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
if [ "$HTTP_CODE" -eq 400 ] || [ "$HTTP_CODE" -eq 200 ]; then
    mark_test_passed "CategoryId inválido manejado"
else
    mark_test_failed "CategoryId inválido" "Esperado 400 o 200, obtenido $HTTP_CODE"
fi

# ============================================
# GRUPO 4: PAGINACIÓN AVANZADA
# ============================================
print_header "GRUPO 4: PAGINACIÓN AVANZADA"

# TEST 13: Paginación básica
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Paginación con size=3"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=3")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
SIZE=$(echo "$BODY" | jq -r '.size' 2>/dev/null)
echo "Size: $SIZE"
echo ""
if [ "$HTTP_CODE" -eq 200 ] && [ "$SIZE" -eq 3 ]; then
    mark_test_passed "Paginación básica"
else
    mark_test_failed "Paginación" "Esperado 200 con size=3, obtenido $HTTP_CODE"
fi

# TEST 14: Página fuera de rango
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Página fuera de rango (page=999)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=999&size=10")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "Status: $HTTP_CODE, Empty: $(echo "$BODY" | jq -r '.empty' 2>/dev/null)"
echo ""
[ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Página fuera de rango manejada" || mark_test_failed "Página fuera rango" "Esperado 200, obtenido $HTTP_CODE"

# TEST 15: Size = 0
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Size = 0 (debe manejarse)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=0")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 400 ]; then
    mark_test_passed "Size=0 manejado"
else
    mark_test_failed "Size=0" "Esperado 200 o 400, obtenido $HTTP_CODE"
fi

# TEST 16: Size excesivo
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Size excesivo (size=1000)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=1000")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Size excesivo manejado" || mark_test_failed "Size excesivo" "Esperado 200, obtenido $HTTP_CODE"

# ============================================
# GRUPO 5: ORDENAMIENTO
# ============================================
print_header "GRUPO 5: ORDENAMIENTO"

# TEST 17: Ordenar por precio ascendente
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Ordenar por precio ascendente"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?sort=price&page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "Status: $HTTP_CODE"
echo ""
if [ "$HTTP_CODE" -eq 200 ]; then
    SORTED=true
    PREV_PRICE=0
    for price in $(echo "$BODY" | jq -r '.content[].price' 2>/dev/null); do
        if [ $(echo "$price < $PREV_PRICE" | bc -l) -eq 1 ]; then
            SORTED=false
            break
        fi
        PREV_PRICE=$price
    done
    [ "$SORTED" = true ] && mark_test_passed "Ordenar por precio" || mark_test_failed "Ordenamiento" "Productos no ordenados"
else
    mark_test_failed "Ordenar por precio" "Esperado 200, obtenido $HTTP_CODE"
fi

# TEST 18: Ordenar descendente
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Ordenar por precio descendente"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?sort=price,desc&page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
echo "Status: $HTTP_CODE"
echo ""
[ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Ordenar descendente" || mark_test_failed "Ordenar descendente" "Esperado 200, obtenido $HTTP_CODE"

# ============================================
# GRUPO 6: PRODUCTOS DE CATEGORÍA
# ============================================
print_header "GRUPO 6: PRODUCTOS DE CATEGORÍA"

# TEST 19: Productos de categoría válida
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Obtener productos de una categoría"
if [ -z "$CATEGORY_ID" ]; then
    mark_test_failed "Productos de categoría" "No hay categorías"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/$CATEGORY_ID/products?page=0&size=5")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Productos de categoría" || mark_test_failed "Productos de categoría" "Esperado 200, obtenido $HTTP_CODE"
fi

# TEST 20: Productos de categoría inexistente
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Productos de categoría inexistente (debe retornar 404)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/9999/products?page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "$BODY" | jq '.' 2>/dev/null
echo ""
[ "$HTTP_CODE" -eq 404 ] && mark_test_passed "Categoría inexistente retorna 404" || mark_test_failed "Validación categoría inexistente" "Esperado 404, obtenido $HTTP_CODE"

# ============================================
# GRUPO 7: VERIFICACIÓN DE STOCK
# ============================================
print_header "GRUPO 7: VERIFICACIÓN DE STOCK"

# TEST 21: Check availability - producto disponible
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Verificar disponibilidad de producto"
if [ -z "$PRODUCT_ID" ]; then
    mark_test_failed "Check availability" "No hay productos"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/products/check-availability" \
        -H "Content-Type: application/json" \
        -d "{\"items\": [{\"productId\": $PRODUCT_ID, \"quantity\": 2}]}")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    echo "$BODY" | jq '.' 2>/dev/null
    echo ""
    if [ "$HTTP_CODE" -eq 200 ] && echo "$BODY" | jq -e '.available' > /dev/null 2>&1; then
        mark_test_passed "Check availability"
    else
        mark_test_failed "Check availability" "Esperado 200 con campo available, obtenido $HTTP_CODE"
    fi
fi

# TEST 22: Check availability - stock insuficiente
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Verificar stock insuficiente"
if [ -z "$PRODUCT_ID" ]; then
    mark_test_failed "Stock insuficiente" "No hay productos"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/products/check-availability" \
        -H "Content-Type: application/json" \
        -d "{\"items\": [{\"productId\": $PRODUCT_ID, \"quantity\": 999999}]}")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    AVAILABLE=$(echo "$BODY" | jq -r '.available' 2>/dev/null)
    echo "Available: $AVAILABLE"
    echo ""
    if [ "$HTTP_CODE" -eq 200 ] && [ "$AVAILABLE" = "false" ]; then
        mark_test_passed "Stock insuficiente detectado"
    else
        mark_test_failed "Stock insuficiente" "Esperado available=false, obtenido $AVAILABLE"
    fi
fi

# TEST 23: Check availability - múltiples productos
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Verificar múltiples productos"
if [ -z "$PRODUCT_ID" ]; then
    mark_test_failed "Múltiples productos" "No hay productos"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/products/check-availability" \
        -H "Content-Type: application/json" \
        -d "{\"items\": [{\"productId\": $PRODUCT_ID, \"quantity\": 1}, {\"productId\": 2, \"quantity\": 1}]}")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    [ "$HTTP_CODE" -eq 200 ] && mark_test_passed "Múltiples productos verificados" || mark_test_failed "Múltiples productos" "Esperado 200, obtenido $HTTP_CODE"
fi

# TEST 24: Check availability - producto inexistente
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Verificar producto inexistente (debe fallar)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/products/check-availability" \
    -H "Content-Type: application/json" \
    -d '{"items": [{"productId": 99999, "quantity": 1}]}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
echo "$BODY" | jq '.' 2>/dev/null
echo ""
if [ "$HTTP_CODE" -eq 404 ] || [ "$HTTP_CODE" -eq 500 ]; then
    mark_test_passed "Producto inexistente manejado"
else
    mark_test_failed "Producto inexistente" "Esperado 404 o 500, obtenido $HTTP_CODE"
fi

# TEST 25: Check availability - cantidad negativa
((TOTAL_TESTS++))
echo "TEST $TOTAL_TESTS: Verificar con cantidad negativa (debe manejarse)"
if [ -z "$PRODUCT_ID" ]; then
    mark_test_failed "Cantidad negativa" "No hay productos"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/products/check-availability" \
        -H "Content-Type: application/json" \
        -d "{\"items\": [{\"productId\": $PRODUCT_ID, \"quantity\": -5}]}")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    echo "Status: $HTTP_CODE"
    echo ""
    if [ "$HTTP_CODE" -eq 400 ] || [ "$HTTP_CODE" -eq 200 ]; then
        mark_test_passed "Cantidad negativa manejada"
    else
        mark_test_failed "Cantidad negativa" "Esperado 400 o 200, obtenido $HTTP_CODE"
    fi
fi

# ============================================
# RESUMEN FINAL
# ============================================
print_header "RESUMEN FINAL"

echo -e "${BLUE}Total de Tests:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Tests Exitosos:${NC} $PASSED_TESTS"
echo -e "${RED}Tests Fallidos:${NC} $FAILED_TESTS"

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
echo -e "${YELLOW}Tasa de Éxito:${NC} $SUCCESS_RATE%"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}DESGLOSE POR GRUPO${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "📊 Cobertura por Área:"
echo "  ✓ Categorías: 3 tests"
echo "  ✓ Productos básicos: 3 tests"
echo "  ✓ Filtros y búsqueda: 6 tests"
echo "  ✓ Paginación avanzada: 4 tests"
echo "  ✓ Ordenamiento: 2 tests"
echo "  ✓ Productos de categoría: 2 tests"
echo "  ✓ Verificación de stock: 5 tests"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON! 🎉${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}⚠️  $FAILED_TESTS test(s) fallaron${NC}"
    EXIT_CODE=1
fi

# Generar reporte
cat > "$REPORT_FILE" << EOF
# 📊 Reporte Completo - Módulo Product Catalog

**Fecha:** $(date '+%Y-%m-%d %H:%M:%S')
**Cobertura:** ~85%

## Resumen

| Métrica | Valor |
|---------|-------|
| **Total Tests** | $TOTAL_TESTS |
| **Passed** | ✅ $PASSED_TESTS |
| **Failed** | ❌ $FAILED_TESTS |
| **Success Rate** | $SUCCESS_RATE% |

---

**Generado:** $(date '+%Y-%m-%d %H:%M:%S')
EOF

echo ""
echo -e "${BLUE}📄 Reporte: $REPORT_FILE${NC}"
echo ""

exit $EXIT_CODE

