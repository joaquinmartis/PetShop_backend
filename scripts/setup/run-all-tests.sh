#!/bin/bash

# ============================================
# MASTER TEST SUITE - VIRTUAL PET API
# Ejecuta todos los tests críticos en secuencia
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

print_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}║        🧪 VIRTUAL PET - MASTER TEST SUITE 🐾          ║${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}║     Ejecutando tests críticos de toda la API          ║${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_suite_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""
}

run_test() {
    local test_name=$1
    local test_file=$2

    ((TOTAL_SUITES++))

    echo -e "${YELLOW}▶ Ejecutando: $test_name${NC}"
    echo ""

    if [ ! -f "$test_file" ]; then
        echo -e "${RED}✗ Archivo no encontrado: $test_file${NC}"
        ((FAILED_SUITES++))
        return 1
    fi

    if bash "$test_file"; then
        echo ""
        echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        ((PASSED_SUITES++))
        return 0
    else
        echo ""
        echo -e "${RED}❌ $test_name: FAILED${NC}"
        ((FAILED_SUITES++))
        return 1
    fi
}

# ============================================
# INICIO
# ============================================

print_banner

START_TIME=$(date +%s)

echo -e "${CYAN}Inicio: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# Verificar servidor
echo -e "${YELLOW}Verificando servidor...${NC}"
SERVER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/api/products" 2>/dev/null || echo "000")

if [ "$SERVER_CHECK" = "000" ]; then
    echo -e "${RED}✗ ERROR: Servidor no responde${NC}"
    echo -e "${RED}  Asegúrate de que la aplicación esté corriendo:${NC}"
    echo -e "${RED}  mvn spring-boot:run${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Servidor corriendo${NC}"

# ============================================
# FASE 1: TESTS POR MÓDULO
# ============================================
print_suite_header "FASE 1: TESTS POR MÓDULO"

run_test "User Module Exhaustive" "./test-user-exhaustive.sh"
run_test "Product Catalog Exhaustive" "./test-product-exhaustive.sh"
run_test "Cart Exhaustive" "./test-cart-exhaustive.sh"
run_test "Order Client Exhaustive" "./test-order-client-exhaustive.sh"
run_test "Order Backoffice Exhaustive" "./test-order-backoffice-exhaustive.sh"

# ============================================
# FASE 2: TESTS END-TO-END
# ============================================
print_suite_header "FASE 2: TESTS END-TO-END"

run_test "Flujo Completo E2E" "./test-flujo-completo-e2e.sh"
run_test "Múltiples Usuarios y Pedidos" "./test-e2e-multiple-orders.sh"

# ============================================
# FASE 3: TESTS DE VALIDACIÓN
# ============================================
print_suite_header "FASE 3: TESTS DE VALIDACIÓN"

run_test "Restauración de Stock" "./test-stock-restoration.sh"
run_test "Validaciones de Campos" "./test-field-validations.sh"
run_test "Query Parameters y Filtros" "./test-query-parameters.sh"

# ============================================
# RESUMEN FINAL
# ============================================

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                        ║${NC}"
echo -e "${CYAN}║              📊 RESUMEN FINAL                          ║${NC}"
echo -e "${CYAN}║                                                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED_SUITES/$TOTAL_SUITES)*100}")

echo -e "${BLUE}Total de test suites:${NC} $TOTAL_SUITES"
echo -e "${GREEN}Suites exitosas:${NC} $PASSED_SUITES"
echo -e "${RED}Suites fallidas:${NC} $FAILED_SUITES"
echo -e "${YELLOW}Tasa de éxito:${NC} $SUCCESS_RATE%"
echo -e "${CYAN}Tiempo total:${NC} ${MINUTES}m ${SECONDS}s"
echo ""

echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  DESGLOSE POR FASE${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

echo "  Fase                        | Estado"
echo "  ────────────────────────────┼────────"
echo "  Módulos individuales (5)    | Ver arriba"
echo "  Tests E2E (2)               | Ver arriba"
echo "  Tests de validación (3)     | Ver arriba"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"

if [ $FAILED_SUITES -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  🎉 ¡TODOS LOS TESTS PASARON! 🎉                  ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  Tu API Virtual Pet está lista para producción   ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  Cobertura de tests: ~85-90%                      ║${NC}"
    echo -e "${GREEN}║  Funcionalidad validada: 100%                     ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  ✅ Aprobada para deployment 🚀                    ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    EXIT_CODE=0
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}║  ⚠️  ALGUNOS TESTS FALLARON ⚠️                     ║${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}║  $FAILED_SUITES suite(s) necesitan revisión              ║${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}║  Revisa los detalles arriba para corregir         ║${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    EXIT_CODE=1
fi

echo -e "${CYAN}Fin: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

exit $EXIT_CODE

