import os

apps = [
    ('mood_tracker', ['MoodLog']),
    ('payments', ['PaymentTransaction'])
]

base_path = r'C:\Users\WALTON\.gemini\antigravity\scratch\Ashwash\ashwash_backend\apps'

for app, models in apps:
    admin_file = os.path.join(base_path, app, 'admin.py')
    with open(admin_file, 'w') as f:
        f.write('from django.contrib import admin\n')
        f.write('from .models import ' + ', '.join(models) + '\n\n')
        for model in models:
            f.write(f'admin.site.register({model})\n')
    print(f'Created {admin_file}')
