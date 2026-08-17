from django.db import migrations, models
from django.db import connection

def add_is_link_shared_if_not_exists(apps, schema_editor):
    table_name = 'appointments_appointment'
    column_name = 'is_link_shared'
    
    with connection.cursor() as cursor:
        try:
            columns = [col[0] for col in connection.introspection.get_table_description(cursor, table_name)]
        except Exception:
            return
            
        if column_name not in columns:
            try:
                # SQLite workaround for boolean default
                if connection.vendor == 'sqlite':
                    cursor.execute(f"ALTER TABLE {table_name} ADD COLUMN {column_name} bool DEFAULT 0 NOT NULL")
                else:
                    cursor.execute(f"ALTER TABLE {table_name} ADD COLUMN {column_name} boolean DEFAULT False NOT NULL")
            except Exception as e:
                print(f"Ignoring error adding column: {e}")

class Migration(migrations.Migration):

    dependencies = [
        ('appointments', '0004_alter_appointment_meeting_link_and_more'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(add_is_link_shared_if_not_exists, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.AddField(
                    model_name='appointment',
                    name='is_link_shared',
                    field=models.BooleanField(default=False),
                ),
            ]
        )
    ]
