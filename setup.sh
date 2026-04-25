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
