# Changelog

All notable changes to this project are logged here by Claude Code.
Newest entries go at the top. Format: `YYYY-MM-DD HH:MM - summary`

## Unreleased
- 2026-07-24 - Created PoliceAssetTracker database, ran schema.sql (tables, RLS policy, seed data), created django_app SQL login with generated password (stored as DJANGO_APP_DB_PASSWORD env var, referenced via os.environ in settings.py), enabled SQL Server Mixed Mode auth, granted db_ddladmin to django_app so `migrate` can manage Django's own internal tables, and ran initial migrate (auth/admin/sessions/contenttypes).
- 2026-07-16 16:05 - Fixed manage.py to insert BASE_DIR into sys.path (needed because the project's embeddable Python distribution's ._pth file suppresses the interpreter's normal auto-add of the script directory).
- 2026-07-16 16:05 - Fixed SyntaxWarning in settings.py by making the SQL Server HOST value a raw string (r'localhost\SQLEXPRESS').
- 2026-07-16 16:00 - Project scaffolded: Django + mssql-django + pyodbc, SQL Server connection configured.
