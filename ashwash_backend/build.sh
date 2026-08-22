#!/usr/bin/env bash
# Exit on error
set -o errexit

pip install -r requirements.txt
python manage.py collectstatic --no-input
python manage.py migrate
python force_admin.py
python seed_db.py || echo "Seed script failed or skipped"
