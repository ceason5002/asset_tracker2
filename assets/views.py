from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone

from .models import Asset, Checkout, MaintenanceLog, Officer

STATUS_CHOICES = ['Available', 'Checked Out', 'Maintenance', 'Retired']


@login_required
def asset_list(request):
    assets = Asset.objects.select_related('precinct').order_by('asset_tag')

    status = request.GET.get('status', '')
    category = request.GET.get('category', '')

    if status:
        assets = assets.filter(status=status)
    if category:
        assets = assets.filter(category=category)

    categories = Asset.objects.order_by('category').values_list('category', flat=True).distinct()

    return render(request, 'assets/asset_list.html', {
        'assets': assets,
        'status_filter': status,
        'category_filter': category,
        'status_choices': STATUS_CHOICES,
        'categories': categories,
    })


@login_required
def checkout_asset(request, asset_id):
    asset = get_object_or_404(Asset, pk=asset_id)

    if asset.status != 'Available':
        messages.error(request, f'{asset.asset_tag} is not available to check out.')
        return redirect('assets:asset_list')

    officers = Officer.objects.filter(is_active=True).order_by('last_name', 'first_name')

    if request.method == 'POST':
        officer_id = request.POST.get('officer_id')
        notes = request.POST.get('notes', '').strip()
        officer = get_object_or_404(Officer, pk=officer_id, is_active=True)

        Checkout.objects.create(
            asset=asset,
            officer=officer,
            checked_out_at=timezone.now(),
            notes=notes or None,
        )
        asset.status = 'Checked Out'
        asset.save(update_fields=['status'])

        messages.success(request, f'{asset.asset_tag} checked out to {officer}.')
        return redirect('assets:asset_list')

    return render(request, 'assets/checkout_form.html', {
        'asset': asset,
        'officers': officers,
    })


@login_required
def return_asset(request, checkout_id):
    checkout = get_object_or_404(Checkout, pk=checkout_id, returned_at__isnull=True)

    if request.method == 'POST':
        checkout.returned_at = timezone.now()
        checkout.save(update_fields=['returned_at'])

        asset = checkout.asset
        asset.status = 'Available'
        asset.save(update_fields=['status'])

        messages.success(request, f'{asset.asset_tag} returned by {checkout.officer}.')

    return redirect('assets:asset_list')


@login_required
def log_maintenance(request, asset_id):
    asset = get_object_or_404(Asset, pk=asset_id)

    if asset.status != 'Available':
        messages.error(request, f'{asset.asset_tag} must be Available to send it to maintenance.')
        return redirect('assets:asset_list')

    if request.method == 'POST':
        performed_by = request.POST.get('performed_by', '').strip()
        description = request.POST.get('description', '').strip()
        next_due_date = request.POST.get('next_due_date') or None

        MaintenanceLog.objects.create(
            asset=asset,
            performed_at=timezone.now(),
            performed_by=performed_by,
            description=description,
            next_due_date=next_due_date,
        )
        asset.status = 'Maintenance'
        asset.save(update_fields=['status'])

        messages.success(request, f'{asset.asset_tag} sent to maintenance.')
        return redirect('assets:asset_list')

    return render(request, 'assets/maintenance_form.html', {
        'asset': asset,
        'default_performed_by': request.user.get_username(),
    })


@login_required
def complete_maintenance(request, asset_id):
    asset = get_object_or_404(Asset, pk=asset_id, status='Maintenance')

    if request.method == 'POST':
        asset.status = 'Available'
        asset.save(update_fields=['status'])
        messages.success(request, f'{asset.asset_tag} marked Available.')

    return redirect('assets:asset_list')
