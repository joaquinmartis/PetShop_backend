#!/bin/bash

# ============================================
# TEST EXHAUSTIVO - MÓDULO PRODUCT CATALOG
# Validación completa de JSON + Códigos HTTP
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

BASE_URL="http://localhost:8080/api"
PRODUCT_ID=""
CATEGORY_ID=""

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

validate_field() {
    local json=$1
    local field=$2
    local expected_value=$3

    if [ -z "$expected_value" ]; then
        # Solo verificar que existe
        if echo "$json" | jq -e ".$field" > /dev/null 2>&1; then
            echo -e "${GREEN}   ✓ Campo '$field' presente${NC}"
            return 0
        else
            echo -e "${RED}   ✗ Campo '$field' AUSENTE${NC}"
            return 1
        fi
    else
        # Verificar valor específico
        actual=$(echo "$json" | jq -r ".$field" 2>/dev/null)
        if [ "$actual" = "$expected_value" ]; then
            echo -e "${GREEN}   ✓ Campo '$field' = '$expected_value'${NC}"
            return 0
        else
            echo -e "${RED}   ✗ Campo '$field': esperado '$expected_value', obtenido '$actual'${NC}"
            return 1
        fi
    fi
}

validate_array_not_empty() {
    local json=$1
    local field=$2

    local length=$(echo "$json" | jq ".$field | length" 2>/dev/null)
    if [ "$length" -gt 0 ]; then
        echo -e "${GREEN}   ✓ Array '$field' tiene $length elementos${NC}"
        return 0
    else
        echo -e "${RED}   ✗ Array '$field' está vacío o no existe${NC}"
        return 1
    fi
}

validate_page_structure() {
    local json=$1
    local validation_passed=true

    # Validar estructura de Page (Spring Data)
    validate_field "$json" "content" || validation_passed=false
    validate_field "$json" "pageable" || validation_passed=false
    validate_field "$json" "totalElements" || validation_passed=false
    validate_field "$json" "totalPages" || validation_passed=false
    validate_field "$json" "size" || validation_passed=false
    validate_field "$json" "number" || validation_passed=false
    validate_field "$json" "first" || validation_passed=false
    validate_field "$json" "last" || validation_passed=false
    validate_field "$json" "empty" || validation_passed=false

    return $([ "$validation_passed" = true ] && echo 0 || echo 1)
}

validate_product_response() {
    local json=$1
    local validation_passed=true

    # Campos obligatorios de ProductResponse
    validate_field "$json" "id" || validation_passed=false
    validate_field "$json" "name" || validation_passed=false
    validate_field "$json" "description" || validation_passed=false
    validate_field "$json" "price" || validation_passed=false
    validate_field "$json" "stock" || validation_passed=false
    validate_field "$json" "category" || validation_passed=false
    validate_field "$json" "category.id" || validation_passed=false
    validate_field "$json" "category.name" || validation_passed=false
    validate_field "$json" "imageUrl" || validation_passed=false
    validate_field "$json" "active" "true" || validation_passed=false
    validate_field "$json" "createdAt" || validation_passed=false
    validate_field "$json" "updatedAt" || validation_passed=false

    return $([ "$validation_passed" = true ] && echo 0 || echo 1)
}

validate_category_response() {
    local json=$1
    local validation_passed=true

    # Campos obligatorios de CategoryResponse
    validate_field "$json" "id" || validation_passed=false
    validate_field "$json" "name" || validation_passed=false
    validate_field "$json" "description" || validation_passed=false
    validate_field "$json" "active" "true" || validation_passed=false
    validate_field "$json" "createdAt" || validation_passed=false
    validate_field "$json" "updatedAt" || validation_passed=false

    return $([ "$validation_passed" = true ] && echo 0 || echo 1)
}

validate_error_response() {
    local json=$1
    local expected_status=$2
    local validation_passed=true

    # Validar estructura de ErrorResponse
    validate_field "$json" "status" "$expected_status" || validation_passed=false
    validate_field "$json" "error" || validation_passed=false
    validate_field "$json" "message" || validation_passed=false
    validate_field "$json" "path" || validation_passed=false
    validate_field "$json" "timestamp" || validation_passed=false

    return $([ "$validation_passed" = true ] && echo 0 || echo 1)
}

mark_test_passed() {
    echo -e "${GREEN}✅ TEST PASSED: $1${NC}"
    echo ""
    ((PASSED_TESTS++))
}

mark_test_failed() {
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
# TEST 1: LISTAR CATEGORÍAS - VALIDACIÓN COMPLETA
# ============================================
print_header "TEST 1: LISTAR CATEGORÍAS - VALIDACIÓN COMPLETA"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response (primeras 2 categorías):"
echo "$BODY" | jq '.[0:2]' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

# Validar que sea un array
if echo "$BODY" | jq -e '. | type == "array"' > /dev/null 2>&1; then
    echo -e "${GREEN}   ✓ Respuesta es un array${NC}"
else
    echo -e "${RED}   ✗ Respuesta NO es un array${NC}"
    VALIDATION_PASSED=false
fi

# Validar que tenga al menos una categoría
CATEGORIES_COUNT=$(echo "$BODY" | jq 'length' 2>/dev/null)
if [ "$CATEGORIES_COUNT" -gt 0 ]; then
    echo -e "${GREEN}   ✓ Array tiene $CATEGORIES_COUNT categorías${NC}"

    # Guardar ID de la primera categoría
    CATEGORY_ID=$(echo "$BODY" | jq -r '.[0].id' 2>/dev/null)
    CATEGORY_NAME=$(echo "$BODY" | jq -r '.[0].name' 2>/dev/null)

    echo ""
    echo "   Validando estructura de la primera categoría:"
    FIRST_CATEGORY=$(echo "$BODY" | jq '.[0]')
    validate_category_response "$FIRST_CATEGORY" || VALIDATION_PASSED=false
else
    echo -e "${RED}   ✗ Array vacío${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Listar categorías retorna array con estructura completa"
else
    mark_test_failed "Listar categorías" "Validación de estructura falló"
fi

# ============================================
# TEST 2: OBTENER CATEGORÍA POR ID - VALIDACIÓN COMPLETA
# ============================================
print_header "TEST 2: OBTENER CATEGORÍA POR ID - VALIDACIÓN COMPLETA"
((TOTAL_TESTS++))

if [ -z "$CATEGORY_ID" ] || [ "$CATEGORY_ID" = "null" ]; then
    mark_test_failed "Obtener categoría por ID" "No hay categorías disponibles"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/$CATEGORY_ID")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Response:"
    echo "$BODY" | jq '.'
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    # Validar estructura completa
    validate_category_response "$BODY" || VALIDATION_PASSED=false

    # Validar que el ID coincida
    RETURNED_ID=$(echo "$BODY" | jq -r '.id' 2>/dev/null)
    if [ "$RETURNED_ID" = "$CATEGORY_ID" ]; then
        echo -e "${GREEN}   ✓ ID coincide: $CATEGORY_ID${NC}"
    else
        echo -e "${RED}   ✗ ID no coincide: esperado $CATEGORY_ID, obtenido $RETURNED_ID${NC}"
        VALIDATION_PASSED=false
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Categoría por ID retorna estructura completa y correcta"
    else
        mark_test_failed "Obtener categoría por ID" "Validación falló"
    fi
fi

# ============================================
# TEST 3: CATEGORÍA INEXISTENTE - VALIDAR 404
# ============================================
print_header "TEST 3: CATEGORÍA INEXISTENTE - VALIDAR 404 Y ERROR"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/99999")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 404 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 404 Not Found, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 404 Not Found${NC}"
fi

# Validar ErrorResponse
validate_error_response "$BODY" "404" || VALIDATION_PASSED=false

# Validar mensaje
MESSAGE=$(echo "$BODY" | jq -r '.message' 2>/dev/null)
if [[ "$MESSAGE" =~ "Categoría" ]] || [[ "$MESSAGE" =~ "categoría" ]] || [[ "$MESSAGE" =~ "encontrad" ]]; then
    echo -e "${GREEN}   ✓ Mensaje indica categoría no encontrada${NC}"
else
    echo -e "${YELLOW}   ⚠ Mensaje no específico: $MESSAGE${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Categoría inexistente retorna 404 con ErrorResponse correcto"
else
    mark_test_failed "Categoría inexistente" "Validación de error falló"
fi

# ============================================
# TEST 4: LISTAR PRODUCTOS - VALIDACIÓN COMPLETA CON PAGINACIÓN
# ============================================
print_header "TEST 4: LISTAR PRODUCTOS - VALIDACIÓN COMPLETA"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?page=0&size=3")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response (estructura Page):"
echo "$BODY" | jq '{totalElements, totalPages, size, number, first, last, empty, contentLength: (.content | length)}' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

# Validar estructura de Page
validate_page_structure "$BODY" || VALIDATION_PASSED=false

# Validar que content tenga productos
CONTENT_LENGTH=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
if [ "$CONTENT_LENGTH" -gt 0 ]; then
    echo -e "${GREEN}   ✓ Content tiene $CONTENT_LENGTH productos${NC}"

    # Guardar ID del primer producto
    PRODUCT_ID=$(echo "$BODY" | jq -r '.content[0].id' 2>/dev/null)
    PRODUCT_NAME=$(echo "$BODY" | jq -r '.content[0].name' 2>/dev/null)

    echo ""
    echo "   Validando estructura del primer producto:"
    FIRST_PRODUCT=$(echo "$BODY" | jq '.content[0]')
    validate_product_response "$FIRST_PRODUCT" || VALIDATION_PASSED=false

    # Validar que el size sea 3 (como pedimos)
    SIZE=$(echo "$BODY" | jq -r '.size' 2>/dev/null)
    if [ "$SIZE" -eq 3 ]; then
        echo -e "${GREEN}   ✓ Size de paginación correcto: 3${NC}"
    else
        echo -e "${RED}   ✗ Size esperado: 3, obtenido: $SIZE${NC}"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${RED}   ✗ Content vacío${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Listar productos retorna Page con estructura completa"
else
    mark_test_failed "Listar productos" "Validación falló"
fi

# ============================================
# TEST 5: OBTENER PRODUCTO POR ID - VALIDACIÓN COMPLETA
# ============================================
print_header "TEST 5: OBTENER PRODUCTO POR ID - VALIDACIÓN COMPLETA"
((TOTAL_TESTS++))

if [ -z "$PRODUCT_ID" ] || [ "$PRODUCT_ID" = "null" ]; then
    mark_test_failed "Obtener producto por ID" "No hay productos disponibles"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products/$PRODUCT_ID")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Response:"
    echo "$BODY" | jq '.'
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    # Validar estructura completa de ProductResponse
    validate_product_response "$BODY" || VALIDATION_PASSED=false

    # Validar que el ID coincida
    RETURNED_ID=$(echo "$BODY" | jq -r '.id' 2>/dev/null)
    if [ "$RETURNED_ID" = "$PRODUCT_ID" ]; then
        echo -e "${GREEN}   ✓ ID coincide: $PRODUCT_ID${NC}"
    else
        echo -e "${RED}   ✗ ID no coincide: esperado $PRODUCT_ID, obtenido $RETURNED_ID${NC}"
        VALIDATION_PASSED=false
    fi

    # Validar tipos de datos
    PRICE=$(echo "$BODY" | jq -r '.price' 2>/dev/null)
    if [[ "$PRICE" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "${GREEN}   ✓ Price es numérico: $PRICE${NC}"
    else
        echo -e "${RED}   ✗ Price no es numérico: $PRICE${NC}"
        VALIDATION_PASSED=false
    fi

    STOCK=$(echo "$BODY" | jq -r '.stock' 2>/dev/null)
    if [[ "$STOCK" =~ ^[0-9]+$ ]]; then
        echo -e "${GREEN}   ✓ Stock es entero: $STOCK${NC}"
    else
        echo -e "${RED}   ✗ Stock no es entero: $STOCK${NC}"
        VALIDATION_PASSED=false
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Producto por ID retorna estructura completa con tipos correctos"
    else
        mark_test_failed "Obtener producto por ID" "Validación falló"
    fi
fi

# ============================================
# TEST 6: PRODUCTO INEXISTENTE - VALIDAR 404
# ============================================
print_header "TEST 6: PRODUCTO INEXISTENTE - VALIDAR 404 Y ERROR"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products/99999")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 404 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 404 Not Found, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 404 Not Found${NC}"
fi

validate_error_response "$BODY" "404" || VALIDATION_PASSED=false

MESSAGE=$(echo "$BODY" | jq -r '.message' 2>/dev/null)
if [[ "$MESSAGE" =~ "Producto" ]] || [[ "$MESSAGE" =~ "producto" ]] || [[ "$MESSAGE" =~ "encontrad" ]]; then
    echo -e "${GREEN}   ✓ Mensaje indica producto no encontrado${NC}"
else
    echo -e "${YELLOW}   ⚠ Mensaje no específico: $MESSAGE${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Producto inexistente retorna 404 con ErrorResponse correcto"
else
    mark_test_failed "Producto inexistente" "Validación falló"
fi

# ============================================
# TEST 7: FILTRAR POR CATEGORÍA - VALIDAR RESULTADOS
# ============================================
print_header "TEST 7: FILTRAR POR CATEGORÍA - VALIDAR RESULTADOS"
((TOTAL_TESTS++))

if [ -z "$CATEGORY_ID" ]; then
    mark_test_failed "Filtrar por categoría" "No hay categorías"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?categoryId=$CATEGORY_ID&page=0&size=5")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Categoría buscada: ID=$CATEGORY_ID, Name='$CATEGORY_NAME'"
    echo "Resultados:"
    echo "$BODY" | jq '{totalElements, productos: .content | map({id, name, "category.id": .category.id, "category.name": .category.name})}' 2>/dev/null
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    validate_page_structure "$BODY" || VALIDATION_PASSED=false

    # Verificar que TODOS los productos tengan la categoría correcta
    CONTENT_LENGTH=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
    if [ "$CONTENT_LENGTH" -gt 0 ]; then
        echo -e "${GREEN}   ✓ Encontrados $CONTENT_LENGTH productos${NC}"

        WRONG_CATEGORY=0
        for i in $(seq 0 $(($CONTENT_LENGTH - 1))); do
            CAT_ID=$(echo "$BODY" | jq -r ".content[$i].category.id" 2>/dev/null)
            if [ "$CAT_ID" != "$CATEGORY_ID" ]; then
                ((WRONG_CATEGORY++))
            fi
        done

        if [ "$WRONG_CATEGORY" -eq 0 ]; then
            echo -e "${GREEN}   ✓ TODOS los productos pertenecen a la categoría $CATEGORY_ID${NC}"
        else
            echo -e "${RED}   ✗ $WRONG_CATEGORY productos NO pertenecen a la categoría${NC}"
            VALIDATION_PASSED=false
        fi
    else
        echo -e "${YELLOW}   ⚠ No hay productos en esta categoría${NC}"
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Filtro por categoría retorna solo productos de esa categoría"
    else
        mark_test_failed "Filtrar por categoría" "Validación falló"
    fi
fi

# ============================================
# TEST 8: FILTRAR POR STOCK - VALIDAR STOCK > 0
# ============================================
print_header "TEST 8: FILTRAR POR STOCK - VALIDAR QUE TODOS TENGAN STOCK"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?inStock=true&page=0&size=10")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Productos con stock:"
echo "$BODY" | jq '.content | map({id, name, stock})' 2>/dev/null | head -20
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

validate_page_structure "$BODY" || VALIDATION_PASSED=false

# Verificar que TODOS los productos tengan stock > 0
CONTENT_LENGTH=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
if [ "$CONTENT_LENGTH" -gt 0 ]; then
    echo -e "${GREEN}   ✓ Encontrados $CONTENT_LENGTH productos${NC}"

    WITHOUT_STOCK=0
    for i in $(seq 0 $(($CONTENT_LENGTH - 1))); do
        STOCK=$(echo "$BODY" | jq -r ".content[$i].stock" 2>/dev/null)
        if [ "$STOCK" -le 0 ]; then
            ((WITHOUT_STOCK++))
            PROD_NAME=$(echo "$BODY" | jq -r ".content[$i].name" 2>/dev/null)
            echo -e "${RED}      ✗ Producto '$PROD_NAME' tiene stock=$STOCK${NC}"
        fi
    done

    if [ "$WITHOUT_STOCK" -eq 0 ]; then
        echo -e "${GREEN}   ✓ TODOS los productos tienen stock > 0${NC}"
    else
        echo -e "${RED}   ✗ $WITHOUT_STOCK productos tienen stock <= 0${NC}"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${RED}   ✗ No hay productos con stock${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Filtro por stock retorna solo productos disponibles"
else
    mark_test_failed "Filtrar por stock" "Algunos productos sin stock"
fi

# ============================================
# TEST 9: BÚSQUEDA POR NOMBRE - VALIDAR COINCIDENCIAS
# ============================================
print_header "TEST 9: BÚSQUEDA POR NOMBRE - VALIDAR COINCIDENCIAS"
((TOTAL_TESTS++))

SEARCH_TERM="alimento"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?name=$SEARCH_TERM&page=0&size=10")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Búsqueda: '$SEARCH_TERM'"
echo "Resultados:"
echo "$BODY" | jq '.content | map({id, name})' 2>/dev/null | head -20
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

validate_page_structure "$BODY" || VALIDATION_PASSED=false

# Verificar que los nombres contengan el término buscado (case insensitive)
CONTENT_LENGTH=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
if [ "$CONTENT_LENGTH" -gt 0 ]; then
    echo -e "${GREEN}   ✓ Encontrados $CONTENT_LENGTH productos${NC}"

    NOT_MATCHING=0
    for i in $(seq 0 $(($CONTENT_LENGTH - 1))); do
        NAME=$(echo "$BODY" | jq -r ".content[$i].name" 2>/dev/null)
        NAME_LOWER=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
        SEARCH_LOWER=$(echo "$SEARCH_TERM" | tr '[:upper:]' '[:lower:]')

        if [[ ! "$NAME_LOWER" =~ "$SEARCH_LOWER" ]]; then
            ((NOT_MATCHING++))
            echo -e "${RED}      ✗ Producto '$NAME' NO contiene '$SEARCH_TERM'${NC}"
        fi
    done

    if [ "$NOT_MATCHING" -eq 0 ]; then
        echo -e "${GREEN}   ✓ TODOS los productos contienen '$SEARCH_TERM' en el nombre${NC}"
    else
        echo -e "${RED}   ✗ $NOT_MATCHING productos NO coinciden con la búsqueda${NC}"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${YELLOW}   ⚠ No hay productos que coincidan con '$SEARCH_TERM'${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Búsqueda por nombre retorna solo productos coincidentes"
else
    mark_test_failed "Búsqueda por nombre" "Resultados no coincidentes"
fi

# ============================================
# TEST 10: BÚSQUEDA SIN RESULTADOS
# ============================================
print_header "TEST 10: BÚSQUEDA SIN RESULTADOS - VALIDAR RESPUESTA VACÍA"
((TOTAL_TESTS++))

SEARCH_TERM="ProductoInexistenteXYZ999"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?name=$SEARCH_TERM&page=0&size=10")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Búsqueda: '$SEARCH_TERM'"
echo "Response:"
echo "$BODY" | jq '{totalElements, empty, contentLength: (.content | length)}' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

validate_page_structure "$BODY" || VALIDATION_PASSED=false

# Validar que totalElements sea 0
TOTAL_ELEMENTS=$(echo "$BODY" | jq -r '.totalElements' 2>/dev/null)
if [ "$TOTAL_ELEMENTS" -eq 0 ]; then
    echo -e "${GREEN}   ✓ totalElements = 0${NC}"
else
    echo -e "${RED}   ✗ totalElements: esperado 0, obtenido $TOTAL_ELEMENTS${NC}"
    VALIDATION_PASSED=false
fi

# Validar que empty sea true
IS_EMPTY=$(echo "$BODY" | jq -r '.empty' 2>/dev/null)
if [ "$IS_EMPTY" = "true" ]; then
    echo -e "${GREEN}   ✓ empty = true${NC}"
else
    echo -e "${RED}   ✗ empty: esperado true, obtenido $IS_EMPTY${NC}"
    VALIDATION_PASSED=false
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Búsqueda sin resultados retorna Page vacía correctamente"
else
    mark_test_failed "Búsqueda sin resultados" "Validación falló"
fi

# ============================================
# TEST 11: ORDENAMIENTO POR PRECIO - VALIDAR ORDEN
# ============================================
print_header "TEST 11: ORDENAMIENTO POR PRECIO - VALIDAR ORDEN ASCENDENTE"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/products?sort=price&page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Productos ordenados por precio:"
echo "$BODY" | jq '.content | map({name, price})' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 200 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
fi

validate_page_structure "$BODY" || VALIDATION_PASSED=false

# Verificar que los precios estén en orden ascendente
CONTENT_LENGTH=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
if [ "$CONTENT_LENGTH" -gt 1 ]; then
    PREV_PRICE=0
    SORTED=true

    for i in $(seq 0 $(($CONTENT_LENGTH - 1))); do
        PRICE=$(echo "$BODY" | jq -r ".content[$i].price" 2>/dev/null)

        if [ $(echo "$PRICE < $PREV_PRICE" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then
            SORTED=false
            echo -e "${RED}      ✗ Precio $PRICE < $PREV_PRICE (orden incorrecto)${NC}"
        fi

        PREV_PRICE=$PRICE
    done

    if [ "$SORTED" = true ]; then
        echo -e "${GREEN}   ✓ Precios ordenados ascendentemente${NC}"
    else
        echo -e "${RED}   ✗ Precios NO están en orden ascendente${NC}"
        VALIDATION_PASSED=false
    fi
else
    echo -e "${YELLOW}   ⚠ No hay suficientes productos para validar orden${NC}"
fi

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Ordenamiento por precio funciona correctamente"
else
    mark_test_failed "Ordenamiento por precio" "Orden incorrecto"
fi

# ============================================
# TEST 12: PRODUCTOS DE CATEGORÍA - VALIDAR RELACIÓN
# ============================================
print_header "TEST 12: PRODUCTOS DE CATEGORÍA - VALIDAR ENDPOINT ESPECÍFICO"
((TOTAL_TESTS++))

if [ -z "$CATEGORY_ID" ]; then
    mark_test_failed "Productos de categoría" "No hay categorías"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/$CATEGORY_ID/products?page=0&size=5")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Categoría: ID=$CATEGORY_ID"
    echo "Productos:"
    echo "$BODY" | jq '.content | map({id, name, "categoryId": .category.id})' 2>/dev/null
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    validate_page_structure "$BODY" || VALIDATION_PASSED=false

    # Verificar que todos pertenezcan a la categoría
    CONTENT_LENGTH=$(echo "$BODY" | jq '.content | length' 2>/dev/null)
    if [ "$CONTENT_LENGTH" -gt 0 ]; then
        WRONG_CATEGORY=0
        for i in $(seq 0 $(($CONTENT_LENGTH - 1))); do
            CAT_ID=$(echo "$BODY" | jq -r ".content[$i].category.id" 2>/dev/null)
            if [ "$CAT_ID" != "$CATEGORY_ID" ]; then
                ((WRONG_CATEGORY++))
            fi
        done

        if [ "$WRONG_CATEGORY" -eq 0 ]; then
            echo -e "${GREEN}   ✓ Todos los productos pertenecen a la categoría${NC}"
        else
            echo -e "${RED}   ✗ $WRONG_CATEGORY productos de otra categoría${NC}"
            VALIDATION_PASSED=false
        fi
    else
        echo -e "${YELLOW}   ⚠ No hay productos en esta categoría${NC}"
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Endpoint de productos por categoría funciona correctamente"
    else
        mark_test_failed "Productos de categoría" "Validación falló"
    fi
fi

# ============================================
# TEST 13: PRODUCTOS DE CATEGORÍA INEXISTENTE - VALIDAR 404
# ============================================
print_header "TEST 13: PRODUCTOS DE CATEGORÍA INEXISTENTE - VALIDAR 404"
((TOTAL_TESTS++))

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/categories/99999/products?page=0&size=5")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null
echo ""

VALIDATION_PASSED=true

if [ "$HTTP_CODE" -ne 404 ]; then
    echo -e "${RED}   ✗ HTTP Code: esperado 404, obtenido $HTTP_CODE${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}   ✓ HTTP Code: 404 Not Found${NC}"
fi

validate_error_response "$BODY" "404" || VALIDATION_PASSED=false

if [ "$VALIDATION_PASSED" = true ]; then
    mark_test_passed "Categoría inexistente en /products retorna 404"
else
    mark_test_failed "Productos categoría inexistente" "Validación falló"
fi

# ============================================
# TEST 14: CHECK AVAILABILITY - VALIDAR ESTRUCTURA
# ============================================
print_header "TEST 14: CHECK AVAILABILITY - VALIDAR ESTRUCTURA COMPLETA"
((TOTAL_TESTS++))

if [ -z "$PRODUCT_ID" ]; then
    mark_test_failed "Check availability" "No hay productos"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/products/check-availability" \
        -H "Content-Type: application/json" \
        -d "{\"items\": [{\"productId\": $PRODUCT_ID, \"quantity\": 1}]}")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Request: productId=$PRODUCT_ID, quantity=1"
    echo "Response:"
    echo "$BODY" | jq '.'
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    # Validar estructura de CheckAvailabilityResponse
    validate_field "$BODY" "available" || VALIDATION_PASSED=false
    validate_field "$BODY" "message" || VALIDATION_PASSED=false

    # Si available es true, unavailableProducts debe ser null o vacío
    AVAILABLE=$(echo "$BODY" | jq -r '.available' 2>/dev/null)
    if [ "$AVAILABLE" = "true" ]; then
        echo -e "${GREEN}   ✓ available = true${NC}"

        UNAVAILABLE=$(echo "$BODY" | jq -r '.unavailableProducts' 2>/dev/null)
        if [ "$UNAVAILABLE" = "null" ] || [ "$UNAVAILABLE" = "[]" ]; then
            echo -e "${GREEN}   ✓ unavailableProducts está vacío (correcto)${NC}"
        else
            echo -e "${YELLOW}   ⚠ unavailableProducts no está vacío pero available=true${NC}"
        fi
    else
        echo -e "${YELLOW}   ⚠ available = false (producto sin stock suficiente)${NC}"
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Check availability retorna estructura correcta"
    else
        mark_test_failed "Check availability" "Validación falló"
    fi
fi

# ============================================
# TEST 15: CHECK AVAILABILITY - STOCK INSUFICIENTE
# ============================================
print_header "TEST 15: CHECK AVAILABILITY - VALIDAR STOCK INSUFICIENTE"
((TOTAL_TESTS++))

if [ -z "$PRODUCT_ID" ]; then
    mark_test_failed "Stock insuficiente" "No hay productos"
else
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/products/check-availability" \
        -H "Content-Type: application/json" \
        -d "{\"items\": [{\"productId\": $PRODUCT_ID, \"quantity\": 999999}]}")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    echo "HTTP Status: $HTTP_CODE"
    echo "Request: productId=$PRODUCT_ID, quantity=999999 (excesiva)"
    echo "Response:"
    echo "$BODY" | jq '.'
    echo ""

    VALIDATION_PASSED=true

    if [ "$HTTP_CODE" -ne 200 ]; then
        echo -e "${RED}   ✗ HTTP Code: esperado 200, obtenido $HTTP_CODE${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}   ✓ HTTP Code: 200 OK${NC}"
    fi

    # Validar que available sea false
    AVAILABLE=$(echo "$BODY" | jq -r '.available' 2>/dev/null)
    if [ "$AVAILABLE" = "false" ]; then
        echo -e "${GREEN}   ✓ available = false (correcto)${NC}"
    else
        echo -e "${RED}   ✗ available: esperado false, obtenido $AVAILABLE${NC}"
        VALIDATION_PASSED=false
    fi

    # Debe haber unavailableProducts
    UNAVAILABLE_COUNT=$(echo "$BODY" | jq '.unavailableProducts | length' 2>/dev/null)
    if [ "$UNAVAILABLE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}   ✓ unavailableProducts tiene $UNAVAILABLE_COUNT productos${NC}"

        # Validar estructura del primer producto no disponible
        FIRST_UNAVAILABLE=$(echo "$BODY" | jq '.unavailableProducts[0]')
        validate_field "$FIRST_UNAVAILABLE" "productId" || VALIDATION_PASSED=false
        validate_field "$FIRST_UNAVAILABLE" "reason" || VALIDATION_PASSED=false
    else
        echo -e "${RED}   ✗ unavailableProducts vacío pero available=false${NC}"
        VALIDATION_PASSED=false
    fi

    if [ "$VALIDATION_PASSED" = true ]; then
        mark_test_passed "Stock insuficiente detectado y reportado correctamente"
    else
        mark_test_failed "Stock insuficiente" "Validación falló"
    fi
fi

# ============================================
# RESUMEN FINAL
# ============================================
print_header "RESUMEN FINAL - VALIDACIÓN EXHAUSTIVA"

echo -e "${BLUE}Total de Tests:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Tests Exitosos:${NC} $PASSED_TESTS"
echo -e "${RED}Tests Fallidos:${NC} $FAILED_TESTS"

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
echo -e "${YELLOW}Tasa de Éxito:${NC} $SUCCESS_RATE%"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}VALIDACIONES REALIZADAS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "✅ Código HTTP correcto"
echo "✅ Estructura JSON completa (CategoryResponse, ProductResponse)"
echo "✅ Estructura Page con paginación"
echo "✅ Campos obligatorios presentes"
echo "✅ Valores de campos correctos"
echo "✅ Tipos de datos validados (price numérico, stock entero)"
echo "✅ Filtros funcionan correctamente"
echo "✅ Búsqueda case-insensitive"
echo "✅ Ordenamiento validado"
echo "✅ Relaciones categoría-producto correctas"
echo "✅ ErrorResponse estandarizado"
echo "✅ Check availability con estructura completa"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON CON VALIDACIÓN COMPLETA! 🎉${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}⚠️  $FAILED_TESTS test(s) fallaron en validación exhaustiva${NC}"
    EXIT_CODE=1
fi

exit $EXIT_CODE

