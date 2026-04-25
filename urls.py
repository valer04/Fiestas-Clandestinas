"""
URL Configuration for fiestas-clandestinas monolith.

Routes:
  /           -> API principal + home
  /fiestas/   -> Gestión de fiestas (CRUD)
  /invitados/ -> Frontend 1: gestión de invitados
  /localizar/ -> Frontend 2: localización de fiestas
  /api/       -> REST API endpoints
  /admin/     -> Django admin
"""
from django.contrib import admin
from django.urls import path, include
from django.shortcuts import redirect

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', lambda r: redirect('fiestas:home'), name='root'),
    path('fiestas/', include('apps.fiestas.urls', namespace='fiestas')),
    path('invitados/', include('apps.invitados.urls', namespace='invitados')),
    path('localizar/', include('apps.localizador.urls', namespace='localizador')),
]
