from django.db import models


class Precinct(models.Model):
    precinct_id = models.AutoField(db_column='PrecinctId', primary_key=True)
    name = models.CharField(db_column='Name', max_length=100)
    code = models.CharField(db_column='Code', max_length=10, unique=True)

    class Meta:
        managed = False
        db_table = 'Precincts'

    def __str__(self):
        return self.name


class Officer(models.Model):
    officer_id = models.AutoField(db_column='OfficerId', primary_key=True)
    badge_number = models.CharField(db_column='BadgeNumber', max_length=20, unique=True)
    first_name = models.CharField(db_column='FirstName', max_length=50)
    last_name = models.CharField(db_column='LastName', max_length=50)
    precinct = models.ForeignKey(Precinct, models.DO_NOTHING, db_column='PrecinctId', related_name='officers')
    db_user_name = models.CharField(db_column='DbUserName', max_length=128)
    is_active = models.BooleanField(db_column='IsActive')

    class Meta:
        managed = False
        db_table = 'Officers'

    def __str__(self):
        return f'{self.first_name} {self.last_name} ({self.badge_number})'


class Asset(models.Model):
    asset_id = models.AutoField(db_column='AssetId', primary_key=True)
    asset_tag = models.CharField(db_column='AssetTag', max_length=30, unique=True)
    description = models.CharField(db_column='Description', max_length=200)
    category = models.CharField(db_column='Category', max_length=50)
    precinct = models.ForeignKey(Precinct, models.DO_NOTHING, db_column='PrecinctId', related_name='assets')
    status = models.CharField(db_column='Status', max_length=20)
    purchase_date = models.DateField(db_column='PurchaseDate', blank=True, null=True)
    last_maintained = models.DateField(db_column='LastMaintained', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Assets'

    def __str__(self):
        return f'{self.asset_tag} - {self.description}'


class Checkout(models.Model):
    checkout_id = models.AutoField(db_column='CheckoutId', primary_key=True)
    asset = models.ForeignKey(Asset, models.DO_NOTHING, db_column='AssetId', related_name='checkouts')
    officer = models.ForeignKey(Officer, models.DO_NOTHING, db_column='OfficerId', related_name='checkouts')
    checked_out_at = models.DateTimeField(db_column='CheckedOutAt')
    returned_at = models.DateTimeField(db_column='ReturnedAt', blank=True, null=True)
    notes = models.CharField(db_column='Notes', max_length=500, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Checkouts'

    def __str__(self):
        return f'{self.asset.asset_tag} -> {self.officer.badge_number}'


class MaintenanceLog(models.Model):
    maintenance_id = models.AutoField(db_column='MaintenanceId', primary_key=True)
    asset = models.ForeignKey(Asset, models.DO_NOTHING, db_column='AssetId', related_name='maintenance_logs')
    performed_at = models.DateTimeField(db_column='PerformedAt')
    performed_by = models.CharField(db_column='PerformedBy', max_length=100)
    description = models.CharField(db_column='Description', max_length=500)
    next_due_date = models.DateField(db_column='NextDueDate', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'MaintenanceLogs'

    def __str__(self):
        return f'{self.asset.asset_tag} - {self.performed_at:%Y-%m-%d}'
