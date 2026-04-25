# Fiestas Clandestinas
Ejercicio #5 de Diseno de Software 2026-I

Estructura y Workflow
Primera vez:
  ./setup.sh        → crea venv, migra, carga 3 fiestas de prueba

Desde ahí:
  ./run.sh          → http://127.0.0.1:8000

Rutas principales:
  /                          → home con grid de fiestas
  /fiestas/crear/            → publicar fiesta nueva
  /fiestas/<id>/             → detalle de fiesta
  /invitados/                → Frontend 1: panel de gestión
  /invitados/<id>/gestionar/ → aceptar/rechazar solicitudes
  /localizador/              → Frontend 2: mapa
  /localizador/revelar/?c=XX → revelar ubicación con código
  /fiestas/api/fiestas/      → REST API


Requisitos


Instalacion/Setup
#!/bin/bash
# =============================================================
# setup.sh — Fiestas Clandestinas
# Configura el proyecto desde cero (primera vez).
#
# Uso: ./setup.sh
# =============================================================

set -e
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

GRN='\033[0;32m'
YLW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YLW}[1/5]${NC} Creando entorno virtual..."
python3 -m venv venv
source venv/bin/activate

echo -e "${YLW}[2/5]${NC} Instalando dependencias..."
pip install -q -r requirements.txt

echo -e "${YLW}[3/5]${NC} Generando migraciones..."
python manage.py makemigrations fiestas
python manage.py makemigrations

echo -e "${YLW}[4/5]${NC} Aplicando migraciones..."
python manage.py migrate

echo -e "${YLW}[5/5]${NC} Cargando datos de prueba..."
python manage.py shell << 'EOF'
from apps.fiestas.models import Fiesta
from django.utils import timezone
from datetime import timedelta
import random, string

def gen_codigo():
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

fiestas_data = [
    {
        'nombre': 'Noche Salvaje Vol. 3',
        'tipo_lugar': 'casa',
        'organizador': 'DJ Fantasma',
        'ciudad': 'Bogotá',
        'departamento': 'Cundinamarca',
        'direccion': 'Calle 45 # 12-30, Chapinero',
        'latitud': 4.6534,
        'longitud': -74.0656,
        'fecha_hora': timezone.now() + timedelta(days=3),
        'capacidad_maxima': 60,
        'es_publica': True,
        'codigo_acceso': gen_codigo(),
        'descripcion': 'House, techno y cosas raras. Código de vestimenta: oscuro.',
        'contacto': '@djfantasma',
    },
    {
        'nombre': 'La Clandestina del Sótano',
        'tipo_lugar': 'local',
        'organizador': 'El Comité',
        'ciudad': 'Medellín',
        'departamento': 'Antioquia',
        'direccion': 'Carrera 70 # 44-18, Laureles',
        'fecha_hora': timezone.now() + timedelta(days=1),
        'capacidad_maxima': 40,
        'es_publica': False,
        'codigo_acceso': gen_codigo(),
        'descripcion': 'Solo con invitación. Pregunta a quien ya sabe.',
    },
    {
        'nombre': 'Finca Roots Session',
        'tipo_lugar': 'finca',
        'organizador': 'Colectivo Raíz',
        'ciudad': 'Cali',
        'departamento': 'Valle del Cauca',
        'direccion': 'Km 12 Vía Jamundí',
        'latitud': 3.3101,
        'longitud': -76.5351,
        'fecha_hora': timezone.now() + timedelta(days=7),
        'capacidad_maxima': 100,
        'es_publica': True,
        'codigo_acceso': gen_codigo(),
        'descripcion': 'Reggae, afrobeat y cumbia experimental. Traer carpas y buen ánimo.',
        'contacto': '@colectivoraiz',
    },
]

print("\n📋 Fiestas creadas:")
for datos in fiestas_data:
    f, created = Fiesta.objects.get_or_create(nombre=datos['nombre'], defaults=datos)
    status = "✅ Creada" if created else "⏭  Ya existe"
    print(f"  {status}: {f.nombre} — Código: {f.codigo_acceso}")

print()
EOF

echo ""
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GRN}✔ Setup completo. Ejecuta para iniciar:${NC}"
echo ""
echo -e "   ${YLW}./run.sh${NC}"
echo ""
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



Scripts
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
