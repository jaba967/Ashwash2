from rest_framework import serializers
from .models import PaymentTransaction

class PaymentTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentTransaction
        fields = ['id', 'user', 'method', 'amount', 'purpose', 'transaction_id', 'status', 'created_at']
        read_only_fields = ['id', 'user', 'transaction_id', 'status', 'created_at']
