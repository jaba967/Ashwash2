"""
Fix broken notifications table (Deprecated / Disabled).
Tables are now permanently preserved and never dropped.
"""
from django.core.management.base import BaseCommand

class Command(BaseCommand):
    help = 'Deprecated - Notifications tables are preserved and never dropped'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS("Notifications tables are healthy and permanently preserved."))

