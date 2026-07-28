from django.contrib import admin

from .models import Asset, Checkout, MaintenanceLog, Officer, Precinct

admin.site.site_header = 'Police Asset Tracker'
admin.site.site_title = 'Police Asset Tracker'
admin.site.index_title = 'Administration'


@admin.register(Precinct)
class PrecinctAdmin(admin.ModelAdmin):
    list_display = ('name', 'code')
    search_fields = ('name', 'code')


@admin.register(Officer)
class OfficerAdmin(admin.ModelAdmin):
    list_display = ('badge_number', 'first_name', 'last_name', 'precinct', 'is_active')
    list_filter = ('precinct', 'is_active')
    search_fields = ('badge_number', 'first_name', 'last_name')


@admin.register(Asset)
class AssetAdmin(admin.ModelAdmin):
    list_display = ('asset_tag', 'description', 'category', 'precinct', 'status')
    list_filter = ('category', 'status', 'precinct')
    search_fields = ('asset_tag', 'description')


@admin.register(Checkout)
class CheckoutAdmin(admin.ModelAdmin):
    list_display = ('asset', 'officer', 'checked_out_at', 'returned_at')
    list_filter = ('checked_out_at', 'returned_at')
    search_fields = ('asset__asset_tag', 'officer__badge_number')


@admin.register(MaintenanceLog)
class MaintenanceLogAdmin(admin.ModelAdmin):
    list_display = ('asset', 'performed_at', 'performed_by', 'next_due_date')
    list_filter = ('performed_at', 'next_due_date')
    search_fields = ('asset__asset_tag', 'performed_by')
