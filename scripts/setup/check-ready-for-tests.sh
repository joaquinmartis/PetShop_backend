#!/bin/bash

# ============================================
# SCRIPT DE VERIFICACIÓN PRE-TESTS
# Verifica que todo esté listo para ejecutar tests
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🔍 VERIFICACIÓN PRE-TESTS - VIRTUAL PET API${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""

ERRORS=0

# 1. Verificar servidor
echo -e "${YELLOW}1. Verificando servidor Spring Boot...${NC}"
SERVER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/api/products" 2>&1)

if [ "$SERVER_CHECK" = "200" ]; then
    echo -e "${GREEN}   ✅ Servidor corriendo en puerto 8080${NC}"
else
    echo -e "${RED}   ❌ Servidor NO responde${NC}"
    echo -e "${YELLOW}   💡 Ejecuta: mvn spring-boot:run${NC}"
    ((ERRORS++))
fi

# 2. Verificar PostgreSQL
echo ""
echo -e "${YELLOW}2. Verificando PostgreSQL...${NC}"
if command -v psql &> /dev/null; then
    if PGPASSWORD=virtualpet123 psql -U virtualpet_user -d virtualpet -h localhost -c "SELECT 1" &> /dev/null; then
        echo -e "${GREEN}   ✅ PostgreSQL conectado${NC}"
    else
        echo -e "${RED}   ❌ No se puede conectar a PostgreSQL${NC}"
        echo -e "${YELLOW}   💡 Verifica: sudo systemctl start postgresql${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${YELLOW}   ⚠️  psql no encontrado, saltando verificación${NC}"
fi

# 3. Verificar usuario warehouse
echo ""
echo -e "${YELLOW}3. Verificando usuario warehouse...${NC}"
if [ "$SERVER_CHECK" = "200" ]; then
    WAREHOUSE_CHECK=$(curl -s -X POST "http://localhost:8080/api/users/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"warehouse@test.com","password":"password123"}' | jq -r '.accessToken' 2>&1)

    if [ -n "$WAREHOUSE_CHECK" ] && [ "$WAREHOUSE_CHECK" != "null" ] && [[ ! "$WAREHOUSE_CHECK" =~ "error" ]]; then
        echo -e "${GREEN}   ✅ Usuario warehouse existe y funciona${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Usuario warehouse no configurado${NC}"
        echo -e "${YELLOW}   💡 Ejecuta: PGPASSWORD=virtualpet123 psql -U virtualpet_user -d virtualpet -h localhost -f create-warehouse-user.sql${NC}"
    fi
fi

# 4. Verificar scripts de test
echo ""
echo -e "${YELLOW}4. Verificando scripts de test...${NC}"
TEST_COUNT=$(ls test-*.sh 2>/dev/null | wc -l)
if [ "$TEST_COUNT" -gt 0 ]; then
    echo -e "${GREEN}   ✅ $TEST_COUNT scripts de test encontrados${NC}"

    # Verificar permisos
    NON_EXEC=$(find . -maxdepth 1 -name "test-*.sh" ! -executable | wc -l)
    if [ "$NON_EXEC" -gt 0 ]; then
        echo -e "${YELLOW}   ⚠️  $NON_EXEC scripts sin permisos de ejecución${NC}"
        echo -e "${YELLOW}   💡 Ejecuta: chmod +x *.sh${NC}"
    else
        echo -e "${GREEN}   ✅ Todos los scripts tienen permisos de ejecución${NC}"
    fi
else
    echo -e "${RED}   ❌ No se encontraron scripts de test${NC}"
    ((ERRORS++))
fi

# 5. Verificar jq (para parsing JSON)
echo ""
echo -e "${YELLOW}5. Verificando herramientas...${NC}"
if command -v jq &> /dev/null; then
    echo -e "${GREEN}   ✅ jq instalado (para parsing JSON)${NC}"
else
    echo -e "${YELLOW}   ⚠️  jq no instalado${NC}"
    echo -e "${YELLOW}   💡 Instala: sudo apt-get install jq${NC}"
fi

if command -v curl &> /dev/null; then
    echo -e "${GREEN}   ✅ curl instalado${NC}"
else
    echo -e "${RED}   ❌ curl no instalado${NC}"
    ((ERRORS++))
fi

# Resumen final
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  ✅ TODO LISTO PARA EJECUTAR TESTS ✅              ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}║  Puedes ejecutar:                                 ║${NC}"
    echo -e "${GREEN}║  ./run-all-tests.sh                               ║${NC}"
    echo -e "${GREEN}║                                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}║  ⚠️  HAY $ERRORS PROBLEMA(S) ⚠️                        ║${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}║  Corrige los errores antes de ejecutar tests      ║${NC}"
    echo -e "${RED}║                                                    ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi

