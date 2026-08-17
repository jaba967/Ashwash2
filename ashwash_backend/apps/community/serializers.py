from rest_framework import serializers
from .models import Post, Comment, Like, Report

class CommentSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()
    is_doctor = serializers.SerializerMethodField()
    author_role = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = ['id', 'post', 'author', 'author_name', 'author_alias', 'author_role', 'is_doctor', 'content', 'created_at']
        read_only_fields = ['id', 'post', 'author', 'author_alias', 'created_at']

    def get_author_name(self, obj):
        if obj.author:
            fn = f"{obj.author.first_name} {obj.author.last_name}".strip()
            return fn if fn else obj.author.username
        return obj.author_alias

    def get_is_doctor(self, obj):
        return bool(obj.author and (obj.author.role in ['SPECIALIST', 'DOCTOR', 'ADMIN'] or obj.author.is_staff))

    def get_author_role(self, obj):
        return obj.author.role if obj.author else 'PATIENT'

class PostSerializer(serializers.ModelSerializer):
    comments = CommentSerializer(many=True, read_only=True)
    is_liked = serializers.SerializerMethodField()
    is_owner = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id', 'author', 'author_alias', 'content', 'tag', 'is_anonymous',
            'likes_count', 'comments_count', 'is_liked', 'is_owner', 'created_at', 'comments'
        ]
        read_only_fields = ['id', 'author', 'likes_count', 'comments_count', 'created_at']

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Like.objects.filter(post=obj, user=request.user).exists()
        return False

    def get_is_owner(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.author == request.user
        return False

class ReportSerializer(serializers.ModelSerializer):
    reporter_name = serializers.SerializerMethodField()
    post_content = serializers.CharField(source='post.content', read_only=True)
    post_author_alias = serializers.CharField(source='post.author_alias', read_only=True)

    class Meta:
        model = Report
        fields = ['id', 'post', 'post_content', 'post_author_alias', 'user', 'reporter_name', 'reason', 'created_at']

    def get_reporter_name(self, obj):
        if obj.user:
            fn = f"{obj.user.first_name} {obj.user.last_name}".strip()
            return fn if fn else obj.user.username
        return "Unknown"
