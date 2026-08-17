from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Questionnaire, Option, AssessmentResult
from .serializers import QuestionnaireSerializer, AssessmentResultSerializer

class QuestionnaireListView(generics.ListAPIView):
    queryset = Questionnaire.objects.all()
    serializer_class = QuestionnaireSerializer
    permission_classes = [permissions.AllowAny]

class QuestionnaireDetailView(generics.RetrieveAPIView):
    queryset = Questionnaire.objects.all()
    serializer_class = QuestionnaireSerializer
    permission_classes = [permissions.AllowAny]

class SubmitAssessmentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        questionnaire_id = request.data.get('questionnaire_id')
        selected_option_ids = request.data.get('selected_option_ids', [])

        try:
            questionnaire = Questionnaire.objects.get(id=questionnaire_id)
        except Questionnaire.DoesNotExist:
            return Response({'error': 'Questionnaire not found'}, status=status.HTTP_404_NOT_FOUND)

        options = Option.objects.filter(id__in=selected_option_ids)
        total_score = sum([opt.score_value for opt in options])

        if total_score <= 5:
            severity = 'Mild'
            rec_en = 'Your stress level is low. Practice daily mindfulness and light wellness exercises.'
            rec_bn = 'আপনার মানসিক চাপের মাত্রা কম। প্রতিদিনের মাইন্ডফুলনেস এবং হালকা ব্যায়াম চর্চা করুন।'
        elif total_score <= 12:
            severity = 'Moderate'
            rec_en = 'Moderate stress detected. We recommend exploring our guided courses and meditation audio.'
            rec_bn = 'মাঝারি মানসিক চাপ পরিলক্ষিত হয়েছে। আমাদের গাইডেড কোর্স এবং মেডিটেশন অডিওগুলো দেখার পরামর্শ দেয়া হচ্ছে।'
        else:
            severity = 'High'
            rec_en = 'High stress levels indicated. Consider booking a session with one of our specialized professionals.'
            rec_bn = 'উচ্চ মানসিক চাপ নির্দেশিত। আমাদের বিশেষজ্ঞ প্রফেশনালের সাথে সেশন বুক করার পরামর্শ দেয়া হচ্ছে।'

        result = AssessmentResult.objects.create(
            user=request.user,
            questionnaire=questionnaire,
            total_score=total_score,
            severity_level=severity,
            recommendations_en=rec_en,
            recommendations_bn=rec_bn
        )

        return Response(AssessmentResultSerializer(result).data, status=status.HTTP_201_CREATED)

class UserAssessmentHistoryView(generics.ListAPIView):
    serializer_class = AssessmentResultSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return AssessmentResult.objects.filter(user=self.request.user)
