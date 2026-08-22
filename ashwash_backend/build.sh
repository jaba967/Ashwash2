#!/usr/bin/env bash
# Exit on error
set -o errexit

pip install -r requirements.txt
python manage.py collectstatic --no-input
python manage.py migrate

# LOAD BACKUP DATA
echo "Loading database backup..."
python manage.py loaddata backup7.json || echo "Loaddata failed but continuing"

# RESET POSTGRES SEQUENCES
echo "Resetting PostgreSQL sequences..."
python manage.py sqlsequencereset admin auth contenttypes sessions authtoken courses dashboard notifications community | python manage.py dbshell || echo "Sequence reset failed"

python force_admin.py
python seed_db.py || echo "Seed script failed or skipped"
