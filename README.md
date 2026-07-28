# Asset Tracker

A Django app for tracking police department assets (radios, vehicles,
firearms, laptops, etc.) — checking them out to officers, recording
returns, and logging maintenance. Backed by SQL Server, with the schema
managed by hand in SQL rather than Django migrations.

## Stack

- Django (`config` project, `assets` app)
- SQL Server via `mssql-django` + `pyodbc`
- Plain server-rendered templates with a light/dark theme toggle

## Project layout

- `schema.sql` — creates the `PoliceAssetTracker` database objects: the
  `django_app` SQL login, the core tables (Precincts, Officers, Assets,
  Checkouts, MaintenanceLogs), and a row-level-security policy.
- `schema_002_allow_django_app_writes.sql` — follow-up fix exempting the
  shared `django_app` service account from that RLS policy (it only
  recognized per-officer SQL logins or `db_owner`, which blocked every
  app-side write).
- `assets/models.py` — Django models for the tables above, all
  `managed = False` since `schema.sql` is the source of truth for schema
  changes, not Django migrations.
- `assets/views.py` / `assets/urls.py` — the checkout / return /
  maintenance-logging workflow.
- `assets/templates/assets/` — the app's own pages (asset list, checkout
  form, maintenance form).
- `assets/templates/admin/base_site.html` — light styling tweaks to the
  Django admin (buttons instead of plain text links in the header and
  app index), left alone otherwise.
- `scripts/run_server.ps1` — starts the app for internal LAN use via
  `waitress` (see Deployment below).
- `scripts/setup_scheduled_task.ps1` — one-time setup that registers a
  Windows Scheduled Task so the app auto-starts on reboot.
- `scripts/add_firewall_rule.ps1` — one-time setup opening the app's port
  to other machines on the LAN.
- `CHANGELOG.md` — running log of changes, newest entries on top.

## Setup

1. Create and activate a virtualenv, then install dependencies:
   ```
   pip install django mssql-django pyodbc
   ```
2. Run `schema.sql` (then `schema_002_allow_django_app_writes.sql`)
   against SQL Server in SSMS to create the database, tables, and the
   `django_app` login.
3. Set the `django_app` password as an environment variable before
   running any `manage.py` command:
   ```
   set DJANGO_APP_DB_PASSWORD=<password>
   ```
4. Apply Django's own migrations (auth, sessions, admin, contenttypes —
   the business tables already exist via `schema.sql` and are unmanaged):
   ```
   python manage.py migrate
   ```
5. Create an admin user and run the dev server:
   ```
   python manage.py createsuperuser
   python manage.py runserver
   ```

## Deployment (internal LAN, this server)

This runs directly on the machine that hosts SQL Server rather than a
public cloud host — the database only exists on this network, and the
data (officer names, badge numbers, firearm assignments) shouldn't be
exposed to the internet.

1. Environment variables (set once as user env vars — see `settings.py`
   for how each is used): `DJANGO_APP_DB_PASSWORD`, `DJANGO_SECRET_KEY`,
   `DJANGO_DEBUG` (`False`), `DJANGO_ALLOWED_HOSTS` (this machine's LAN
   IP, plus `localhost,127.0.0.1`).
2. `python manage.py collectstatic --noinput`
3. Start command: `scripts/run_server.ps1`, which runs
   `python -m waitress --host=0.0.0.0 --port=8000 config.wsgi:application`.
4. One-time: run `scripts/setup_scheduled_task.ps1` and
   `scripts/add_firewall_rule.ps1` from an elevated PowerShell, so the
   app auto-starts on reboot and is reachable from other machines on the
   LAN at `http://<this machine's LAN IP>:8000/assets/`.

## Using it

- `/assets/` — the asset list. Filter by status/category, check assets
  out to an officer, return them, or send them to maintenance.
- `/admin/` — full CRUD over all five tables (Precincts, Officers,
  Assets, Checkouts, Maintenance logs), plus user/group management.

## Notes

- SQL Server must be configured for Mixed Mode authentication (SQL
  Server + Windows Authentication) — Windows-only auth mode will reject
  the `django_app` SQL login regardless of password.
- Schema changes (new tables/columns) should be written as new numbered
  `.sql` files and run in SSMS, then reflected in `assets/models.py` with
  `managed = False` — see `CLAUDE.md` for the full convention.
