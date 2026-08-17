from django.urls import path
from .views import (
    InitiatePaymentView, UserPaymentHistoryView,
    bKashExecutePaymentAPIView, NagadExecutePaymentAPIView
)

urlpatterns = [
    path('initiate/', InitiatePaymentView.as_view(), name='initiate_payment'),
    path('history/', UserPaymentHistoryView.as_view(), name='payment_history'),
    path('bkash/execute/', bKashExecutePaymentAPIView.as_view(), name='bkash_execute_payment'),
    path('nagad/execute/', NagadExecutePaymentAPIView.as_view(), name='nagad_execute_payment'),
]
