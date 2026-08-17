from django.urls import path
from .views import (
    QuestionnaireListView, QuestionnaireDetailView, SubmitAssessmentView, UserAssessmentHistoryView
)

urlpatterns = [
    path('questionnaires/', QuestionnaireListView.as_view(), name='questionnaires_list'),
    path('questionnaires/<int:pk>/', QuestionnaireDetailView.as_view(), name='questionnaire_detail'),
    path('submit/', SubmitAssessmentView.as_view(), name='submit_assessment'),
    path('history/', UserAssessmentHistoryView.as_view(), name='assessment_history'),
]
