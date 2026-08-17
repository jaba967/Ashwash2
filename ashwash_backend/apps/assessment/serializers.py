from rest_framework import serializers
from .models import Questionnaire, Question, Option, AssessmentResult

class OptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Option
        fields = ['id', 'text_en', 'text_bn', 'score_value']

class QuestionSerializer(serializers.ModelSerializer):
    options = OptionSerializer(many=True, read_only=True)

    class Meta:
        model = Question
        fields = ['id', 'text_en', 'text_bn', 'order', 'options']

class QuestionnaireSerializer(serializers.ModelSerializer):
    questions = QuestionSerializer(many=True, read_only=True)

    class Meta:
        model = Questionnaire
        fields = ['id', 'title_en', 'title_bn', 'description_en', 'description_bn', 'category', 'questions']

class AssessmentResultSerializer(serializers.ModelSerializer):
    questionnaire_title = serializers.CharField(source='questionnaire.title_en', read_only=True)

    class Meta:
        model = AssessmentResult
        fields = ['id', 'questionnaire', 'questionnaire_title', 'total_score', 'severity_level', 'recommendations_en', 'recommendations_bn', 'created_at']
        read_only_fields = ['id', 'total_score', 'severity_level', 'recommendations_en', 'recommendations_bn', 'created_at']
