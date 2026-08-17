import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ashwash_backend.settings')
django.setup()

from apps.knowledge_hub.models import Resource

def seed_resources():
    Resource.objects.all().delete()

    resources = [
        # Audio - Free
        {
            'title_en': 'Mixkit Time Out Relaxation & Breathing Track',
            'title_bn': 'টাইম-আউট রিলেক্সেশন ও শ্বাসের অডিও',
            'summary_en': 'Calming acoustic audio designed for 10-minute stress relief and deep breathing practice.',
            'summary_bn': '১০ মিনিটের মানসিক চাপ কমানো ও গভীর শ্বাসের অডিও ট্র্যাক।',
            'resource_type': 'audio',
            'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493228/mixkit-time-out-92_cxu9hq.mp3',
            'duration_minutes': 4,
            'is_premium': False,
        },
        {
            'title_en': 'Leberch Deep Meditation & Calm Music',
            'title_bn': 'গভীর মেডিটেশন ও প্রশান্তিদায়ক অডিও ট্র্যাক',
            'summary_en': 'Deep meditative waves helping lower heart rate, ease anxiety, and promote restful sleep.',
            'summary_bn': 'মানসিক এনজাইটি ও দুশ্চিন্তা কমানোর প্রশান্তিদায়ক সুর।',
            'resource_type': 'audio',
            'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493206/leberch-meditation-509071_vjnfiw.mp3',
            'duration_minutes': 5,
            'is_premium': False,
        },
        {
            'title_en': 'Monume Ambient Wellness Meditation Track',
            'title_bn': 'মাইন্ডফুলনেস ও মানসিক স্থৈর্যবর্ধক অডিও',
            'summary_en': 'Soothing background meditation track for daily focus, work breaks, and emotional grounding.',
            'summary_bn': 'কাজের ফাঁকে মানসিক স্থৈর্য ও মনোযোগ বৃদ্ধিতে সহায়ক মেডিটেশন।',
            'resource_type': 'audio',
            'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493145/monume-meditation-meditation-music-570695_nxg03k.mp3',
            'duration_minutes': 4,
            'is_premium': False,
        },
        # Audio - Paid
        {
            'title_en': 'Verclub Masterclass Guided Meditation (Paid)',
            'title_bn': 'ভারক্লাব প্রিমিয়াম গাইডেড মেডিটেশন (পেইড)',
            'summary_en': 'Exclusive clinical-grade guided audio session for anxiety disorder relief and deep mental rejuvenation.',
            'summary_bn': 'বিশেষজ্ঞ মানসিক চিকিৎসকের নির্দেশিত প্রিমিয়াম অডিও মেডিটেশন (৳৫০০/-$৫)।',
            'resource_type': 'audio',
            'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493086/verclub_music-meditation-music-550885_vcek1p.mp3',
            'duration_minutes': 15,
            'is_premium': True,
        },

        # Video - Free
        {
            'title_en': 'Mindful Nature Meditation & Breathing Visualizer',
            'title_bn': 'প্রকৃতির সান্নিধ্যে ভিজ্যুয়াল মেডিটেশন',
            'summary_en': 'HD relaxing visual video with natural landscapes for visual mindfulness and anxiety reduction.',
            'summary_bn': 'প্রাকৃতিক দৃশ্যের সাথে ভিজ্যুয়াল মেডিটেশন ভিডিও।',
            'resource_type': 'video',
            'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493355/istockphoto-1253263447-640_adpp_is_n8i3m0.mp4',
            'duration_minutes': 2,
            'is_premium': False,
        },
        {
            'title_en': 'Tranquil Forest & Water Stream Relaxation Video',
            'title_bn': 'শান্ত বনভূমি ও জলপ্রপাতের মানসিক রিলেক্সেশন ভিজ্যুয়াল',
            'summary_en': 'UHD 4K nature video stream to de-stress eyes and mind during long working hours.',
            'summary_bn': 'চোখ ও মনের ক্লান্তি দূর করতে 4K প্রকৃতির স্ট্রিম।',
            'resource_type': 'video',
            'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493620/6941384-uhd_4096_2160_25fps_asotry.mp4',
            'duration_minutes': 7,
            'is_premium': False,
        },
        # Video - Paid
        {
            'title_en': 'Specialist Therapy Session Video Class (Paid)',
            'title_bn': 'বিশেষজ্ঞ চিকিৎসকের সাইকোথেরাপি সেশন (পেইড)',
            'summary_en': 'Exclusive 4K video masterclass by licensed clinical psychologists on managing severe panic & stress.',
            'summary_bn': 'লাইসেন্সপ্রাপ্ত সাইকোলজিস্টের মাস্টারক্লাস থেরাপি সেশন (৳১০০০/-$১০)।',
            'resource_type': 'video',
            'media_url': 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785494530/244839_medium_oib2g0.mp4',
            'duration_minutes': 25,
            'is_premium': True,
        },

        # Article - Free
        {
            'title_en': 'WHO Guide: Mental Health & Stress Management e-Book',
            'title_bn': 'বিশ্ব স্বাস্থ্য সংস্থা (WHO) মানসিক স্বাস্থ্য সহায়িকা',
            'summary_en': 'Official World Health Organization illustrated e-Book on stress management and practical coping strategies.',
            'summary_bn': 'ডাব্লিউএইচও (WHO) প্রকাশিত মানসিক স্বাস্থ্য নির্দেশিকা ই-বুক।',
            'resource_type': 'article',
            'media_url': 'https://res.cloudinary.com/a6cztdgv/raw/upload/v1785509977/pg31382-images-3_wvszvx.epub',
            'content_en': 'Official WHO Mental Health e-Book guide on stress resilience and emotional well-being.',
            'content_bn': 'বিশ্ব স্বাস্থ্য সংস্থার মনস্তাত্ত্বিক সহায়িকা।',
            'duration_minutes': 12,
            'is_premium': False,
        },
        # Article - Paid (WHO Text Resource)
        {
            'title_en': 'WHO Psychology-Based Clinical Stress Manual (Paid)',
            'title_bn': 'WHO ক্লিনিক্যাল সাইকোলজি ও মানসিক স্বাস্থ্যের পূর্ণাঙ্গ গাইড (পেইড)',
            'summary_en': 'Comprehensive WHO evidence-based manual covering cognitive reframing, emotional regulation, and stress intervention protocols.',
            'summary_bn': 'WHO ক্লিনিক্যাল সাইকোলজিকাল থেরাপি ম্যানুয়াল ও মানসিক নিয়ন্ত্রণের গাইড (৳৩০০/-$৩)।',
            'resource_type': 'article',
            'media_url': 'https://www.who.int/publications/i/item/9789240003926',
            'content_en': 'World Health Organization (WHO) Psychology-Based Guide:\n1. Stress grounding techniques.\n2. Cognitive reframing practices.\n3. Daily emotional regulation steps.',
            'content_bn': 'ডাব্লিউএইচও মনস্তাত্ত্বিক সহায়তা ম্যানুয়াল।',
            'duration_minutes': 20,
            'is_premium': True,
        },
    ]

    for item in resources:
        Resource.objects.create(**item)

    print(f"Successfully seeded {len(resources)} resources into Django database!")

if __name__ == '__main__':
    seed_resources()
