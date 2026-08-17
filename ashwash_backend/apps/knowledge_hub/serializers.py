from rest_framework import serializers
from .models import Resource

class ResourceSerializer(serializers.ModelSerializer):
    effective_media_url = serializers.SerializerMethodField()

    class Meta:
        model = Resource
        fields = [
            'id', 'title_en', 'title_bn', 'summary_en', 'summary_bn',
            'content_en', 'content_bn', 'resource_type', 'media_url',
            'media_file', 'effective_media_url', 'duration_minutes', 'is_premium', 'created_at'
        ]

    def get_effective_media_url(self, obj):
        if obj.media_url and obj.media_url.strip():
            return obj.media_url.strip()
        if obj.media_file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.media_file.url)
            return obj.media_file.url
        return 'https://www.globalfamilydoctor.com/site/DefaultSite/filesystem/documents/resources/MHGuidebook-EBookDownload.pdf'

