import os
import django
import sys
import requests

# Setup Django Environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ashwash_backend.settings')
django.setup()

from apps.courses.models import Course, Lesson
from apps.knowledge_hub.models import Resource

CLOUD_NAME = 'a6cztdgv'
UPLOAD_PRESET = 'ashwash_upload'
UPLOAD_URL = f'https://api.cloudinary.com/v1_1/{CLOUD_NAME}/raw/upload'

def upload_to_cloudinary(file_content, filename):
    try:
        files = {
            'file': (filename, file_content)
        }
        data = {
            'upload_preset': UPLOAD_PRESET
        }
        res = requests.post(UPLOAD_URL, files=files, data=data)
        if res.status_code == 200:
            return res.json().get('secure_url')
        else:
            print(f"    [!] Cloudinary upload failed: {res.text}")
            return None
    except Exception as e:
        print(f"    [!] Error uploading: {e}")
        return None

def process_url(url, local_file_path=None):
    if not url and not local_file_path:
        return None

    is_pdf = False
    
    # Check if it's a PDF by URL or file path extension
    if url and url.lower().endswith('.pdf'):
        is_pdf = True
    elif local_file_path and local_file_path.lower().endswith('.pdf'):
        is_pdf = True
        
    if not is_pdf:
        # Not a PDF, skip
        return None

    # Condition 1: If it's already a Cloudinary raw upload, skip
    if url and 'res.cloudinary.com' in url and '/raw/upload/' in url:
        return None
        
    # Condition 2: If it's a Cloudinary image upload PDF, we must migrate
    if url and 'res.cloudinary.com' in url and '/image/upload/' in url:
        print(f"    [*] Found Cloudinary image/upload PDF: {url}")
        try:
            r = requests.get(url)
            if r.status_code == 200:
                print("    [*] Downloaded successfully, migrating to raw/upload...")
                new_url = upload_to_cloudinary(r.content, url.split('/')[-1])
                return new_url
            else:
                print("    [!] Could not download file from Cloudinary.")
                return None
        except Exception as e:
            print(f"    [!] Error downloading: {e}")
            return None

    # Condition 3: Local file (from media_file)
    if local_file_path and os.path.exists(local_file_path):
        print(f"    [*] Found local PDF: {local_file_path}")
        try:
            with open(local_file_path, 'rb') as f:
                content = f.read()
            print("    [*] Migrating local file to Cloudinary raw/upload...")
            filename = os.path.basename(local_file_path)
            new_url = upload_to_cloudinary(content, filename)
            return new_url
        except Exception as e:
            print(f"    [!] Error reading local file: {e}")
            return None
            
    # Condition 4: It's a local URL but file doesn't exist on disk
    if url and '/media/' in url and not url.startswith('http'):
        print(f"    [!] Local file URL found but no physical file exists for migration: {url}")
        return None

    return None

print("Starting PDF Migration...")

# 1. Migrate Knowledge Hub Resources
resources = Resource.objects.filter(resource_type='pdf')
print(f"Scanning {resources.count()} PDF Resources...")
for res in resources:
    local_path = None
    try:
        local_path = res.media_file.path if res.media_file else None
    except Exception:
        pass
        
    # If media_url is empty but media_file exists, it's local
    url_to_check = res.media_url if res.media_url else (res.media_file.url if res.media_file else None)
    
    new_url = process_url(url_to_check, local_path)
    if new_url:
        res.media_url = new_url
        res.media_file = None
        res.save()
        print(f"    [SUCCESS] Resource '{res.title_en}' updated to: {new_url}")

# 2. Migrate Courses
courses = Course.objects.all()
print(f"Scanning {courses.count()} Courses...")
for course in courses:
    local_path = None
    try:
        local_path = course.media_file.path if course.media_file else None
    except Exception:
        pass
        
    url_to_check = course.media_url if course.media_url else (course.media_file.url if course.media_file else None)
    
    new_url = process_url(url_to_check, local_path)
    if new_url:
        course.media_url = new_url
        course.media_file = None
        course.save()
        print(f"    [SUCCESS] Course '{course.title_en}' updated to: {new_url}")

# 3. Migrate Lessons
lessons = Lesson.objects.all()
print(f"Scanning {lessons.count()} Lessons...")
for lesson in lessons:
    # Lessons only have video_url, no local file field
    if lesson.content_en == 'pdf' or (lesson.video_url and lesson.video_url.lower().endswith('.pdf')):
        new_url = process_url(lesson.video_url, None)
        if new_url:
            lesson.video_url = new_url
            lesson.save()
            print(f"    [SUCCESS] Lesson '{lesson.title_en}' updated to: {new_url}")

print("Migration Complete!")
