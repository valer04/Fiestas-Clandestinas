"""
FRONTEND 2: LOCALIZADOR DE FIESTAS
====================================
Interfaz de mapa para buscar fiestas por ciudad/código.
Revela la ubicación de fiestas privadas con código de acceso.

Corre en puerto 8002 (configurable).
"""
from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods

from core.business_logic.fiesta_service import FiestaService
from apps.fiestas.models import Fiesta

fiesta_service = FiestaService()


def mapa_fiestas(request):
    """
    Vista principal del Frontend 2.
    Muestra todas las fiestas activas en el mapa.
    """
    fiestas = fiesta_service.obtener_fiestas_activas()
    return render(request, 'localizador/mapa.html', {
        'fiestas': fiestas,
        'frontend': 'localizador',
    })


def buscar_fiestas(request):
    """
    GET ?q=<query>: Filtra fiestas por ciudad o nombre.
    """
    query = request.GET.get('q', '').strip()
    if query:
        fiestas = Fiesta.objects.filter(
            estado='activa'
        ).filter(
            ciudad__icontains=query
        ) | Fiesta.objects.filter(
            estado='activa'
        ).filter(
            nombre__icontains=query
        )
        fiestas = fiestas.distinct()
    else:
        fiestas = fiesta_service.obtener_fiestas_activas()

    return render(request, 'localizador/mapa.html', {
        'fiestas': fiestas,
        'query': query,
        'frontend': 'localizador',
    })


def revelar_ubicacion(request):
    """
    GET ?c=<codigo>: Revela la dirección de una fiesta privada
    si el código de acceso es correcto.
    """
    codigo = request.GET.get('c', '').strip().upper()
    fiesta = None
    error = None

    if codigo:
        try:
            fiesta = Fiesta.objects.get(codigo_acceso=codigo)
            if fiesta.estado == 'cancelada':
                error = 'Esta fiesta fue cancelada.'
                fiesta = None
        except Fiesta.DoesNotExist:
            error = f'Código "{codigo}" no corresponde a ninguna fiesta activa.'

    return render(request, 'localizador/revelar.html', {
        'codigo': codigo,
        'fiesta': fiesta,
        'error': error,
        'frontend': 'localizador',
    })


@require_http_methods(['GET'])
def api_fiestas_mapa(request):
    """
    GET /localizador/api/mapa/
    Devuelve JSON con fiestas activas y sus coordenadas.
    Útil para integrar con Leaflet u otro mapa JS externo.
    """
    fiestas = fiesta_service.obtener_fiestas_activas()
    data = []
    for f in fiestas:
        item = {
            'id': f.pk,
            'nombre': f.nombre,
            'ciudad': f.ciudad,
            'estado': f.estado,
            'cupos': f.cupos_disponibles,
            'fecha': f.fecha_hora.isoformat(),
            'es_publica': f.es_publica,
        }
        if f.es_publica:
            item['direccion'] = f.direccion
            item['lat'] = float(f.latitud) if f.latitud else None
            item['lng'] = float(f.longitud) if f.longitud else None
        data.append(item)

    return JsonResponse({'fiestas': data, 'total': len(data)})
