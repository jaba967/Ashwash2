import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ashwash_backend.settings')
django.setup()

from apps.authentication.models import Category, User, SpecialistProfile
from apps.courses.models import Course, Module, Lesson, Assignment, UserCourseProgress
from apps.appointments.models import Specialist, Appointment
from apps.knowledge_hub.models import Resource
from apps.community.models import Post, Comment

def seed():
    print("==================================================")
    print("Seeding Complete Data into MySQL ashwash_db...")
    print("==================================================")

    # 1. Categories
    categories_data = [
        ("First Time Mother", "Support for new mothers navigating early motherhood"),
        ("Postpartum Depression", "Support and management for postpartum depression and anxiety"),
        ("Single Parent", "Resources and guidance for single parents"),
        ("Parent of Special Child", "Specialized support for parents of children with special needs"),
        ("Corporate Professional", "Mental wellness support for working professionals"),
        ("University Student", "Stress, anxiety & academic pressure support for students"),
    ]
    
    cats = {}
    for name, desc in categories_data:
        cat, created = Category.objects.get_or_create(name=name, defaults={"description": desc})
        cats[name] = cat
        print(f"Category '{name}': {'Created' if created else 'Already exists'}")

    # 2. Superuser & Standard Users
    admin_user, _ = User.objects.get_or_create(
        username="admin",
        defaults={
            "email": "admin@ashwash.com",
            "role": User.Role.ADMIN,
            "is_staff": True,
            "is_superuser": True,
        }
    )
    admin_user.is_active = True
    admin_user.is_staff = True
    admin_user.is_superuser = True
    admin_user.set_password("adminpassword123")
    admin_user.save()
    print("Admin User activated and ready: admin / adminpassword123")

    spec_user, spec_u_created = User.objects.get_or_create(
        username="dr.mekhala",
        defaults={
            "email": "dr.mekhala@ashwash.com",
            "first_name": "Dr. Mekhala",
            "last_name": "Sarkar",
            "role": User.Role.SPECIALIST,
        }
    )
    if spec_u_created:
        spec_user.set_password("doctor123")
        spec_user.save()

    SpecialistProfile.objects.get_or_create(
        user=spec_user,
        defaults={
            "full_name": "Dr. Mekhala Sarkar",
            "gender": "female",
            "phone_number": "+880 1711-982341",
            "email": "dr.mekhala@ashwash.com",
            "specialization": "Clinical Psychologist & Senior Consultant",
            "hospital_clinic": "Ashwash Mental Wellness Center, Dhaka",
            "experience_years": 12,
            "qualification": "FCPS (Psychiatry), M.Phil in Clinical Psychology (BSMMU)",
            "medical_license_number": "BMDC-REG-98234",
            "languages": "Bengali, English",
            "consultation_fee_bdt": 1500,
            "available_days": ["Sunday", "Monday", "Wednesday", "Thursday"],
            "available_time_slots": ["10:00 AM - 11:00 AM", "03:00 PM - 04:00 PM", "07:00 PM - 08:00 PM"],
            "is_profile_complete": True,
            "rating": 4.9,
            "total_reviews": 48,
            "bio": "Dedicated senior consultant psychiatrist specializing in maternal mental health, postpartum depression, and emotional resilience.",
        }
    )

    # 3. Category-wise Courses
    courses_info = [
        {
            "cat": "Postpartum Depression",
            "title_en": "Postpartum Depression Recovery Program",
            "title_bn": "পোস্টপার্টাম ডিপ্রেশন রিকভারি প্রোগ্রাম",
            "desc_en": "Comprehensive 6-week guided recovery for new mothers covering symptoms, bonding, and coping.",
            "desc_bn": "নতুন মায়েদের প্রসূতি পরবর্তী বিষণ্নতা দূরীকরণে ৬ সপ্তাহের পূর্ণাঙ্গ সহায়িকা",
            "duration": 6,
            "tasks": 17,
            "lessons": [
                ("Understanding Postpartum Mood Shifts", "প্রসূতি পরবর্তী আবেগীয় পরিবর্তন বুঝুন", "https://res.cloudinary.com/a6cztdgv/video/upload/v1785525213/Postpartum_Depression_mood_disorder_after_child_birth_in_Bangla_Dr_Mekhala_Sarkar_-_Dr._Mekhala_Sarkar_720p_h264_twt9ei.mp4"),
                ("Baby Blues vs Postpartum Depression", "বেবি ব্লুজ বনাম পোস্টপার্টাম ডিপ্রেশন", "https://res.cloudinary.com/a6cztdgv/video/upload/v1785525764/Baby_Blues_vs_Postpartum_Depression_Which_is_it_-_The_Maternity_Mentor_360p_h264_pmxptj.mp4"),
                ("Managing Anxiety & Guilt", "উদ্বেগ ও অপরাধবোধ কমানোর উপায়", "https://res.cloudinary.com/a6cztdgv/video/upload/v1785525679/Anxiety_Disorder_what_s_an_anxiety_disorder_anxiety_symptoms_treatment_in_bangla_-_Health_Inside_%E0%A6%AC%E0%A6%BE%E0%A6%82%E0%A6%B2%E0%A6%BE_720p_h264_kkvvdp.mp4"),
            ]
        },
        {
            "cat": "Single Parent",
            "title_en": "Single Parent Resilience & Child Care",
            "title_bn": "একক অভিভাবকের মানসিক শক্তি ও সন্তান লালন-পালন",
            "desc_en": "Balancing parental responsibilities, work, and personal emotional strength.",
            "desc_bn": "একক অভিভাবকত্বের চ্যালেঞ্জ ও মানসিক প্রশান্তি বজায় রাখার কৌশল।",
            "duration": 4,
            "tasks": 8,
            "lessons": [
                ("Overcoming Parental Burnout", "অভিভাবকত্বের ক্লান্তি দূরীকরণ", "https://res.cloudinary.com/a6cztdgv/video/upload/v1785526641/7_Secrets_To_Becoming_Mentally_Tougher_-_Psych2Go_720p_h264_tftysh.mp4"),
                ("Setting Healthy Work-Life Boundaries", "কাজ ও পরিবারের ভারসাম্য গঠন", ""),
            ]
        },
        {
            "cat": "Parent of Special Child",
            "title_en": "Special Child Parenting & Mindfulness",
            "title_bn": "বিশেষ চাহিদা সম্পন্ন শিশুর অভিভাবকত্ব কোর্স",
            "desc_en": "Empathy, patience, and specialized care strategies for neurodivergent children.",
            "desc_bn": "বিশেষ চাহিদাসম্পন্ন শিশুদের মমতায় লালন-পালন ও মানসিক প্রশান্তি।",
            "duration": 5,
            "tasks": 10,
            "lessons": [
                ("Sensory Integration & Patience", "শিশুর সংবেদনশীলতার বিকাশ ও ধৈর্য অর্জন", "https://res.cloudinary.com/a6cztdgv/video/upload/v1785525679/Anxiety_Disorder_what_s_an_anxiety_disorder_anxiety_symptoms_treatment_in_bangla_-_Health_Inside_%E0%A6%AC%E0%A6%BE%E0%A6%82%E0%A6%B2%E0%A6%BE_720p_h264_kkvvdp.mp4"),
            ]
        },
        {
            "cat": "Corporate Professional",
            "title_en": "Corporate Burnout & Stress Mastery",
            "title_bn": "কর্পোরেট বার্নআউট ও স্ট্রেস সামলানোর গাইড",
            "desc_en": "Work-life balance, anxiety relief, and preventing workplace exhaustion.",
            "desc_bn": "কাজের মানসিক চাপ ও কর্মক্ষেত্রের ভারসাম্যের জন্য বিজ্ঞানসম্মত গাইড।",
            "duration": 3,
            "tasks": 6,
            "lessons": [
                ("Defeating Workplace Burnout", "কর্মক্ষেত্রের বার্নআউট জয় করার কৌশল", "https://res.cloudinary.com/a6cztdgv/video/upload/v1785526641/7_Secrets_To_Becoming_Mentally_Tougher_-_Psych2Go_720p_h264_tftysh.mp4"),
            ]
        },
        {
            "cat": "University Student",
            "title_en": "Student Exam Anxiety & Focus Boost",
            "title_bn": "পরীক্ষার ভয় ও পড়ার মনোযোগ বাড়ানোর উপায়",
            "desc_en": "Overcoming exam fear, study paralysis, and boosting concentration.",
            "desc_bn": "শিক্ষার্থীদের পড়ালেখার মানসিক চাপ ও পরীক্ষার ভীতি কাটানোর গাইড।",
            "duration": 3,
            "tasks": 6,
            "lessons": [
                ("Beating Study Procrastination & Focus", "পড়াশোনায় মনোযোগ বৃদ্ধি ও ভয় দূরীকরণ", "https://res.cloudinary.com/a6cztdgv/video/upload/v1785525679/Anxiety_Disorder_what_s_an_anxiety_disorder_anxiety_symptoms_treatment_in_bangla_-_Health_Inside_%E0%A6%AC%E0%A6%BE%E0%A6%82%E0%A6%B2%E0%A6%BE_720p_h264_kkvvdp.mp4"),
            ]
        },
    ]

    for cdata in courses_info:
        cat_obj = cats.get(cdata["cat"]) or cats.get("Postpartum Depression")
        course, c_created = Course.objects.get_or_create(
            title_en=cdata["title_en"],
            defaults={
                "category": cat_obj,
                "title_bn": cdata["title_bn"],
                "description_en": cdata["desc_en"],
                "description_bn": cdata["desc_bn"],
                "duration_weeks": cdata["duration"],
                "total_tasks": cdata["tasks"],
                "type_label": "Both",
                "price": 0.00,
                "is_free": True,
                "rating": 4.9,
            }
        )
        if c_created:
            module = Module.objects.create(
                course=course,
                title_en="Module 1: Core Fundamentals",
                title_bn="মডিউল ১: মৌলিক জ্ঞান ও কৌশল",
                order=1
            )
            for l_idx, l_info in enumerate(cdata["lessons"], 1):
                lesson = Lesson.objects.create(
                    module=module,
                    title_en=l_info[0],
                    title_bn=l_info[1],
                    video_url=l_info[2],
                    duration_minutes=15,
                    order=l_idx
                )
                Assignment.objects.create(
                    lesson=lesson,
                    instruction_en=f"Complete daily reflection for {l_info[0]}.",
                    instruction_bn=f"{l_info[1]} এর ওপর দৈনন্দিন প্রতিফলন সম্পন্ন করুন।"
                )
            print(f"Created Course: {course.title_en} with {len(cdata['lessons'])} lessons.")

    # 4. Psychologists / Specialists Table
    specialists_list = [
        ("Jaba Acharjee", "MSc in Clinical Psychology (BSMMU)", "Postpartum & Maternal Mental Health Specialist", "Ashwash Mental Wellness & BSMMU", 8, 5.0, 1200),
        ("Dr. Mekhala Sarkar", "FCPS (Psychiatry), M.Phil", "Clinical Psychologist & Senior Consultant", "Ashwash Mental Wellness Center", 12, 4.9, 1500),
        ("Jahanur Akter", "BSc (Psychology), MSc (Psychology)", "Psychology & Mental Health Counseling", "Healthx", 5, 4.9, 500),
        ("Nazmun Nahar Munmun", "BSc (Psychology), MS (Clinical Psychology)", "Clinical Psychology & CBT Therapy", "Dhaka College", 9, 5.0, 600),
        ("Ashraful Alam Khan", "BSc (Psychology), MS (Psychology)", "Psychology & Audiology Therapy", "Moner Shusthota, Audiology Bangladesh", 17, 4.9, 800),
        ("Md. Wahid Anowar", "BSc (Psychology), MS (Psychology)", "Psychological Consultancy & Youth Therapy", "Restart- Psychological Consultancy", 3, 4.8, 500),
        ("Ambia Khatun", "MPhil (Psychology), MSc (Psychology)", "Psychology & Educational Counseling", "Bangladesh Open University", 4, 5.0, 500),
        ("Dr. Sharmin Akter", "FCPS (Psychiatry), MSc", "Postpartum & Maternal Mental Health Specialist", "Ashwash Wellness & BSMMU", 8, 4.9, 1200),
        ("Dr. Anisur Rahman", "MD (Psychiatry), MBBS (DMC)", "Consultant Psychiatrist & Sleep Specialist", "Dhaka Medical College & Hospital", 11, 4.8, 1500),
        ("Dr. Farhana Islam", "M.Phil (Clinical Psychology)", "Child & Adolescent Psychologist", "National Institute of Mental Health (NIMH)", 7, 5.0, 1000),
    ]

    for s_name, s_deg, s_spec, s_work, s_exp, s_rat, s_fee in specialists_list:
        Specialist.objects.get_or_create(
            name=s_name,
            defaults={
                "title_en": s_deg,
                "title_bn": s_spec,
                "bio_en": f"{s_name} is a highly experienced {s_spec} with {s_exp}+ years of clinical counseling experience at {s_work}.",
                "bio_bn": f"{s_name} একজন অভিজ্ঞ {s_spec} ({s_exp}+ বছরের অভিজ্ঞতা)।",
                "experience_years": s_exp,
                "rating": s_rat,
                "fee_bdt": s_fee,
                "location_type": "local",
                "is_available": True,
                "is_online": True,
            }
        )
    print(f"Specialists table seeded: {Specialist.objects.count()} entries.")

    # 5. Knowledge Hub Resources
    resources_list = [
        ("5 Daily Mindfulness Habits for New Mothers", "প্রসূতি মায়েদের জন্য প্রতিদিনের ৫টি মাইন্ডফুলনেস অভ্যাস", "article", 5, "https://www.globalfamilydoctor.com/site/DefaultSite/filesystem/documents/resources/MHGuidebook-EBookDownload.pdf"),
        ("4-7-8 Breathing Relaxation Audio for Sleep", "৪-৭-৮ শ্বাস-প্রশ্বাসের মাধ্যমে গভীর ঘুমের অডিও", "audio", 10, "https://res.cloudinary.com/a6cztdgv/video/upload/v1785524287/A_Guided_Meditation_for_Releasing_Guilt_-_Great_Meditation_hku8ku.mp3"),
        ("Understanding Postpartum Mood Shifts", "পোস্টপার্টাম মুড চেঞ্জ ও মানসিক প্রস্তুতি ভিডিও", "video", 18, "https://res.cloudinary.com/a6cztdgv/video/upload/v1785525213/Postpartum_Depression_mood_disorder_after_child_birth_in_Bangla_Dr_Mekhala_Sarkar_-_Dr._Mekhala_Sarkar_720p_h264_twt9ei.mp4"),
        ("Mental Health Guidebook PDF", "মানসিক সুস্থতার পূর্ণাঙ্গ পিডিএফ নির্দেশিকা", "pdf", 15, "https://www.docs.sasg.ed.ac.uk/StudentCounselling/SCSbooklets/SCSstressbooklet.pdf"),
    ]

    for r_title_en, r_title_bn, r_type, r_dur, r_url in resources_list:
        Resource.objects.get_or_create(
            title_en=r_title_en,
            defaults={
                "title_bn": r_title_bn,
                "summary_en": f"Comprehensive {r_type} resource on mental health and emotional well-being.",
                "summary_bn": "মানসিক সুস্থতা ও আবেগের ভারসাম্যের পূর্ণাঙ্গ নির্দেশিকা।",
                "content_en": f"Detailed information regarding {r_title_en} for daily resilience.",
                "content_bn": f"{r_title_bn} বিষয়ক বৈজ্ঞানিক টিপস ও নির্দেশনা।",
                "resource_type": r_type,
                "duration_minutes": r_dur,
                "is_premium": False,
            }
        )
    print(f"Knowledge Hub Resources seeded: {Resource.objects.count()} entries.")

    # 6. Sample Community Posts
    post1, p1_created = Post.objects.get_or_create(
        id=1,
        defaults={
            "author": admin_user,
            "author_alias": "Anonymous Member",
            "is_anonymous": True,
            "tag": "Support",
            "content": "গত কয়েকদিন ধরে খুব মানসিক চাপে ভুগছি। রাতে ঠিকমত ঘুম হচ্ছে না। কেউ কি সাহায্য বা শ্বাস-প্রশ্বাসের ভালো টিপস দিতে পারেন?",
            "likes_count": 14,
            "comments_count": 2,
        }
    )
    if p1_created:
        Comment.objects.create(
            post=post1,
            author=spec_user,
            author_alias="Dr. Sharmin Akter (Specialist)",
            content="ধন্যবাদ শেয়ার করার জন্য। ৪-৭-৮ শ্বাস-প্রশ্বাসের ব্যায়ামটি ঘুমানোর আগে ৩ মিনিট করুন। মানসিক চাপ কমাতে সাহায্য করবে।"
        )
        Comment.objects.create(
            post=post1,
            author=spec_user,
            author_alias="Dr. Anisur Rahman (Psychiatrist)",
            content="প্রতিদিন রাতে ঘুমানোর ৩০ মিনিট আগে স্ক্রিন টাইম বন্ধ রাখুন এবং হালকা গরম পানি বা ক্যাফেইন-মুক্ত টি খেতে পারেন।"
        )

    print("==================================================")
    print("Database seeding completed successfully!")
    print("==================================================")

if __name__ == "__main__":
    seed()
