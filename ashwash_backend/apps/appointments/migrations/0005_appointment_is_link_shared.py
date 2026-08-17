from django.db import migrations, models

def add_is_link_shared_if_not_exists(apps, schema_editor):
    Appointment = apps.get_model('appointments', 'Appointment')
    db_table = Appointment._meta.db_table
    
    # Check if the column exists in the database
    with schema_editor.connection.cursor() as cursor:
        try:
            columns = [col[0] for col in schema_editor.connection.introspection.get_table_description(cursor, db_table)]
        except Exception:
            return # Table might not exist yet if running tests or new db
            
        if 'is_link_shared' not in columns:
            field = Appointment._meta.get_field('is_link_shared')
            schema_editor.add_field(Appointment, field)

class Migration(migrations.Migration):

    dependencies = [
        ('appointments', '0004_alter_appointment_meeting_link_and_more'),
    ]

    operations = [
        migrations.RunPython(add_is_link_shared_if_not_exists, reverse_code=migrations.RunPython.noop, state_operations=[
            migrations.AddField(
                model_name='appointment',
                name='is_link_shared',
                field=models.BooleanField(default=False),
            ),
        ])
    ]
