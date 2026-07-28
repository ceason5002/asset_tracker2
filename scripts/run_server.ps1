# Starts the Asset Tracker app for internal LAN use with waitress.
# Expects DJANGO_APP_DB_PASSWORD, DJANGO_SECRET_KEY, DJANGO_DEBUG, and
# DJANGO_ALLOWED_HOSTS to already be set as user environment variables
# (see README.md). Not meant to be run outside this machine as-is.

$python = "$env:USERPROFILE\python312\python.exe"
$projectDir = Split-Path -Parent $PSScriptRoot

Set-Location $projectDir
& $python -m waitress --host=0.0.0.0 --port=8000 config.wsgi:application
