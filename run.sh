#!/bin/bash
# =============================================================
# run.sh — Fiestas Clandestinas
# Levanta la aplicación Django en modo desarrollo.
#
# Uso:
#   ./run.sh              → puerto 8000 (default)
#   ./run.sh 9000         → puerto personalizado
#   ./run.sh --setup      → inicializa BD + datos de prueba
# =============================================================

set -e

PORT=${1:-8000}
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$BASE_DIR"

# ── Colores ──
RED='\033[0;31m'
YLW='\033[1;33m'
GRN='\033[0;32m'
NC='\033[0m'

echo -e "${YLW}"
echo "  ████████╗██╗███████╗███████╗████████╗ █████╗ ███████╗"
echo "  ██╔════╝ ██║██╔════╝██╔════╝╚══██╔══╝██╔══██╗██╔════╝"
echo "  █████╗   ██║█████╗  ███████╗   ██║   ███████║███████╗"
echo "  ██╔══╝   ██║██╔══╝  ╚════██║   ██║   ██╔══██║╚════██║"
echo "  ██║      ██║███████╗███████║   ██║   ██║  ██║███████║"
echo "  ╚═╝      ╚═╝╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝"
echo -e "  CLANDESTINAS — servidor de desarrollo${NC}"
echo ""

# ── Verificar entorno virtual ──
if [ ! -d "venv" ]; then
    echo -e "${YLW}[setup]${NC} Creando entorno virtual..."
    python3 -m venv venv
fi

source venv/bin/activate

# ── Instalar dependencias ──
if [ ! -f "venv/.installed" ] || [ "requirements.txt" -nt "venv/.installed" ]; then
    echo -e "${YLW}[setup]${NC} Instalando dependencias..."
    pip install -q -r requirements.txt
    touch venv/.installed
fi

# ── Modo setup ──
if [ "$1" == "--setup" ]; then
    echo -e "${YLW}[setup]${NC} Aplicando migraciones..."
    python manage.py migrate

    echo -e "${YLW}[setup]${NC} Cargando datos de prueba..."
    python manage.py shell -c "
from apps.fiestas.models import Fiesta
from django.utils import timezone
from datetime import timedelta
import random, string

def codigo():
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

if not Fiesta.objects.exists():
    fiestas = [
        dict(nombre='Noche Salvaje Vol. 3', tipo_lugar='casa', organizador='DJ Fantasma',
             ciudad='Bogotá', departamento='Cundinamarca', direccion='Calle 45 # 12-30',
             fecha_hora=timezone.now() + timedelta(days=3), capacidad_maxima=60,
             es_publica=True, codigo_acceso=codigo()),
        dict(nombre='La Clandestina del Sótano', tipo_lugar='local', organizador='El Comité',
             ciudad='Medellín', departamento='Antioquia', direccion='Carrera 70 # 44-18',
             fecha_hora=timezone.now() + timedelta(days=1), capacidad_maxima=40,
             es_publica=False, codigo_acceso=codigo()),
        dict(nombre='Finca Roots Session', tipo_lugar='finca', organizador='Colectivo Raíz',
             ciudad='Cali', departamento='Valle del Cauca', direccion='Km 12 Vía Jamundí',
             fecha_hora=timezone.now() + timedelta(days=7), capacidad_maxima=100,
             es_publica=True, codigo_acceso=codigo()),
    ]
    for f in fiestas:
        Fiesta.objects.create(**f)
    print('✅ 3 fiestas de prueba creadas.')
else:
    print('ℹ️  Ya existen fiestas en la base de datos.')
"
    echo -e "${GRN}✔ Setup completo.${NC}"
    echo ""
fi

# ── Migraciones pendientes ──
echo -e "${YLW}[db]${NC} Verificando migraciones..."
python manage.py migrate --run-syncdb 2>/dev/null || python manage.py migrate

# ── Lanzar servidor ──
echo ""
echo -e "${GRN}▶ Servidor corriendo en:${NC}"
echo -e "   ${YLW}http://127.0.0.1:${PORT}/${NC}              → Inicio"
echo -e "   ${YLW}http://127.0.0.1:${PORT}/invitados/${NC}    → Frontend 1: Gestión de invitados"
echo -e "   ${YLW}http://127.0.0.1:${PORT}/localizador/${NC}  → Frontend 2: Mapa localizador"
echo -e "   ${YLW}http://127.0.0.1:${PORT}/fiestas/api/${NC}  → REST API"
echo ""
echo -e "  Ctrl+C para detener."
echo ""

python manage.py runserver 0.0.0.0:${PORT}
