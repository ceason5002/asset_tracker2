#!/usr/bin/env bash
# setup_django_project.sh
# Scaffolds a Django project wired for SQL Server (Express, named instance).
# Run this from inside Claude Code with: "run setup_django_project.sh"
# or directly: bash setup_django_project.sh

set -e  # stop on first error

PROJECT_NAME="config"
APP_NAME="assets"
DB_NAME="PoliceAssetTracker"
DB_USER="django_app"
DB_HOST="localhost\\SQLEXPRESS"   # update if your instance name differs

echo ">>> Creating virtual environment..."
python -m venv venv

echo ">>> Activating virtual environment..."
source venv/Scripts/activate 2>/dev/null || source venv/bin/activate

echo ">>> Installing packages..."
pip install django mssql-django pyodbc

echo ">>> Starting Django project and app..."
django-admin startproject "$PROJECT_NAME" .
python manage.py startapp "$APP_NAME"

echo ">>> Writing SQL Server database config into settings.py..."
SETTINGS_FILE="$PROJECT_NAME/settings.py"
python3 - "$SETTINGS_FILE" "$DB_NAME" "$DB_USER" "$DB_HOST" "$APP_NAME" <<'PYEOF'
import re, sys

settings_file, db_name, db_user, db_host, app_name = sys.argv[1:6]

with open(settings_file, "r") as f:
    content = f.read()

# Replace default sqlite3 DATABASES block
new_db_block = f'''DATABASES = {{
    'default': {{
        'ENGINE': 'mssql',
        'NAME': '{db_name}',
        'USER': '{db_user}',
        'PASSWORD': 'CHANGE_ME',  # move to an environment variable before committing
        'HOST': '{db_host}',
        'PORT': '',
        'OPTIONS': {{
            'driver': 'ODBC Driver 18 for SQL Server',
            'extra_params': 'TrustServerCertificate=yes;',
        }},
    }}
}}'''

content = re.sub(
    r"DATABASES = \{.*?\n\}",
    new_db_block,
    content,
    flags=re.DOTALL,
)

# Register the app
content = content.replace(
    "INSTALLED_APPS = [",
    f"INSTALLED_APPS = [\n    '{app_name}',",
)

with open(settings_file, "w") as f:
    f.write(content)

print(f"Updated {settings_file}")
PYEOF

echo ">>> Creating CHANGELOG.md..."
cat > CHANGELOG.md <<'EOF'
# Changelog

All notable changes to this project are logged here by Claude Code.
Newest entries go at the top. Format: `YYYY-MM-DD HH:MM - summary`

## Unreleased
- Project scaffolded: Django + mssql-django + pyodbc, SQL Server connection configured.
EOF

echo ">>> Running initial Django migrations (auth, sessions, etc. only)..."
python manage.py migrate

echo ""
echo "Done. Next steps:"
echo "1. Update the PASSWORD field in $PROJECT_NAME/settings.py (or move to env var)."
echo "2. Build your tables in SSMS using schema.sql."
echo "3. Run: python manage.py inspectdb > $APP_NAME/models.py"
echo "4. Set managed = False on each generated model."
