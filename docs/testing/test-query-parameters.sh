#!/bin/bash

# ============================================
# TEST: QUERY PARAMETERS Y FILTROS AVANZADOS
# Valida filtros, búsquedas y ordenamiento
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

BASE_URL="http://localhost:8080/api"

print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

mark_success() {
    echo -e "${GREEN}   ✅ $1${NC}"
    ((PASSED_TESTS++))
}

mark_failure() {
    echo -e "${RED}   ❌ $1${NC}"
    ((FAILED_TESTS++))
}

print_header "TEST: QUERY PARAMETERS Y FILTROS"

# ============================================
# FILTROS DE PRODUCTOS
# ============================================
print_header "1. FILTROS DE PRODUCTOS"

# Test 1: Filtro por categoría
((TOTAL_TESTS++))
echo "Test 1: Filtrar por categoría (categoryId=1)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?categoryId=1&page=0&size=10")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    # Verificar que todos tienen categoryId=1
    WRONG_CATEGORY=$(echo "$BODY" | jq '[.content[] | select(.category.id != 1)] | length' 2>/dev/null)
    if [ "$WRONG_CATEGORY" -eq 0 ]; then
        mark_success "Filtro por categoría funciona"
    else
        mark_failure "Filtro por categoría NO funciona ($WRONG_CATEGORY productos incorrectos)"
    fi
else
    mark_failure "Error al filtrar por categoría (HTTP $HTTP_CODE)"
fi

# Test 2: Filtro inStock=true
((TOTAL_TESTS++))
echo "Test 2: Filtrar solo productos con stock (inStock=true)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?inStock=true&page=0&size=10")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    WITHOUT_STOCK=$(echo "$BODY" | jq '[.content[] | select(.stock <= 0)] | length' 2>/dev/null)
    if [ "$WITHOUT_STOCK" -eq 0 ]; then
        mark_success "Filtro inStock funciona"
    else
        mark_failure "Filtro inStock NO funciona ($WITHOUT_STOCK sin stock)"
    fi
else
    mark_failure "Error al filtrar por stock (HTTP $HTTP_CODE)"
fi

# Test 3: Ordenamiento por precio ASC
((TOTAL_TESTS++))
echo "Test 3: Ordenar por precio ascendente (sort=price,asc)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=5&sort=price,asc")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    # Verificar orden ascendente
    PRICES=$(echo "$BODY" | jq '[.content[].price] | sort' 2>/dev/null)
    ACTUAL_PRICES=$(echo "$BODY" | jq '[.content[].price]' 2>/dev/null)

    if [ "$PRICES" == "$ACTUAL_PRICES" ]; then
        mark_success "Ordenamiento ASC funciona"
    else
        mark_failure "Ordenamiento ASC NO funciona correctamente"
    fi
else
    mark_failure "Error al ordenar (HTTP $HTTP_CODE)"
fi

# Test 4: Filtros combinados (category + inStock)
((TOTAL_TESTS++))
echo "Test 4: Filtros combinados (categoryId=1&inStock=true)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?categoryId=1&inStock=true&page=0&size=10")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    WRONG=$(echo "$BODY" | jq '[.content[] | select(.category.id != 1 or .stock <= 0)] | length' 2>/dev/null)
    if [ "$WRONG" -eq 0 ]; then
        mark_success "Filtros combinados funcionan"
    else
        mark_failure "Filtros combinados NO funcionan"
    fi
else
    mark_failure "Error en filtros combinados (HTTP $HTTP_CODE)"
fi

# ============================================
# PAGINACIÓN AVANZADA
# ============================================
print_header "2. PAGINACIÓN AVANZADA"

# Test 5: Página fuera de rango
((TOTAL_TESTS++))
echo "Test 5: Solicitar página que no existe (page=999)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=999&size=10")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    CONTENT_SIZE=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
    if [ "$CONTENT_SIZE" -eq 0 ]; then
        mark_success "Página vacía retornada correctamente"
    else
        mark_failure "Página fuera de rango retorna datos"
    fi
else
    mark_failure "Error al solicitar página fuera de rango (HTTP $HTTP_CODE)"
fi

# Test 6: Diferentes tamaños de página
((TOTAL_TESTS++))
echo "Test 6: Verificar size=2 retorna máximo 2 elementos"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=2")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    CONTENT_SIZE=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
    if [ "$CONTENT_SIZE" -le 2 ]; then
        mark_success "Size respetado (retorna $CONTENT_SIZE)"
    else
        mark_failure "Size NO respetado (retorna $CONTENT_SIZE)"
    fi
else
    mark_failure "Error en paginación (HTTP $HTTP_CODE)"
fi

# Test 7: Validar estructura Page completa
((TOTAL_TESTS++))
echo "Test 7: Validar estructura Page completa"
RESPONSE=$(curl -s -X GET "$BASE_URL/products?page=0&size=5")
BODY="$RESPONSE"

# Verificar campos obligatorios de Page
FIELDS=("content" "pageable" "totalElements" "totalPages" "size" "number" "first" "last")
ALL_PRESENT=true

for field in "${FIELDS[@]}"; do
    if ! echo "$BODY" | jq -e ".$field" > /dev/null 2>&1; then
        ALL_PRESENT=false
        echo -e "${RED}      Campo '$field' faltante${NC}"
    fi
done

if [ "$ALL_PRESENT" = true ]; then
    mark_success "Estructura Page completa"
else
    mark_failure "Estructura Page incompleta"
fi

# ============================================
# PRODUCTOS POR CATEGORÍA
# ============================================
print_header "3. PRODUCTOS POR CATEGORÍA"

# Test 8: GET /categories/{id}/products
((TOTAL_TESTS++))
echo "Test 8: Productos de categoría 1 con paginación"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/1/products?page=0&size=3")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    # Verificar que todos pertenecen a la categoría 1
    WRONG=$(echo "$BODY" | jq '[.content[] | select(.category.id != 1)] | length' 2>/dev/null)
    if [ "$WRONG" -eq 0 ]; then
        mark_success "Productos por categoría correcto"
    else
        mark_failure "Productos de otras categorías incluidos"
    fi
else
    mark_failure "Error al obtener productos por categoría (HTTP $HTTP_CODE)"
fi

# Test 9: Categoría inexistente
((TOTAL_TESTS++))
echo "Test 9: Categoría inexistente (id=9999)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/9999/products")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -eq 404 ]; then
    mark_success "Categoría inexistente retorna 404"
else
    mark_failure "Categoría inexistente NO retorna 404 (HTTP $HTTP_CODE)"
fi

# ============================================
# ORDENAMIENTO
# ============================================
print_header "4. ORDENAMIENTO"

# Test 10: Ordenar por nombre
((TOTAL_TESTS++))
echo "Test 10: Ordenar por nombre (sort=name,asc)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=5&sort=name,asc")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    NAMES=$(echo "$BODY" | jq '[.content[].name]' 2>/dev/null)
    SORTED_NAMES=$(echo "$BODY" | jq '[.content[].name] | sort' 2>/dev/null)

    if [ "$NAMES" == "$SORTED_NAMES" ]; then
        mark_success "Ordenamiento por nombre funciona"
    else
        mark_failure "Ordenamiento por nombre NO funciona"
    fi
else
    mark_failure "Error al ordenar por nombre (HTTP $HTTP_CODE)"
fi

# Test 11: Orden por defecto (sin sort)
((TOTAL_TESTS++))
echo "Test 11: Orden por defecto sin parámetro sort"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -eq 200 ]; then
    mark_success "Consulta sin sort funciona"
else
    mark_failure "Error sin parámetro sort (HTTP $HTTP_CODE)"
fi

# ============================================
# CASOS ESPECIALES
# ============================================
print_header "5. CASOS ESPECIALES"

# Test 12: Query parameters inválidos
((TOTAL_TESTS++))
echo "Test 12: Query parameter inválido (invalidParam=123)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?invalidParam=123&page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -eq 200 ]; then
    mark_success "Parámetros inválidos ignorados correctamente"
else
    mark_failure "Error con parámetros inválidos (HTTP $HTTP_CODE)"
fi

# Test 13: Múltiples sorts
((TOTAL_TESTS++))
echo "Test 13: Múltiples criterios de ordenamiento"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=5&sort=price,asc&sort=name,asc")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -eq 200 ]; then
    mark_success "Múltiples sorts manejados"
else
    mark_failure "Error con múltiples sorts (HTTP $HTTP_CODE)"
fi

# ============================================
# RESUMEN FINAL
# ============================================
print_header "📊 RESUMEN DE QUERY PARAMETERS"

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")

echo -e "${BLUE}Total de tests:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Tests exitosos:${NC} $PASSED_TESTS"
echo -e "${RED}Tests fallidos:${NC} $FAILED_TESTS"
echo -e "${YELLOW}Tasa de éxito:${NC} $SUCCESS_RATE%"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los filtros y query parameters funcionan${NC}"
    exit 0
else
    echo -e "${RED}⚠️  $FAILED_TESTS tests fallaron${NC}"
    exit 1
fi

