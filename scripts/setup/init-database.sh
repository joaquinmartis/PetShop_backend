#!/bin/bash

# ========================================
# VIRTUAL PET - Inicializar Base de Datos
# ========================================
# Este script inicializa la base de datos PostgreSQL
# con la estructura completa y datos de ejemplo
# ========================================

set -e  # Salir si hay errores

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración por defecto
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-virtualpet}"
DB_USER="${DB_USER:-virtualpet_user}"
DB_PASSWORD="${DB_PASSWORD:-virtualpet123}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}VIRTUAL PET - Database Initialization${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -h, --help              Mostrar esta ayuda"
    echo "  -H, --host HOST         Host de PostgreSQL (default: localhost)"
    echo "  -p, --port PORT         Puerto de PostgreSQL (default: 5432)"
    echo "  -d, --database DB       Nombre de la base de datos (default: virtualpet)"
    echo "  -U, --user USER         Usuario de PostgreSQL (default: virtualpet_user)"
    echo "  -W, --password PASS     Password de PostgreSQL (default: virtualpet123)"
    echo "  -f, --force             Forzar ejecución (eliminar datos existentes)"
    echo ""
    echo "Ejemplo:"
    echo "  $0"
    echo "  $0 --host localhost --database virtualpet"
    echo ""
}

# Parsear argumentos
FORCE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -H|--host)
            DB_HOST="$2"
            shift 2
            ;;
        -p|--port)
            DB_PORT="$2"
            shift 2
            ;;
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -U|--user)
            DB_USER="$2"
            shift 2
            ;;
        -W|--password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            echo -e "${RED}❌ Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Mostrar configuración
echo -e "${YELLOW}Configuración:${NC}"
echo "  Host:     $DB_HOST"
echo "  Port:     $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User:     $DB_USER"
echo ""

# Verificar que psql esté instalado
if ! command -v psql &> /dev/null; then
    echo -e "${RED}❌ Error: psql no está instalado${NC}"
    echo "Instala PostgreSQL client:"
    echo "  Ubuntu/Debian: sudo apt-get install postgresql-client"
    echo "  Mac: brew install postgresql"
    exit 1
fi

# Verificar que el archivo SQL existe
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="$SCRIPT_DIR/init-database.sql"

if [ ! -f "$SQL_FILE" ]; then
    echo -e "${RED}❌ Error: No se encuentra el archivo init-database.sql${NC}"
    echo "Buscando en: $SCRIPT_DIR"
    exit 1
fi

echo -e "${GREEN}📄 Usando: init-database.sql (formato pg_dump)${NC}"

# Verificar conexión a la base de datos
echo -e "${YELLOW}📡 Verificando conexión a PostgreSQL...${NC}"
if PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Conexión exitosa${NC}"
else
    echo -e "${RED}❌ Error: No se puede conectar a PostgreSQL${NC}"
    echo "Verifica que PostgreSQL esté corriendo y las credenciales sean correctas"
    exit 1
fi

# Verificar si la base de datos existe
echo -e "${YELLOW}🔍 Verificando base de datos...${NC}"
DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")

if [ "$DB_EXISTS" = "1" ]; then
    echo -e "${GREEN}✅ Base de datos '$DB_NAME' encontrada${NC}"

    # Verificar si ya tiene datos
    TABLE_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog', 'information_schema')")

    if [ "$TABLE_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  La base de datos ya contiene $TABLE_COUNT tabla(s)${NC}"

        if [ "$FORCE" = false ]; then
            echo ""
            echo -e "${YELLOW}¿Deseas continuar? Esto puede sobrescribir datos existentes.${NC}"
            echo "  [y] Continuar"
            echo "  [n] Cancelar"
            read -p "Opción: " -n 1 -r
            echo ""

            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}ℹ️  Operación cancelada${NC}"
                exit 0
            fi
        else
            echo -e "${YELLOW}⚡ Modo --force activado, continuando...${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Base de datos '$DB_NAME' no existe${NC}"
    echo -e "${YELLOW}📝 Creando base de datos...${NC}"

    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Base de datos creada${NC}"
    else
        echo -e "${RED}❌ Error al crear la base de datos${NC}"
        exit 1
    fi
fi

# Ejecutar el script SQL
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Ejecutando script de inicialización...${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$SQL_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ BASE DE DATOS INICIALIZADA${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${GREEN}🎉 ¡La base de datos está lista!${NC}"
    echo ""
    echo -e "${YELLOW}📝 Siguiente paso:${NC}"
    echo "   cd /home/optimus/Desktop/VirtualPet"
    echo "   mvn spring-boot:run"
    echo ""
    echo -e "${YELLOW}🔗 URLs útiles:${NC}"
    echo "   API: http://localhost:8080"
    echo "   Swagger: http://localhost:8080/swagger-ui.html"
    echo ""
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}❌ ERROR AL INICIALIZAR${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Verifica el log arriba para más detalles"
    exit 1
fi

