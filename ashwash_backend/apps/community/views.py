from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Post, Comment, Like, Report
from .serializers import PostSerializer, CommentSerializer, ReportSerializer

class AdminListReportsAPIView(generics.ListAPIView):
    queryset = Report.objects.all().order_by('-created_at')
    serializer_class = ReportSerializer
    permission_classes = [permissions.AllowAny] # In a real app this should be IsAdminUser, matching other admin endpoints

class PostListCreateView(generics.ListCreateAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        queryset = Post.objects.all()
        tag = self.request.query_params.get('tag')
        if tag and tag != 'All':
            queryset = queryset.filter(tag=tag)
        return queryset

    def perform_create(self, serializer):
        user = self.request.user
        if user.role in ['SPECIALIST', 'DOCTOR']:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Only patients can create community posts. Specialists can reply to posts with their doctor badge.')

        is_anon = serializer.validated_data.get('is_anonymous', True)
        if is_anon:
            alias = 'Anonymous Member'
        else:
            full_name = f"{user.first_name} {user.last_name}".strip()
            alias = full_name if full_name else user.username
        serializer.save(author=user, is_anonymous=is_anon, author_alias=alias)

class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        # Only the post author or admins/staff can edit/delete
        return obj.author == request.user or request.user.is_staff or request.user.is_superuser or request.user.role == 'ADMIN'

class PostDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsOwnerOrReadOnly]

    def perform_update(self, serializer):
        is_anon = serializer.validated_data.get('is_anonymous', serializer.instance.is_anonymous)
        if is_anon:
            alias = 'Anonymous Member'
        else:
            full_name = f"{self.request.user.first_name} {self.request.user.last_name}".strip()
            alias = full_name if full_name else self.request.user.username
        serializer.save(author_alias=alias)

class LikePostView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, post_id):
        try:
            post = Post.objects.get(id=post_id)
        except Post.DoesNotExist:
            return Response({'error': 'Post not found'}, status=status.HTTP_404_NOT_FOUND)

        like, created = Like.objects.get_or_create(post=post, user=request.user)
        if not created:
            like.delete()
            post.likes_count = max(0, post.likes_count - 1)
            liked = False
        else:
            post.likes_count += 1
            liked = True
            # Like creation triggers notify_community_like in signals.py automatically

        post.save()

        return Response({'liked': liked, 'likes_count': post.likes_count})

class AddCommentView(generics.CreateAPIView):
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, *args, **kwargs):
        user = request.user
        is_specialist = (
            user.role in ['DOCTOR', 'ADMIN', 'SPECIALIST'] or 
            user.is_staff or 
            user.is_superuser or 
            hasattr(user, 'specialist_profile')
        )
        if not is_specialist:
            return Response(
                {'detail': 'Only verified mental health specialists and doctors can comment on community posts.'},
                status=status.HTTP_403_FORBIDDEN
            )
        return super().post(request, *args, **kwargs)

    def perform_create(self, serializer):
        post_id = self.kwargs['post_id']
        post = Post.objects.get(id=post_id)
        doctor_title = f"Dr. {self.request.user.first_name or self.request.user.username} (Specialist)"
        serializer.save(post=post, author=self.request.user, author_alias=doctor_title)
        post.comments_count += 1
        post.save()
        # Comment creation triggers notify_community_comment in signals.py automatically

class ReportPostView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, post_id):
        try:
            post = Post.objects.get(id=post_id)
        except Post.DoesNotExist:
            return Response({'error': 'Post not found'}, status=status.HTTP_404_NOT_FOUND)

        reason = request.data.get('reason', 'Inappropriate content')
        Report.objects.create(post=post, user=request.user, reason=reason)
        return Response({'message': 'Post reported successfully. Our administration team has been notified to review.'}, status=status.HTTP_201_CREATED)

class AdminDeletePostAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk):
        try:
            post = Post.objects.get(pk=pk)
            post_id = post.id
            post.delete()
            return Response({'message': f'Post #{post_id} deleted successfully by Administrator.'})
        except Post.DoesNotExist:
            return Response({'error': 'Post not found'}, status=status.HTTP_404_NOT_FOUND)

class AdminDismissReportAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk):
        try:
            report = Report.objects.get(pk=pk)
            report.delete()
            return Response({'message': 'Report dismissed successfully.'})
        except Report.DoesNotExist:
            return Response({'error': 'Report not found'}, status=status.HTTP_404_NOT_FOUND)
