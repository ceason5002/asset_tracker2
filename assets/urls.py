from django.urls import path

from . import views

app_name = 'assets'

urlpatterns = [
    path('', views.asset_list, name='asset_list'),
    path('<int:asset_id>/checkout/', views.checkout_asset, name='checkout_asset'),
    path('checkouts/<int:checkout_id>/return/', views.return_asset, name='return_asset'),
]
