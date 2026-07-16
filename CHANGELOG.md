# Changelog

All notable changes to this project are logged here by Claude Code.
Newest entries go at the top. Format: `YYYY-MM-DD HH:MM - summary`

## Unreleased
- 2026-07-16 16:05 - Fixed manage.py to insert BASE_DIR into sys.path (needed because the project's embeddable Python distribution's ._pth file suppresses the interpreter's normal auto-add of the script directory).
- 2026-07-16 16:05 - Fixed SyntaxWarning in settings.py by making the SQL Server HOST value a raw string (r'localhost\SQLEXPRESS').
- 2026-07-16 16:00 - Project scaffolded: Django + mssql-django + pyodbc, SQL Server connection configured.
