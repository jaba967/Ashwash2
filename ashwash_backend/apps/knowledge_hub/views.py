from rest_framework import generics, permissions
from .models import Resource
from .serializers import ResourceSerializer

class ResourceListView(generics.ListCreateAPIView):
    serializer_class = ResourceSerializer
    permission_classes = [permissions.AllowAny]

    def get_permissions(self):
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        queryset = Resource.objects.all()
        res_type = self.request.query_params.get('type')
        is_premium = self.request.query_params.get('is_premium')

        if res_type and res_type != 'all':
            queryset = queryset.filter(resource_type=res_type)
        if is_premium is not None:
            queryset = queryset.filter(is_premium=(is_premium.lower() == 'true'))

        return queryset

    def perform_create(self, serializer):
        media_file = self.request.FILES.get('media_file')
        media_url = self.request.data.get('media_url', '')
        serializer.save(media_file=media_file, media_url=media_url)

class ResourceDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Resource.objects.all()
    serializer_class = ResourceSerializer
    permission_classes = [permissions.AllowAny]

