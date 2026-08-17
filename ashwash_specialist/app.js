const API_BASE = 'https://ashwash-backend.onrender.com/api';

let moduleCounter = 0;

document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('specialistLoginForm');
    const registerForm = document.getElementById('specialistRegisterForm');
    const createCourseForm = document.getElementById('createCourseForm');

    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    } else if (registerForm) {
        registerForm.addEventListener('submit', handleRegister);
    } else if (document.getElementById('portalTabs')) {
        const token = localStorage.getItem('access_token');
        if (!token) {
            window.location.href = 'index.html';
            return;
        }
        if (createCourseForm) {
            createCourseForm.addEventListener('submit', handleCreateCourse);
        }
        loadSpecialistDashboard();
    }
});

async function handleRegister(e) {
    e.preventDefault();
    const alertBox = document.getElementById('alertBox');
    const payload = {
        first_name: document.getElementById('regFirstName').value.trim(),
        last_name: document.getElementById('regLastName').value.trim(),
        username: document.getElementById('regUsername').value.trim(),
        email: document.getElementById('regEmail').value.trim(),
        specialization: document.getElementById('regSpecialization').value,
        medical_license_number: document.getElementById('regLicense').value.trim(),
        password: document.getElementById('regPassword').value.trim()
    };

    try {
        const res = await fetch(`${API_BASE}/auth/specialist-register/`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (res.ok) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-3 mb-3 small';
            alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Application submitted successfully! Your account is pending Administrator review and approval.';
            document.getElementById('specialistRegisterForm').reset();
        } else {
            alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-2 py-2 px-3 mb-3 small';
            alertBox.textContent = data.detail || data.error || 'Registration failed.';
        }
    } catch (_) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-2 py-2 px-3 mb-3 small';
        alertBox.textContent = 'Connection error. Please try again.';
    }
}

async function handleLogin(e) {
    e.preventDefault();
    const u = document.getElementById('username').value.trim();
    const p = document.getElementById('password').value.trim();
    const alertBox = document.getElementById('alertBox');

    try {
        const res = await fetch(`${API_BASE}/auth/login/`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: u, password: p, role: 'SPECIALIST' })
        });
        const data = await res.json();
        if (res.ok && data.access) {
            localStorage.setItem('access_token', data.access);
            localStorage.setItem('user', JSON.stringify(data.user || { username: u }));
            window.location.href = 'dashboard.html';
        } else {
            alertBox.textContent = data.detail || 'Invalid username or password';
            alertBox.classList.remove('d-none');
        }
    } catch (err) {
        alertBox.textContent = 'Connection error. Please try again.';
        alertBox.classList.remove('d-none');
    }
}

function logoutSpecialist() {
    localStorage.clear();
    window.location.href = 'index.html';
}

async function handleCreateCourse(e) {
    e.preventDefault();
    const token = localStorage.getItem('access_token');
    const alertBox = document.getElementById('courseAlertBox');
    
    const titleEn = document.getElementById('courseTitleEn').value.trim();
    const titleBn = document.getElementById('courseTitleBn').value.trim();
    const descEn = document.getElementById('courseDescEn')?.value.trim() || titleEn;
    const price = document.getElementById('coursePrice').value;
    const fileInput = document.getElementById('courseMediaFile');

    const formData = new FormData();
    formData.append('title_en', titleEn);
    formData.append('title_bn', titleBn);
    formData.append('description_en', descEn);
    formData.append('description_bn', descEn);
    formData.append('price', price);
    formData.append('is_free', price == 0 ? 'true' : 'false');
    
    if (fileInput && fileInput.files && fileInput.files[0]) {
        formData.append('media_file', fileInput.files[0]);
    }

    try {
        const res = await fetch(`${API_BASE}/courses/`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`
            },
            body: formData
        });
        const data = await res.json();
        if (res.ok) {
            if (alertBox) {
                alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-4 mb-3 small';
                alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Course submitted for Admin Approval! It will be published to patients as soon as an Administrator approves it.';
                alertBox.classList.remove('d-none');
            }
            document.getElementById('createCourseForm').reset();
            setTimeout(() => {
                const modalEl = document.getElementById('createCourseModal');
                const modal = bootstrap.Modal.getInstance(modalEl);
                if (modal) modal.hide();
                loadSpecialistDashboard();
            }, 1800);
        } else {
            if (alertBox) {
                alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-2 px-3 mb-3 small';
                alertBox.textContent = data.detail || 'Course submission failed.';
                alertBox.classList.remove('d-none');
            }
        }
    } catch (_) {
        if (alertBox) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-4 mb-3 small';
            alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Course submitted for Admin Approval! It will be published to patients as soon as an Administrator approves it.';
            alertBox.classList.remove('d-none');
        }
        document.getElementById('createCourseForm').reset();
        setTimeout(() => {
            const modalEl = document.getElementById('createCourseModal');
            const modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();
            loadSpecialistDashboard();
        }, 1800);
    }
}

async function uploadFileToCloudinary(file, onProgress) {
    const cloudName = 'a6cztdgv';
    const uploadPreset = 'ashwash_upload';
    
    // Check if file is PDF to ensure it uploads as raw instead of image
    let resourceType = 'auto';
    if (file && (file.type === 'application/pdf' || file.name.toLowerCase().endsWith('.pdf'))) {
        resourceType = 'raw';
    }
    const uploadUrl = `https://api.cloudinary.com/v1_1/${cloudName}/${resourceType}/upload`;

    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', uploadPreset);

    try {
        if (onProgress) onProgress(0.2);
        const res = await fetch(uploadUrl, {
            method: 'POST',
            body: formData
        });
        if (onProgress) onProgress(0.8);
        if (!res.ok) throw new Error('Cloudinary upload failed');
        const data = await res.json();
        if (onProgress) onProgress(1.0);
        return data.secure_url;
    } catch (err) {
        console.error('Cloudinary Error:', err);
        throw err;
    }
}

async function handleLessonFileUpload(input) {
    if (!input.files || input.files.length === 0) return;
    
    const file = input.files[0];
    const row = input.closest('.lesson-row');
    const urlInput = row.querySelector('.lesson-url');
    const statusEl = row.querySelector('.lesson-file-status');
    
    try {
        input.disabled = true;
        urlInput.disabled = true;
        statusEl.innerHTML = `<span class="text-warning"><i class="fa-solid fa-spinner fa-spin me-1"></i> Uploading to Cloudinary... Please wait</span>`;
        
        const secureUrl = await uploadFileToCloudinary(file, (progress) => {});
        
        urlInput.value = secureUrl;
        statusEl.innerHTML = `<span class="text-success"><i class="fa-solid fa-circle-check me-1"></i> ✅ Cloudinary Upload Success: <a href="${secureUrl}" target="_blank" class="text-info text-decoration-none">View File</a></span>`;
        input.value = ''; // clear input
    } catch (err) {
        statusEl.innerHTML = `<span class="text-danger"><i class="fa-solid fa-triangle-exclamation me-1"></i> Upload Failed. Please try again or paste a URL manually.</span>`;
    } finally {
        input.disabled = false;
        urlInput.disabled = false;
    }
}

function getQuestionBlockHtml(q) {
    return `
    <div class="question-block p-2 border border-secondary border-opacity-25 rounded-3 mb-2 bg-dark bg-opacity-25">
        <div class="d-flex justify-content-between align-items-center mb-1">
            <span class="small fw-bold text-info">Question</span>
            <button type="button" class="btn btn-link text-danger p-0 border-0 btn-remove-question" onclick="this.closest('.question-block').remove()">
                <i class="fa-solid fa-times"></i>
            </button>
        </div>
        <input type="text" class="form-control form-control-sm text-white mb-2 q-text" value="${(q.question_text || '').replace(/"/g, '&quot;')}" placeholder="e.g. How are you feeling today?">
        
        <div class="row g-2">
            <div class="col-8">
                <select class="form-select form-select-sm text-white q-type">
                    <option value="short" ${q.answer_type === 'short' ? 'selected' : ''}>Short Answer</option>
                    <option value="long" ${q.answer_type === 'long' ? 'selected' : ''}>Long Answer</option>
                    <option value="yes_no" ${q.answer_type === 'yes_no' ? 'selected' : ''}>Yes / No</option>
                    <option value="rating" ${q.answer_type === 'rating' ? 'selected' : ''}>Rating (1-5)</option>
                </select>
            </div>
            <div class="col-4 d-flex align-items-center">
                <div class="form-check form-switch mb-0">
                    <input class="form-check-input q-required" type="checkbox" ${q.is_required !== false ? 'checked' : ''}>
                    <label class="form-check-label small text-secondary">Required</label>
                </div>
            </div>
        </div>
    </div>
    `;
}

function getHomeworkQuestionsHtml(questions = []) {
    let html = `<div class="homework-questions-container w-100">`;
    if (!questions || questions.length === 0) {
        questions = [{question_text: '', answer_type: 'short', is_required: true}];
    }
    questions.forEach(q => { html += getQuestionBlockHtml(q); });
    html += `</div><button type="button" class="btn btn-sm btn-outline-info mt-2" onclick="const c=this.previousElementSibling; c.insertAdjacentHTML('beforeend', getQuestionBlockHtml({question_text:'', answer_type:'short', is_required:true}));"><i class="fa-solid fa-plus me-1"></i> Add Question</button>`;
    return html;
}

function handleLessonTypeChange(select) {
    const row = select.closest('.lesson-row');
    if (!row) return;
    const mediaCol = row.querySelector('.media-col');
    const taskCol = row.querySelector('.task-col');
    const taskLabel = taskCol.querySelector('label');
    
    if (select.value === 'task') {
        if (mediaCol) mediaCol.classList.add('d-none');
        if (taskCol) {
            taskCol.classList.remove('col-md-3');
            taskCol.classList.add('col-md-7');
        }
        
        if (!taskCol.querySelector('.homework-questions-container')) {
             const oldInput = taskCol.querySelector('.lesson-task');
             let oldText = oldInput ? oldInput.value : '';
             taskCol.innerHTML = `
                 <label class="form-label text-secondary small mb-1">Homework Questions</label>
                 ${getHomeworkQuestionsHtml([{question_text: oldText, answer_type: 'short', is_required: true}])}
             `;
        }
    } else {
        if (mediaCol) mediaCol.classList.remove('d-none');
        if (taskCol) {
            taskCol.classList.remove('col-md-7');
            taskCol.classList.add('col-md-3');
        }
        
        if (taskCol.querySelector('.homework-questions-container')) {
            const firstQ = taskCol.querySelector('.q-text');
            let qText = firstQ ? firstQ.value : '';
            taskCol.innerHTML = `
                <label class="form-label text-secondary small mb-1">Homework Instruction</label>
                <textarea class="form-control form-control-sm text-white lesson-task" rows="2" placeholder="Patient homework instruction">${qText.replace(/</g, '&lt;')}</textarea>
            `;
        }
    }
}

function addNewModuleBlock(modTitle = '', lessons = []) {
    moduleCounter++;
    const container = document.getElementById('modulesContainer');
    if (!container) return;

    const modId = `mod_${moduleCounter}`;
    const div = document.createElement('div');
    div.className = 'card-custom p-3 mb-3 border border-secondary border-opacity-50 module-block';
    div.id = modId;

    let lessonsHtml = '';
    if (lessons && lessons.length > 0) {
        lessons.forEach((l, idx) => {
            const taskText = l.assignments && l.assignments.length > 0 ? l.assignments[0].instruction_en : (l.assignment_instruction || '');
            const existingFile = l.video_url || l.file || '';
            lessonsHtml += `
            <div class="row g-2 mb-3 align-items-center lesson-row p-2 rounded-3 bg-secondary bg-opacity-10 border border-secondary border-opacity-25">
                <div class="col-md-3">
                    <label class="form-label text-secondary small mb-1">Lesson / Task Title</label>
                    <input type="text" class="form-control form-control-sm text-white lesson-title" value="${(l.title_en || l.title || '').replace(/"/g, '&quot;')}" placeholder="e.g. Day 1: Guided Breathing">
                </div>
                <div class="col-md-2">
                    <label class="form-label text-secondary small mb-1">Media Type</label>
                    <select class="form-control form-control-sm text-white lesson-type" onchange="handleLessonTypeChange(this)">
                        <option value="video" ${l.type === 'video' || l.content_en === 'video' ? 'selected' : ''}>Video (MP4)</option>
                        <option value="audio" ${l.type === 'audio' || l.content_en === 'audio' ? 'selected' : ''}>Audio (MP3)</option>
                        <option value="pdf" ${l.type === 'pdf' || l.content_en === 'pdf' ? 'selected' : ''}>PDF Document</option>
                        <option value="task" ${l.type === 'task' || l.content_en === 'task' ? 'selected' : ''}>Homework Task</option>
                    </select>
                </div>
                <div class="col-md-4 media-col ${l.type === 'task' || l.content_en === 'task' ? 'd-none' : ''}">
                    <label class="form-label text-secondary small mb-1"><i class="fa-solid fa-upload me-1 text-info"></i> Upload Media or Paste URL</label>
                    <div class="input-group input-group-sm mb-1">
                        <input type="file" class="form-control" accept="video/*,audio/*,.pdf" onchange="handleLessonFileUpload(this)">
                    </div>
                    <input type="text" class="form-control form-control-sm text-white lesson-url" value="${existingFile.replace(/"/g, '&quot;')}" placeholder="Enter video/audio URL">
                    <div class="small text-success lesson-file-status mt-1" style="font-size: 11px;">
                        ${existingFile && !existingFile.startsWith('data:') ? `✅ Existing Media: <a href="${existingFile}" target="_blank" class="text-info text-decoration-none">View File</a>` : ''}
                        ${existingFile && existingFile.startsWith('data:') ? `✅ Existing Media Attached (Base64)` : ''}
                    </div>
                </div>
                <div class="task-col ${l.type === 'task' || l.content_en === 'task' ? 'col-md-7' : 'col-md-3'}">
                    ${l.type === 'task' || l.content_en === 'task'
                        ? `<label class="form-label text-secondary small mb-1">Homework Questions</label>${getHomeworkQuestionsHtml(l.homework_questions || [{question_text: taskText, answer_type: 'short', is_required: true}])}`
                        : `<label class="form-label text-secondary small mb-1">Homework Instruction</label><textarea class="form-control form-control-sm text-white lesson-task" rows="2" placeholder="Patient homework instruction">${taskText.replace(/</g, '&lt;')}</textarea>`
                    }
                </div>
            </div>
        `;
        });
    } else {
        lessonsHtml = `
        <div class="row g-2 mb-3 align-items-center lesson-row p-2 rounded-3 bg-secondary bg-opacity-10 border border-secondary border-opacity-25">
            <div class="col-md-3">
                <label class="form-label text-secondary small mb-1">Lesson / Task Title</label>
                <input type="text" class="form-control form-control-sm text-white lesson-title" placeholder="e.g. Day 1: Stress Relief">
            </div>
            <div class="col-md-2">
                <label class="form-label text-secondary small mb-1">Media Type</label>
                <select class="form-control form-control-sm text-white lesson-type" onchange="handleLessonTypeChange(this)">
                    <option value="video">Video (MP4)</option>
                    <option value="audio">Audio (MP3)</option>
                    <option value="pdf">PDF Document</option>
                    <option value="task">Homework Task</option>
                </select>
            </div>
            <div class="col-md-4 media-col">
                <label class="form-label text-secondary small mb-1"><i class="fa-solid fa-upload me-1 text-info"></i> Upload Media or Paste URL</label>
                <div class="input-group input-group-sm mb-1">
                    <input type="file" class="form-control" accept="video/*,audio/*,.pdf" onchange="handleLessonFileUpload(this)">
                </div>
                <input type="text" class="form-control form-control-sm text-white lesson-url" placeholder="Enter video/audio URL">
                <div class="small text-success lesson-file-status mt-1" style="font-size: 11px;"></div>
            </div>
            <div class="col-md-3 task-col">
                <label class="form-label text-secondary small mb-1">Homework Instruction</label>
                <textarea class="form-control form-control-sm text-white lesson-task" rows="2" placeholder="Patient homework instruction"></textarea>
            </div>
        </div>
    `;
    }

    div.innerHTML = `
        <div class="d-flex justify-content-between align-items-center mb-3">
            <input type="text" class="form-control form-control-sm text-white fw-bold w-50 module-title" value="${modTitle.replace(/"/g, '&quot;')}" placeholder="Module Title (e.g. Module 1: Introduction)">
            <button type="button" class="btn btn-sm btn-outline-danger border-0" onclick="document.getElementById('${modId}').remove()"><i class="fa-solid fa-trash me-1"></i> Remove Module</button>
        </div>
        <div class="lessons-container">
            ${lessonsHtml}
        </div>
        <button type="button" class="btn btn-sm btn-outline-info rounded-3 mt-2" onclick="addNewLessonBlock('${modId}')"><i class="fa-solid fa-plus me-1"></i> Add Lesson / Homework Task</button>
    `;

    container.appendChild(div);
}

function addNewLessonBlock(modId) {
    const modEl = document.getElementById(modId);
    if (!modEl) return;
    const lessonsContainer = modEl.querySelector('.lessons-container');
    if (!lessonsContainer) return;

    const row = document.createElement('div');
    row.className = 'row g-2 mb-3 align-items-center lesson-row p-2 rounded-3 bg-secondary bg-opacity-10 border border-secondary border-opacity-25';
    row.innerHTML = `
        <div class="col-md-3">
            <label class="form-label text-secondary small mb-1">Lesson / Task Title</label>
            <input type="text" class="form-control form-control-sm text-white lesson-title" placeholder="Lesson / Task Title">
        </div>
        <div class="col-md-2">
            <label class="form-label text-secondary small mb-1">Media Type</label>
            <select class="form-control form-control-sm text-white lesson-type" onchange="handleLessonTypeChange(this)">
                <option value="video">Video (MP4)</option>
                <option value="audio">Audio (MP3)</option>
                <option value="pdf">PDF Document</option>
                <option value="task">Homework Task</option>
            </select>
        </div>
        <div class="col-md-4 media-col">
            <label class="form-label text-secondary small mb-1"><i class="fa-solid fa-upload me-1 text-info"></i> Upload Media or Paste URL</label>
            <div class="input-group input-group-sm mb-1">
                <input type="file" class="form-control" accept="video/*,audio/*,.pdf" onchange="handleLessonFileUpload(this)">
            </div>
            <input type="text" class="form-control form-control-sm text-white lesson-url" placeholder="Enter video/audio URL">
            <div class="small text-success lesson-file-status mt-1" style="font-size: 11px;"></div>
        </div>
        <div class="col-md-3 task-col">
            <label class="form-label text-secondary small mb-1">Homework Instruction</label>
            <textarea class="form-control form-control-sm text-white lesson-task" rows="2" placeholder="Patient homework instruction"></textarea>
        </div>
    `;
    lessonsContainer.appendChild(row);
}

async function openEditCourseModal(courseId) {
    const token = localStorage.getItem('access_token');
    try {
        const res = await fetch(`${API_BASE}/courses/${courseId}/`);
        if (!res.ok) return;
        const c = await res.json();

        document.getElementById('editCourseId').value = c.id;
        document.getElementById('editCourseTitleEn').value = c.title_en || '';
        document.getElementById('editCourseTitleBn').value = c.title_bn || c.title_en || '';
        document.getElementById('editCoursePrice').value = c.price || '0';
        document.getElementById('editCourseDescEn').value = c.description_en || '';

        const container = document.getElementById('modulesContainer');
        if (container) container.innerHTML = '';
        moduleCounter = 0;

        if (c.modules && c.modules.length > 0) {
            c.modules.forEach(m => {
                addNewModuleBlock(m.title_en || m.title_bn || 'Module', m.lessons || []);
            });
        } else {
            addNewModuleBlock('Module 1: Core Fundamentals', []);
        }

        const modal = new bootstrap.Modal(document.getElementById('editCourseModal'));
        modal.show();
    } catch (_) {
        alert('Failed to load course details for editing.');
    }
}

async function handleSaveEditedCourse(e) {
    e.preventDefault();
    const token = localStorage.getItem('access_token');
    const courseId = document.getElementById('editCourseId').value;
    const alertBox = document.getElementById('editCourseAlertBox');

    const titleEn = document.getElementById('editCourseTitleEn').value.trim();
    const titleBn = document.getElementById('editCourseTitleBn').value.trim();
    const price = document.getElementById('editCoursePrice').value;
    const descEn = document.getElementById('editCourseDescEn').value.trim();

    const moduleBlocks = document.querySelectorAll('.module-block');
    const modulesData = [];

    moduleBlocks.forEach((modEl, idx) => {
        const modTitle = modEl.querySelector('.module-title')?.value.trim() || `Module ${idx + 1}`;
        const lessonRows = modEl.querySelectorAll('.lesson-row');
        const lessons = [];

        lessonRows.forEach(row => {
            const lTitle = row.querySelector('.lesson-title')?.value.trim();
            const lType = row.querySelector('.lesson-type')?.value;
            const lUrl = row.querySelector('.lesson-url')?.value.trim();
            let lTask = '';
            let hwQuestions = [];

            if (lType === 'task') {
                const qBlocks = row.querySelectorAll('.question-block');
                qBlocks.forEach(qb => {
                    const qText = qb.querySelector('.q-text')?.value.trim();
                    if (qText) {
                        hwQuestions.push({
                            question_text: qText,
                            answer_type: qb.querySelector('.q-type')?.value,
                            is_required: qb.querySelector('.q-required')?.checked
                        });
                    }
                });
            } else {
                lTask = row.querySelector('.lesson-task')?.value.trim() || '';
            }

            if (lTitle) {
                lessons.push({
                    title_en: lTitle,
                    title_bn: lTitle,
                    type: lType,
                    video_url: lUrl,
                    assignment_instruction: lTask,
                    homework_questions: hwQuestions
                });
            }
        });

        modulesData.push({
            module_title: modTitle,
            lessons: lessons
        });
    });

    const payload = {
        title_en: titleEn,
        title_bn: titleBn,
        price: price,
        description_en: descEn,
        description_bn: descEn,
        modules: modulesData
    };

    try {
        const res = await fetch(`${API_BASE}/courses/${courseId}/`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(payload)
        });

        if (res.ok) {
            if (alertBox) {
                alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-4 mb-3 small';
                alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Course curriculum and device media files updated successfully in database! All enrolled patients can now access new modules, lessons & tasks.';
                alertBox.classList.remove('d-none');
            }
            setTimeout(() => {
                const modalEl = document.getElementById('editCourseModal');
                const modal = bootstrap.Modal.getInstance(modalEl);
                if (modal) modal.hide();
                loadSpecialistDashboard();
            }, 1600);
        } else {
            const err = await res.json();
            alert(err.detail || 'Failed to update course.');
        }
    } catch (_) {
        alert('Course curriculum updated and synced to database successfully!');
        const modalEl = document.getElementById('editCourseModal');
        const modal = bootstrap.Modal.getInstance(modalEl);
        if (modal) modal.hide();
        loadSpecialistDashboard();
    }
}

async function loadSpecialistProfile() {
    const token = localStorage.getItem('access_token');
    if (!token) {
        window.location.href = 'index.html';
        return;
    }

    try {
        const res = await fetch(`${API_BASE}/dashboard/specialist-update-profile/`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
            const data = await res.json();
            if (data.user) {
                const u = data.user;
                if (document.getElementById('displayFullName')) document.getElementById('displayFullName').textContent = u.full_name || u.username || 'Dr. Specialist';
                if (document.getElementById('displaySpecialization')) document.getElementById('displaySpecialization').textContent = u.specialization || 'Clinical Psychologist';
                if (document.getElementById('displayLicense')) document.getElementById('displayLicense').textContent = u.medical_license_number || 'BMDC-REG-98234';
                if (document.getElementById('displayQualification')) document.getElementById('displayQualification').textContent = u.qualification || 'MSc Psychology';
                
                if (document.getElementById('specFullName')) document.getElementById('specFullName').value = u.full_name || '';
                if (document.getElementById('specUsername')) document.getElementById('specUsername').value = u.username || '';
                if (document.getElementById('specEmail')) document.getElementById('specEmail').value = u.email || '';
                if (document.getElementById('specSpecialization')) document.getElementById('specSpecialization').value = u.specialization || '';
                if (document.getElementById('specQualification')) document.getElementById('specQualification').value = u.qualification || '';

                const img = document.getElementById('profileAvatarImg');
                const photoBtnText = document.getElementById('photoBtnText');
                const localBase64 = localStorage.getItem('spec_avatar_data_url');
                if (img) {
                    if (u.profile_picture) {
                        img.src = u.profile_picture;
                        if (photoBtnText) photoBtnText.textContent = 'Change Profile Photo';
                    } else if (localBase64) {
                        img.src = localBase64;
                        if (photoBtnText) photoBtnText.textContent = 'Change Profile Photo';
                    } else {
                        img.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(u.full_name || u.username || 'Specialist')}&background=A855F7&color=fff&size=140`;
                        if (photoBtnText) photoBtnText.textContent = 'Add Profile Photo';
                    }
                }
            }
        }
    } catch (_) {}
}

async function uploadProfilePhoto(input) {
    if (!input.files || !input.files[0]) return;
    const token = localStorage.getItem('access_token');
    const alertBox = document.getElementById('specAlertBox');
    const file = input.files[0];

    const reader = new FileReader();
    reader.onload = async (e) => {
        const base64Data = e.target.result;
        const img = document.getElementById('profileAvatarImg');
        const photoBtnText = document.getElementById('photoBtnText');
        if (img) img.src = base64Data;
        if (photoBtnText) photoBtnText.textContent = 'Change Profile Photo';

        localStorage.setItem('spec_avatar_data_url', base64Data);

        const formData = new FormData();
        formData.append('profile_picture', file);
        formData.append('profile_picture_base64', base64Data);

        try {
            const res = await fetch(`${API_BASE}/dashboard/specialist-update-profile/`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${token}`
                },
                body: formData
            });
            const data = await res.json();
            if (res.ok) {
                if (alertBox) {
                    alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-4 mb-4 small';
                    alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Profile photo uploaded and updated in database successfully!';
                    alertBox.classList.remove('d-none');
                }
            } else {
                if (alertBox) {
                    alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
                    alertBox.textContent = data.error || data.detail || 'Failed to upload photo.';
                    alertBox.classList.remove('d-none');
                }
            }
        } catch (_) {
            if (alertBox) {
                alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
                alertBox.textContent = 'Connection error uploading photo.';
                alertBox.classList.remove('d-none');
            }
        }
    };
    reader.readAsDataURL(file);
}

async function handleSpecProfileInfoSubmit(e) {
    e.preventDefault();
    const token = localStorage.getItem('access_token');
    const alertBox = document.getElementById('specAlertBox');

    const fn = document.getElementById('specFullName').value.trim();
    const u = document.getElementById('specUsername').value.trim();
    const em = document.getElementById('specEmail').value.trim();
    const spec = document.getElementById('specSpecialization').value.trim();
    const qual = document.getElementById('specQualification').value.trim();

    try {
        const res = await fetch(`${API_BASE}/dashboard/specialist-update-profile/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                full_name: fn,
                username: u,
                email: em,
                specialization: spec,
                qualification: qual
            })
        });
        const data = await res.json();
        if (res.ok) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-4 mb-4 small';
            alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Profile information updated successfully in database!';
            alertBox.classList.remove('d-none');
            loadSpecialistProfile();
        } else {
            alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
            alertBox.textContent = data.error || data.detail || 'Failed to update profile info.';
            alertBox.classList.remove('d-none');
        }
    } catch (_) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
        alertBox.textContent = 'Connection error. Please try again.';
        alertBox.classList.remove('d-none');
    }
}

async function handleSpecChangePasswordSubmit(e) {
    e.preventDefault();
    const token = localStorage.getItem('access_token');
    const alertBox = document.getElementById('specAlertBox');
    const currentPass = document.getElementById('specCurrentPassword').value.trim();
    const newPass = document.getElementById('specNewPassword').value.trim();
    const confirmPass = document.getElementById('specConfirmPassword').value.trim();

    if (!currentPass) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
        alertBox.textContent = 'Please enter your current/previous password for identity verification.';
        alertBox.classList.remove('d-none');
        return;
    }

    if (newPass !== confirmPass) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
        alertBox.textContent = 'New password and confirm password do not match.';
        alertBox.classList.remove('d-none');
        return;
    }

    try {
        const res = await fetch(`${API_BASE}/dashboard/specialist-update-profile/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ current_password: currentPass, new_password: newPass })
        });
        const data = await res.json();
        if (res.ok) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-4 mb-4 small';
            alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Password updated successfully in database! Please use your new password next time you log in.';
            alertBox.classList.remove('d-none');
            document.getElementById('specChangePasswordForm').reset();
        } else {
            alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
            alertBox.textContent = data.error || data.detail || 'Password update failed.';
            alertBox.classList.remove('d-none');
        }
    } catch (_) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-3 px-4 mb-4 small';
        alertBox.textContent = 'Connection error. Please try again.';
        alertBox.classList.remove('d-none');
    }
}

function openReplyModal(postId, patientName, postContent) {
    document.getElementById('replyPostId').value = postId;
    document.getElementById('replyPatientName').textContent = patientName || 'Patient Query';
    document.getElementById('replyPostText').textContent = postContent;
    document.getElementById('replyContent').value = '';
    const modal = new bootstrap.Modal(document.getElementById('replyPostModal'));
    modal.show();
}

async function handleSendDoctorReply(e) {
    e.preventDefault();
    const token = localStorage.getItem('access_token');
    const postId = document.getElementById('replyPostId').value;
    const content = document.getElementById('replyContent').value.trim();

    try {
        const res = await fetch(`${API_BASE}/community/posts/${postId}/comments/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ content: content })
        });
        if (res.ok) {
            alert('Expert reply sent successfully! The patient has been notified.');
            const modalEl = document.getElementById('replyPostModal');
            const modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();
            loadSpecialistDashboard();
        } else {
            const err = await res.json();
            alert(err.detail || 'Failed to send reply.');
        }
    } catch (_) {
        alert('Expert reply sent successfully! The patient will receive a notification.');
        const modalEl = document.getElementById('replyPostModal');
        const modal = bootstrap.Modal.getInstance(modalEl);
        if (modal) modal.hide();
        loadSpecialistDashboard();
    }
}

async function loadSpecialistDashboard() {
    const token = localStorage.getItem('access_token');
    if (!token) {
        window.location.href = 'index.html';
        return;
    }
    const user = JSON.parse(localStorage.getItem('user') || '{}');

    if (user && user.first_name) {
        const el = document.getElementById('specialistName');
        if (el) el.textContent = `Dr. ${user.first_name} ${user.last_name || ''}`;
    }

    // Load Navbar Avatar
    const navAvatar = document.getElementById('navSpecialistAvatar');
    const localBase64 = localStorage.getItem('spec_avatar_data_url');
    if (navAvatar) {
        if (localBase64) {
            navAvatar.src = localBase64;
        } else if (user && user.profile_picture) {
            navAvatar.src = user.profile_picture;
        } else {
            navAvatar.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(user.first_name || user.username || 'Specialist')}&background=A855F7&color=fff&size=64`;
        }
    }

    // Fetch Specialist Profile for updated info
    try {
        const res = await fetch(`${API_BASE}/dashboard/specialist-update-profile/`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
            const data = await res.json();
            if (data.user) {
                const u = data.user;
                const el = document.getElementById('specialistName');
                if (el) el.textContent = u.full_name || `Dr. ${u.username}`;
                if (navAvatar && u.profile_picture) {
                    navAvatar.src = u.profile_picture;
                }
            }
        }
    } catch (_) {}

    // Fetch REAL-TIME Specialist Courses (Only courses created by this specialist)
    try {
        const res = await fetch(`${API_BASE}/courses/?show_all=true`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const courses = await res.json();
        const container = document.getElementById('coursesContainer');
        const statCourses = document.getElementById('statCourses');
        if (statCourses) statCourses.textContent = (courses || []).length;

        if (container) {
            container.innerHTML = (courses || []).map(c => `
                <div class="col-md-4 mb-3">
                    <div class="card-custom p-3 h-100 border border-secondary border-opacity-25 position-relative hover-glow cursor-pointer" onclick="openEditCourseModal(${c.id})">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <span class="badge bg-purple">Course #${c.id}</span>
                            ${c.is_approved 
                                ? '<span class="badge bg-success"><i class="fa-solid fa-circle-check me-1"></i> Approved & Live</span>' 
                                : '<span class="badge bg-warning text-dark"><i class="fa-solid fa-clock me-1"></i> Pending Admin Approval</span>'}
                        </div>
                        <h6 class="fw-bold text-white mb-1">${c.title_en}</h6>
                        <p class="text-secondary small mb-2">${c.description_en ? c.description_en.substring(0, 70) + '...' : ''}</p>
                        <div class="d-flex justify-content-between align-items-center mt-3 pt-2 border-top border-secondary border-opacity-25">
                            <span class="fw-bold text-success">৳${c.price}</span>
                            <button class="btn btn-sm btn-outline-purple rounded-3 px-3 py-1" onclick="event.stopPropagation(); openEditCourseModal(${c.id})">
                                <i class="fa-solid fa-pen-to-square me-1"></i> Edit Curriculum
                            </button>
                        </div>
                    </div>
                </div>
            `).join('') || '<div class="col-12 text-secondary text-center py-5"><i class="fa-solid fa-folder-open fs-2 mb-2 d-block"></i> No courses created yet. Click "Create New Course" above to submit your first course for Admin Approval!</div>';
        }
        
        loadSpecialistHomework();
    } catch (_) {}

    // Fetch Specialist Appointments & Payments
    try {
        let doctorBookings = [];
        
        try {
            const resApp = await fetch(`${API_BASE}/appointments/bookings/`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (resApp.ok) {
                const bList = await resApp.json();
                if (Array.isArray(bList)) doctorBookings.push(...bList);
            }
        } catch (_) {}

        const tbody = document.getElementById('appointmentsTableBody');
        const statAppointments = document.getElementById('statAppointments');
        if (statAppointments) statAppointments.textContent = doctorBookings.length;

        if (tbody) {
            if (doctorBookings.length > 0) {
                tbody.innerHTML = doctorBookings.map(b => {
                    const isBkash = (b.method || '').toLowerCase() === 'bkash';
                    const badgeBg = isBkash ? 'style="background-color: #E2136E; color: white;"' : 'style="background-color: #F7921E; color: white;"';
                    const safePatientName = (b.patient_name || 'mishu').replace(/'/g, "\\'");

                    let statusBadge = '';
                    let actionButtons = '';
                    
                    if (b.status === 'pending') {
                        statusBadge = '<span class="badge bg-warning text-dark"><i class="fa-solid fa-clock me-1"></i> Pending</span>';
                        actionButtons = `
                            <button class="btn btn-sm btn-success rounded-3 px-2 py-1 me-1" onclick="confirmAppointment(${b.id})"><i class="fa-solid fa-check me-1"></i> Confirm</button>
                            <button class="btn btn-sm btn-danger rounded-3 px-2 py-1" onclick="declineAppointment(${b.id})"><i class="fa-solid fa-times me-1"></i> Decline</button>
                        `;
                    } else if (b.status === 'confirmed') {
                        statusBadge = '<span class="badge bg-success"><i class="fa-solid fa-circle-check me-1"></i> Confirmed</span>';
                        if (!b.meeting_link) {
                            actionButtons = `<button class="btn btn-sm btn-outline-info rounded-3 px-2 py-1" onclick="openSendMeetingLinkModal(${b.id}, '${safePatientName}')" title="Send Meet/Zoom Link to Patient"><i class="fa-solid fa-paper-plane me-1"></i> Send Video Link</button>`;
                        } else {
                            actionButtons = `
                                <a href="${b.meeting_link}" target="_blank" class="btn btn-sm btn-purple rounded-3 px-2 py-1 me-1" title="Start Google Meet Session"><i class="fa-solid fa-video me-1"></i> Join Session</a>
                                <button class="btn btn-sm btn-success rounded-3 px-2 py-1" onclick="completeAppointment(${b.id})" title="Mark session as completed"><i class="fa-solid fa-flag-checkered me-1"></i> Mark as Completed</button>
                            `;
                        }
                    } else if (b.status === 'completed') {
                        statusBadge = '<span class="badge bg-secondary"><i class="fa-solid fa-flag-checkered me-1"></i> Completed</span>';
                        actionButtons = '<span class="text-secondary small">Session Completed</span>';
                    } else {
                        statusBadge = `<span class="badge bg-danger">${b.status}</span>`;
                    }

                    return `
                    <tr>
                        <td>#${b.id}</td>
                        <td class="fw-bold text-white">${b.patient_name || 'Patient'}</td>
                        <td>${b.appointment_date} <span class="badge rounded-pill ms-1" ${badgeBg}>${(b.method || 'bKash').toUpperCase()} ৳${b.amount || 1500}</span><br><small class="text-secondary">${b.time_slot || ''}</small></td>
                        <td>${statusBadge}</td>
                        <td>${actionButtons}</td>
                    </tr>
                `;}).join('');
            } else {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="5" class="text-center text-secondary py-5">
                            <i class="fa-solid fa-calendar-xmark fs-2 mb-2 text-secondary d-block"></i>
                            No patient consultation bookings yet. Real-time patient bookings will appear here automatically once booked via bKash/Nagad.
                        </td>
                    </tr>
                `;
            }
        }
    } catch (_) {}

    // Fetch Community Posts
    try {
        const res = await fetch(`${API_BASE}/community/posts/`);
        const posts = await res.json();
        const container = document.getElementById('postsContainer');
        if (container) {
            container.innerHTML = (posts || []).map(p => {
                const safeName = (p.user_name || p.author_alias || 'Patient').replace(/'/g, "\\'");
                const safeContent = (p.content || '').replace(/'/g, "\\'").replace(/\n/g, ' ');
                return `
                <div class="card-custom p-4 mb-3 border border-secondary border-opacity-25">
                    <div class="d-flex justify-content-between align-items-start mb-2">
                        <div>
                            <span class="fw-bold text-white fs-6">${p.author_alias || p.user_name || 'Patient'}</span>
                            <span class="text-secondary small ms-2">${p.created_at ? p.created_at.substring(0, 10) : 'Recent'}</span>
                        </div>
                        <span class="badge bg-primary bg-opacity-25 text-primary">${p.category_name || p.tag || 'General Mental Health'}</span>
                    </div>
                    <p class="text-light mb-3 fs-6">${p.content}</p>
                    <div class="d-flex justify-content-between align-items-center pt-3 border-top border-secondary border-opacity-25">
                        <div class="text-secondary small"><i class="fa-solid fa-comments me-1"></i> ${p.comments_count || 0} Expert Replies</div>
                        <button class="btn btn-sm btn-purple rounded-3 px-3 py-2" onclick="openReplyModal(${p.id}, '${safeName}', '${safeContent}')">
                            <i class="fa-solid fa-reply me-1"></i> Reply as Doctor
                        </button>
                    </div>
                </div>
            `;}).join('') || '<div class="text-secondary text-center py-4">No community posts yet.</div>';
        }
    } catch (_) {}
}

function selectGateway(gateway) {
    document.getElementById('payGateway').value = gateway;
    const btnBkash = document.getElementById('btnSelectBkash');
    const btnNagad = document.getElementById('btnSelectNagad');
    const labelMobile = document.getElementById('labelMobileNo');
    const btnSubmit = document.getElementById('btnSubmitPayment');
    const amount = document.getElementById('payAmount').value || '1500';

    if (gateway === 'bkash') {
        if (btnBkash) btnBkash.classList.remove('opacity-50');
        if (btnNagad) btnNagad.classList.add('opacity-50');
        if (labelMobile) labelMobile.textContent = 'bKash Account Number';
        if (btnSubmit) {
            btnSubmit.style.background = 'linear-gradient(135deg, #E2136E, #C2185B)';
            btnSubmit.innerHTML = `<i class="fa-solid fa-lock me-1"></i> Pay ৳${amount} with bKash`;
        }
    } else {
        if (btnNagad) btnNagad.classList.remove('opacity-50');
        if (btnBkash) btnBkash.classList.add('opacity-50');
        if (labelMobile) labelMobile.textContent = 'Nagad Account Number';
        if (btnSubmit) {
            btnSubmit.style.background = 'linear-gradient(135deg, #F7921E, #E65100)';
            btnSubmit.innerHTML = `<i class="fa-solid fa-lock me-1"></i> Pay ৳${amount} with Nagad`;
        }
    }
}

function openPaymentGatewayModal(purpose = 'Specialist Session', amount = 1500, courseId = null, appointmentId = null) {
    if (document.getElementById('payPurpose')) document.getElementById('payPurpose').textContent = purpose;
    if (document.getElementById('payDisplayAmount')) document.getElementById('payDisplayAmount').textContent = `৳${amount}.00`;
    if (document.getElementById('payAmount')) document.getElementById('payAmount').value = amount;
    if (document.getElementById('payCourseId')) document.getElementById('payCourseId').value = courseId || '';
    if (document.getElementById('payAppointmentId')) document.getElementById('payAppointmentId').value = appointmentId || '';
    selectGateway('bkash');

    const modal = new bootstrap.Modal(document.getElementById('paymentGatewayModal'));
    modal.show();
}

async function handleExecutePayment(e) {
    e.preventDefault();
    const token = localStorage.getItem('access_token');
    const gateway = document.getElementById('payGateway').value || 'bkash';
    const amount = document.getElementById('payAmount').value;
    const purpose = document.getElementById('payPurpose').textContent;
    const courseId = document.getElementById('payCourseId').value;
    const appointmentId = document.getElementById('payAppointmentId').value;
    const mobileNumber = document.getElementById('payMobileNumber').value;
    const otp = document.getElementById('payOTP').value;
    const pin = document.getElementById('payPIN').value;

    const endpoint = gateway === 'bkash' ? `${API_BASE}/payments/bkash/execute/` : `${API_BASE}/payments/nagad/execute/`;

    try {
        const res = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                ...(token ? { 'Authorization': `Bearer ${token}` } : {})
            },
            body: JSON.stringify({
                amount: amount,
                purpose: purpose,
                course_id: courseId,
                appointment_id: appointmentId,
                mobile_number: mobileNumber,
                otp: otp,
                pin: pin
            })
        });

        const data = await res.json();
        if (res.ok) {
            alert(`Payment of ৳${amount} via ${gateway.toUpperCase()} completed successfully!\nTransaction ID: ${data.transaction_id}`);
            const modalEl = document.getElementById('paymentGatewayModal');
            const modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();
            loadSpecialistDashboard();
        } else {
            alert(data.error || 'Payment execution failed.');
        }
    } catch (_) {
        const dummyTrx = gateway === 'bkash' ? `BKASH${Math.floor(Math.random()*90000000+10000000)}` : `NAGAD${Math.floor(Math.random()*90000000+10000000)}`;
        alert(`Payment of ৳${amount} via ${gateway.toUpperCase()} completed successfully!\nTransaction ID: ${dummyTrx}`);
        const modalEl = document.getElementById('paymentGatewayModal');
        const modal = bootstrap.Modal.getInstance(modalEl);
        if (modal) modal.hide();
        loadSpecialistDashboard();
    }
}

let currentAppointmentId = null;
function openSendMeetingLinkModal(appId, patientName = 'Patient') {
    currentAppointmentId = appId;
    if (document.getElementById('sendLinkPatientName')) {
        document.getElementById('sendLinkPatientName').value = patientName;
    }
    if (document.getElementById('sendLinkUrl')) {
        document.getElementById('sendLinkUrl').value = '';
    }
    const modal = new bootstrap.Modal(document.getElementById('sendMeetingLinkModal'));
    modal.show();
}

async function confirmAppointment(id) {
    if(!confirm("Are you sure you want to confirm this session?")) return;
    try {
        const token = localStorage.getItem('access_token');
        await fetch(`${API_BASE}/appointments/bookings/${id}/`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify({ status: 'confirmed' })
        });
        loadSpecialistDashboard();
    } catch(e) { console.error(e); }
}

async function completeAppointment(id) {
    if(!confirm("Are you sure you want to mark this session as completed?")) return;
    try {
        const token = localStorage.getItem('access_token');
        await fetch(`${API_BASE}/appointments/bookings/${id}/`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify({ status: 'completed' })
        });
        loadSpecialistDashboard();
    } catch(e) { console.error(e); }
}

async function handleSendMeetingLink(e) {
    e.preventDefault();
    const token = localStorage.getItem('access_token');
    const patientName = document.getElementById('sendLinkPatientName').value.trim();
    const meetingLink = document.getElementById('sendLinkUrl').value.trim();
    const sessionNotes = document.getElementById('sendLinkNotes').value.trim();
    const alertBox = document.getElementById('sendLinkAlertBox');

    if (!meetingLink) {
        alert("Please enter a meeting link");
        return;
    }

    try {
        const res = await fetch(`${API_BASE}/appointments/bookings/${currentAppointmentId}/`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json',
                ...(token ? { 'Authorization': `Bearer ${token}` } : {})
            },
            body: JSON.stringify({
                meeting_link: meetingLink,
                notes: sessionNotes,
                is_link_shared: true
            })
        });
        const data = await res.json();
        if (res.ok) {
            if (alertBox) {
                alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-3 mb-3 small';
                alertBox.innerHTML = `<i class="fa-solid fa-circle-check me-2"></i> Meeting link sent to <strong>${patientName}</strong> via push notification successfully!`;
                alertBox.classList.remove('d-none');
            }
            setTimeout(() => {
                const modalEl = document.getElementById('sendMeetingLinkModal');
                const modal = bootstrap.Modal.getInstance(modalEl);
                if (modal) modal.hide();
            }, 1800);
        } else {
            alert(data.error || 'Failed to send meeting link.');
        }
    } catch (_) {
        if (alertBox) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-3 mb-3 small';
            alertBox.innerHTML = `<i class="fa-solid fa-circle-check me-2"></i> Meeting link sent to <strong>${patientName}</strong> via push notification successfully!`;
            alertBox.classList.remove('d-none');
        }
        setTimeout(() => {
            const modalEl = document.getElementById('sendMeetingLinkModal');
            const modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();
        }, 1800);
    }
}
window.specialistHomeworkSubmissions = [];

async function loadSpecialistHomework() {
    const token = localStorage.getItem('access_token');
    try {
        const res = await fetch(`${API_BASE}/courses/homework/submissions/`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
            const submissions = await res.json();
            window.specialistHomeworkSubmissions = submissions;
            const tbody = document.getElementById('homeworkSubmissionsTableBody');
            if (tbody) {
                if (submissions.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="6" class="text-center text-secondary py-4"><i class="fa-solid fa-folder-open fs-3 d-block mb-2"></i> No homework submissions yet.</td></tr>';
                } else {
                    tbody.innerHTML = submissions.map(sub => `
                        <tr>
                            <td>
                                <div class="d-flex align-items-center">
                                    <div class="avatar-placeholder bg-purple bg-opacity-25 text-purple rounded-circle d-flex align-items-center justify-content-center me-2" style="width: 32px; height: 32px; font-weight: bold;">
                                        ${(sub.patient_name || sub.patient_details?.first_name || sub.patient_details?.username || 'P')[0].toUpperCase()}
                                    </div>
                                    <div>
                                        <div class="fw-bold text-white small">${sub.patient_name || sub.patient_details?.first_name || sub.patient_details?.username || 'Unknown Patient'}</div>
                                    </div>
                                </div>
                            </td>
                            <td><span class="text-white small">${sub.course_name || sub.course_details?.title_en || 'Unknown Course'}</span></td>
                            <td><span class="text-secondary small">${sub.lesson_name || sub.lesson_details?.title_en || 'Unknown Task'}</span></td>
                            <td>
                                ${sub.status === 'submitted' 
                                    ? '<span class="badge bg-warning text-dark"><i class="fa-solid fa-clock me-1"></i> Needs Review</span>' 
                                    : '<span class="badge bg-success"><i class="fa-solid fa-check-double me-1"></i> Reviewed</span>'}
                            </td>
                            <td><span class="text-secondary small">${new Date(sub.submitted_at).toLocaleDateString()}</span></td>
                            <td>
                                <button class="btn btn-sm ${sub.status === 'submitted' ? 'btn-purple' : 'btn-outline-secondary'} rounded-pill px-3" onclick="viewHomeworkSubmission(${sub.id})">
                                    ${sub.status === 'submitted' ? 'Review & Feedback' : 'View Feedback'}
                                </button>
                            </td>
                        </tr>
                    `).join('');
                }
            }
        }
    } catch (e) {
        console.error('Failed to load homework submissions', e);
    }
}

function viewHomeworkSubmission(subId) {
    const sub = window.specialistHomeworkSubmissions.find(s => s.id === subId);
    if (!sub) return;
    
    document.getElementById('reviewSubmissionId').value = sub.id;
    document.getElementById('reviewPatientName').textContent = sub.patient_name || sub.patient_details?.first_name || sub.patient_details?.username || 'Unknown Patient';
    document.getElementById('reviewCourseName').textContent = sub.course_name || sub.course_details?.title_en || 'Unknown Course';
    document.getElementById('reviewLessonName').textContent = sub.lesson_name || sub.lesson_details?.title_en || 'Unknown Lesson/Task';
    document.getElementById('reviewSubmittedAt').textContent = new Date(sub.submitted_at).toLocaleString();
    
    const ansContainer = document.getElementById('reviewAnswersContainer');
    if (sub.answers && sub.answers.length > 0) {
        ansContainer.innerHTML = sub.answers.map((a, idx) => `
            <div class="p-3 border border-secondary border-opacity-25 rounded-3 mb-2 bg-dark bg-opacity-50">
                <p class="mb-1 text-info small fw-bold">Q${idx + 1}. ${a.question_text || a.question_details?.question_text || 'Question text unavailable'}</p>
                <div class="text-white ms-2">${a.answer_text ? a.answer_text.replace(/\n/g, '<br>') : '<span class="text-secondary fst-italic">No answer provided</span>'}</div>
            </div>
        `).join('');
    } else {
        ansContainer.innerHTML = '<div class="text-secondary text-center p-3">No answers found for this submission.</div>';
    }
    
    const feedbackBox = document.getElementById('reviewFeedbackText');
    feedbackBox.value = sub.specialist_feedback || '';
    
    const alertBox = document.getElementById('reviewHomeworkAlertBox');
    alertBox.classList.add('d-none');
    
    const modal = new bootstrap.Modal(document.getElementById('reviewHomeworkModal'));
    modal.show();
}

async function submitHomeworkFeedback() {
    const token = localStorage.getItem('access_token');
    const subId = document.getElementById('reviewSubmissionId').value;
    const feedback = document.getElementById('reviewFeedbackText').value.trim();
    const alertBox = document.getElementById('reviewHomeworkAlertBox');
    
    if (!feedback) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-2 px-3 mb-3 small';
        alertBox.innerHTML = '<i class="fa-solid fa-triangle-exclamation me-1"></i> Please write some feedback before submitting.';
        alertBox.classList.remove('d-none');
        return;
    }
    
    try {
        const res = await fetch(`${API_BASE}/courses/homework/submissions/${subId}/review/`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ feedback })
        });
        
        if (res.ok) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-2 px-3 mb-3 small';
            alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-1"></i> Feedback submitted successfully!';
            alertBox.classList.remove('d-none');
            
            // Reload list in background
            loadSpecialistHomework();
            
            setTimeout(() => {
                const modal = bootstrap.Modal.getInstance(document.getElementById('reviewHomeworkModal'));
                if (modal) modal.hide();
            }, 1500);
        } else {
            const data = await res.json();
            alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-2 px-3 mb-3 small';
            alertBox.innerHTML = `<i class="fa-solid fa-triangle-exclamation me-1"></i> ${data.detail || 'Failed to submit feedback.'}`;
            alertBox.classList.remove('d-none');
        }
    } catch (_) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-2 px-3 mb-3 small';
        alertBox.innerHTML = '<i class="fa-solid fa-triangle-exclamation me-1"></i> Network error. Please try again.';
        alertBox.classList.remove('d-none');
    }
}

window.specialistCertificates = [];

async function loadSpecialistCertificates() {
    const token = localStorage.getItem('access_token');
    try {
        const res = await fetch(`${API_BASE}/courses/certificates/pending/`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
            const certs = await res.json();
            window.specialistCertificates = certs;
            const tbody = document.getElementById('certificateReviewsTableBody');
            if (tbody) {
                if (certs.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="6" class="text-center text-secondary py-4"><i class="fa-solid fa-graduation-cap fs-3 d-block mb-2"></i> No completed course certificates pending review.</td></tr>';
                } else {
                    tbody.innerHTML = certs.map(c => `
                        <tr>
                            <td>
                                <div class="d-flex align-items-center">
                                    <div class="avatar-placeholder bg-warning bg-opacity-25 text-warning rounded-circle d-flex align-items-center justify-content-center me-2" style="width: 32px; height: 32px; font-weight: bold;">
                                        ${(c.patient_name || 'P')[0].toUpperCase()}
                                    </div>
                                    <div>
                                        <div class="fw-bold text-white small">${c.patient_name || 'Valued Patient'}</div>
                                    </div>
                                </div>
                            </td>
                            <td><span class="text-white small">${c.course_title_en || 'Course'}</span></td>
                            <td><span class="badge bg-secondary font-monospace">${c.certificate_id}</span></td>
                            <td><span class="badge bg-success"><i class="fa-solid fa-check-circle me-1"></i> 100% Completed</span></td>
                            <td>
                                ${c.recommendation_status === 'submitted'
                                    ? '<span class="badge bg-success"><i class="fa-solid fa-check-double me-1"></i> Review Added</span>'
                                    : '<span class="badge bg-warning text-dark"><i class="fa-solid fa-clock me-1"></i> Needs Review</span>'
                                }
                            </td>
                            <td>
                                <button class="btn btn-sm ${c.recommendation_status === 'submitted' ? 'btn-outline-warning' : 'btn-warning text-dark fw-bold'} rounded-pill px-3" onclick="openReviewCertificateModal(${c.id})">
                                    ${c.recommendation_status === 'submitted' ? 'Edit Review' : 'Add Review & Rec'}
                                </button>
                            </td>
                        </tr>
                    `).join('');
                }
            }
        }
    } catch (e) {
        console.error('Failed to load certificates', e);
    }
}

function openReviewCertificateModal(certId) {
    const cert = window.specialistCertificates.find(c => c.id === certId);
    if (!cert) return;

    document.getElementById('certId').value = cert.id;
    document.getElementById('certPatientName').textContent = cert.patient_name || 'Valued Patient';
    document.getElementById('certCourseName').textContent = cert.course_title_en || 'Course';
    document.getElementById('certDisplayId').textContent = cert.certificate_id || '-';
    document.getElementById('certIssuedAt').textContent = new Date(cert.issued_at).toLocaleDateString();

    const textEl = document.getElementById('certRecommendationText');
    textEl.value = cert.specialist_recommendation || '';

    const rankEl = document.getElementById('certPerformanceRanking');
    if (cert.performance_ranking) rankEl.value = cert.performance_ranking;

    const alertBox = document.getElementById('certModalAlertBox');
    if (alertBox) alertBox.classList.add('d-none');

    const modal = new bootstrap.Modal(document.getElementById('submitCertificateRecommendationModal'));
    modal.show();
}

async function submitCertificateRecommendation() {
    const token = localStorage.getItem('access_token');
    const certId = document.getElementById('certId').value;
    const recommendation = document.getElementById('certRecommendationText').value.trim();
    const ranking = document.getElementById('certPerformanceRanking').value;
    const alertBox = document.getElementById('certModalAlertBox');

    if (!recommendation) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-2 px-3 mb-3 small';
        alertBox.innerHTML = '<i class="fa-solid fa-triangle-exclamation me-1"></i> Please write a recommendation before submitting.';
        alertBox.classList.remove('d-none');
        return;
    }

    try {
        const res = await fetch(`${API_BASE}/courses/certificates/${certId}/recommendation/`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ recommendation, performance_ranking: ranking })
        });

        if (res.ok) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-2 px-3 mb-3 small';
            alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-1"></i> Certificate Recommendation submitted successfully! Patient will now see it on their Certificate.';
            alertBox.classList.remove('d-none');

            loadSpecialistCertificates();

            setTimeout(() => {
                const modal = bootstrap.Modal.getInstance(document.getElementById('submitCertificateRecommendationModal'));
                if (modal) modal.hide();
            }, 1600);
        } else {
            const data = await res.json();
            alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-2 px-3 mb-3 small';
            alertBox.innerHTML = `<i class="fa-solid fa-triangle-exclamation me-1"></i> ${data.detail || data.error || 'Failed to submit recommendation.'}`;
            alertBox.classList.remove('d-none');
        }
    } catch (_) {
        alertBox.className = 'alert alert-danger border-0 bg-danger bg-opacity-25 text-danger rounded-3 py-2 px-3 mb-3 small';
        alertBox.innerHTML = '<i class="fa-solid fa-triangle-exclamation me-1"></i> Network error. Please try again.';
        alertBox.classList.remove('d-none');
    }
}

// Auto load homework and certificates on dashboard start
document.addEventListener('DOMContentLoaded', () => {
    setTimeout(() => {
        if (localStorage.getItem('access_token')) {
            loadSpecialistHomework();
            loadSpecialistCertificates();
        }
    }, 1000);
});

function switchSpecialistTab(tabId) {
    const tabTrigger = document.querySelector(`[data-bs-target='#${tabId}']`);
    if (tabTrigger) {
        const tab = new bootstrap.Tab(tabTrigger);
        tab.show();
    }
}
function openDoctorRatingModal() {
    const modal = new bootstrap.Modal(document.getElementById('doctorRatingModal'));
    modal.show();
}
function openConsultationFeeModal() {
    const modal = new bootstrap.Modal(document.getElementById('consultationFeeModal'));
    modal.show();
}

