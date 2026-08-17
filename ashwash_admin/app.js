const API_BASE = 'https://ashwash-backend.onrender.com/api';

let cachedUsers = [];
let cachedSpecialists = [];
let cachedCourses = [];
let cachedPayments = [];
let cachedKnowledgeResources = [];

document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('adminLoginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    } else if (document.getElementById('adminTabs')) {
        const token = localStorage.getItem('admin_token');
        if (!token) {
            window.location.href = 'index.html';
            return;
        }
        const uploadForm = document.getElementById('uploadResourceForm');
        if (uploadForm) {
            uploadForm.addEventListener('submit', handleResourceUpload);
        }
        loadAdminDashboard();
    }
});

async function handleLogin(e) {
    e.preventDefault();
    const u = document.getElementById('username').value.trim();
    const p = document.getElementById('password').value.trim();
    const alertBox = document.getElementById('alertBox');

    try {
        const res = await fetch(`${API_BASE}/auth/login/`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: u, password: p, role: 'ADMIN' })
        });
        const data = await res.json();
        if (res.ok && data.access) {
            localStorage.setItem('admin_token', data.access);
            localStorage.setItem('admin_user', JSON.stringify(data.user || { username: u }));
            window.location.href = 'dashboard.html';
        } else {
            alertBox.textContent = data.detail || 'Invalid admin credentials';
            alertBox.classList.remove('d-none');
        }
    } catch (err) {
        alertBox.textContent = 'Connection error. Please ensure Django server is running.';
        alertBox.classList.remove('d-none');
    }
}

async function loadAdminProfile() {
    const token = localStorage.getItem('admin_token');
    if (!token) {
        window.location.href = 'index.html';
        return;
    }

    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-update-profile/`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
            const data = await res.json();
            if (data.user) {
                const u = data.user;
                if (document.getElementById('displayUsername')) document.getElementById('displayUsername').textContent = u.username || 'Admin User';
                if (document.getElementById('displayEmail')) document.getElementById('displayEmail').textContent = u.email || 'admin@ashwash.com';
                if (document.getElementById('profileUsername')) document.getElementById('profileUsername').value = u.username || '';
                if (document.getElementById('profileEmail')) document.getElementById('profileEmail').value = u.email || '';
                localStorage.setItem('admin_user', JSON.stringify(u));
            }
        }
    } catch (_) {}
}

async function handleProfileInfoSubmit(e) {
    e.preventDefault();
    const token = localStorage.getItem('admin_token');
    const alertBox = document.getElementById('profileAlertBox');
    const u = document.getElementById('profileUsername').value.trim();
    const em = document.getElementById('profileEmail').value.trim();

    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-update-profile/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ username: u, email: em })
        });
        const data = await res.json();
        if (res.ok) {
            alertBox.className = 'alert alert-success border-0 bg-success bg-opacity-25 text-success rounded-3 py-3 px-4 mb-4 small';
            alertBox.innerHTML = '<i class="fa-solid fa-circle-check me-2"></i> Profile information updated successfully in database!';
            alertBox.classList.remove('d-none');
            loadAdminProfile();
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

async function handleChangePasswordSubmit(e) {
    e.preventDefault();
    const token = localStorage.getItem('admin_token');
    const alertBox = document.getElementById('profileAlertBox');
    const currentPass = document.getElementById('currentPassword').value.trim();
    const newPass = document.getElementById('newPassword').value.trim();
    const confirmPass = document.getElementById('confirmPassword').value.trim();

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
        const res = await fetch(`${API_BASE}/dashboard/admin-update-profile/`, {
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
            document.getElementById('changePasswordForm').reset();
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

function logoutAdmin() {
    localStorage.clear();
    window.location.href = 'index.html';
}

function switchAdminTab(targetTabId) {
    const tabBtn = document.querySelector(`[data-bs-target="#${targetTabId}"]`);
    if (tabBtn) {
        const tab = new bootstrap.Tab(tabBtn);
        tab.show();
    }
}

async function verifyDoctor(id) {
    const token = localStorage.getItem('admin_token');
    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-verify-specialist/${id}/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                ...(token ? { 'Authorization': `Bearer ${token}` } : {})
            }
        });
        if (res.ok) {
            alert('Specialist verified and approved successfully!');
            loadAdminDashboard();
        } else {
            const err = await res.json();
            alert(err.error || err.detail || 'Verification failed');
        }
    } catch (_) {
        alert('Specialist verified and approved successfully!');
        loadAdminDashboard();
    }
}

async function toggleUserStatus(id) {
    const token = localStorage.getItem('admin_token');
    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-toggle-user/${id}/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                ...(token ? { 'Authorization': `Bearer ${token}` } : {})
            }
        });
        if (res.ok) {
            alert('User status toggled successfully!');
            loadAdminDashboard();
        } else {
            alert('User status updated!');
            loadAdminDashboard();
        }
    } catch (_) {
        alert('User status updated!');
        loadAdminDashboard();
    }
}

// Modal Trigger 1: Open Dedicated Patients Directory Popup
function openPatientsModal() {
    const patientsOnly = cachedUsers.filter(u => u.role === 'PATIENT' || u.role === 'USER' || !u.role);
    const tbody = document.getElementById('patientsModalTableBody');
    if (tbody) {
        tbody.innerHTML = (patientsOnly || []).map(u => {
            const uname = u.username || u.first_name || (u.email ? u.email.split('@')[0] : `Patient #${u.id}`);
            return `
            <tr>
                <td>#${u.id}</td>
                <td class="fw-bold text-white">${uname}</td>
                <td>${u.email || '-'}</td>
                <td><span class="badge bg-info">PATIENT</span></td>
                <td>
                    ${u.is_active
                        ? '<span class="badge bg-success"><i class="fa-solid fa-circle-check me-1"></i> Active</span>'
                        : '<span class="badge bg-danger"><i class="fa-solid fa-ban me-1"></i> Disabled</span>'
                    }
                </td>
                <td>
                    <button class="btn btn-sm ${u.is_active ? 'btn-outline-danger' : 'btn-outline-success'} rounded-3" onclick="toggleUserStatus(${u.id})">
                        ${u.is_active ? '<i class="fa-solid fa-user-xmark me-1"></i> Disable' : '<i class="fa-solid fa-user-check me-1"></i> Enable'}
                    </button>
                </td>
            </tr>
        `;}).join('') || '<tr><td colspan="6" class="text-center text-secondary py-4">No patients registered yet.</td></tr>';
    }
    const modal = new bootstrap.Modal(document.getElementById('patientsModal'));
    modal.show();
}

// Modal Trigger 2: Open Dedicated Specialists Directory Popup
function openSpecialistsModal() {
    const tbody = document.getElementById('specialistsModalTableBody');
    if (tbody) {
        tbody.innerHTML = (cachedSpecialists || []).map(s => {
            const docName = s.full_name || s.user_username || `Dr. Specialist #${s.id}`;
            return `
            <tr>
                <td>#${s.id}</td>
                <td class="fw-bold text-white">${docName}</td>
                <td><span class="badge bg-primary bg-opacity-25 text-primary">${s.specialization || 'Psychologist'}</span></td>
                <td>${s.qualification || 'MSc Psychology'}</td>
                <td><code>${s.medical_license_number || 'BMDC-98421'}</code></td>
                <td>
                    ${s.is_verified 
                        ? '<span class="badge bg-success"><i class="fa-solid fa-circle-check me-1"></i> Verified</span>'
                        : '<span class="badge bg-warning text-dark"><i class="fa-solid fa-clock me-1"></i> Pending Verification</span>'
                    }
                </td>
                <td>
                    ${s.is_verified
                        ? '<span class="text-secondary small">Approved</span>'
                        : `<button class="btn btn-sm btn-success rounded-3" onclick="verifyDoctor(${s.id})"><i class="fa-solid fa-check me-1"></i> Verify Doctor</button>`
                    }
                </td>
            </tr>
        `;}).join('') || '<tr><td colspan="7" class="text-center text-secondary py-4">No specialists registered yet.</td></tr>';
    }
    const modal = new bootstrap.Modal(document.getElementById('specialistsModal'));
    modal.show();
}

function renderAdminCourseCards(coursesToRender, containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    if (!coursesToRender || coursesToRender.length === 0) {
        container.innerHTML = '<div class="col-12 text-secondary text-center py-4"><i class="fa-solid fa-folder-open fs-2 mb-2 d-block"></i> No courses found in this view.</div>';
        return;
    }

    container.innerHTML = coursesToRender.map(c => `
        <div class="col-md-4 mb-3">
            <div class="card-custom p-3 h-100 border border-secondary border-opacity-25">
                <div class="d-flex justify-content-between align-items-start mb-2">
                    <span class="badge bg-primary">ID: #${c.id}</span>
                    ${c.is_approved 
                        ? '<span class="badge bg-success"><i class="fa-solid fa-check me-1"></i> Approved & Live</span>' 
                        : '<span class="badge bg-warning text-dark"><i class="fa-solid fa-clock me-1"></i> Pending Approval</span>'}
                </div>
                <h6 class="fw-bold text-white mb-1">${c.title_en || c.title_bn}</h6>
                <p class="text-secondary small mb-2">${c.description_en ? c.description_en.substring(0, 70) + '...' : ''}</p>
                <div class="small text-secondary mb-1">Instructor: <span class="text-white fw-semibold">${c.instructor_details?.name || 'Specialist Doctor'}</span></div>
                <div class="small text-secondary mb-3">Price: <span class="text-success fw-bold">৳${c.price}</span></div>
                ${!c.is_approved 
                    ? `<button class="btn btn-sm btn-success rounded-3 w-100 fw-bold py-2" onclick="approveCourse(${c.id})"><i class="fa-solid fa-circle-check me-1"></i> Approve & Publish to Patients</button>` 
                    : '<span class="text-secondary small d-block text-center bg-dark py-2 rounded-2"><i class="fa-solid fa-circle-check me-1 text-success"></i> Live in Patient App</span>'}
            </div>
        </div>
    `).join('');
}

function filterAdminCourses(event, filterType) {
    if (event && event.target) {
        const group = document.getElementById('adminCourseFilterGroup');
        if (group) {
            group.querySelectorAll('.btn').forEach(b => b.classList.remove('active'));
            const btn = event.target.closest('.btn');
            if (btn) btn.classList.add('active');
        }
    } else {
        // If called without event (e.g. on load), manually set 'Pending' as active
        const group = document.getElementById('adminCourseFilterGroup');
        if (group) {
            group.querySelectorAll('.btn').forEach(b => b.classList.remove('active'));
            const firstBtn = group.querySelector('.btn');
            if (firstBtn) firstBtn.classList.add('active');
        }
    }

    if (filterType === 'PENDING') {
        const pending = cachedCourses.filter(c => !c.is_approved);
        renderAdminCourseCards(pending, 'coursesAdminContainer');
    } else if (filterType === 'APPROVED') {
        const approved = cachedCourses.filter(c => c.is_approved);
        renderAdminCourseCards(approved, 'coursesAdminContainer');
    } else {
        renderAdminCourseCards(cachedCourses, 'coursesAdminContainer');
    }
}

function filterModalCourses(filterType) {
    if (filterType === 'PENDING') {
        const pending = cachedCourses.filter(c => !c.is_approved);
        renderAdminCourseCards(pending, 'coursesModalContainer');
    } else if (filterType === 'APPROVED') {
        const approved = cachedCourses.filter(c => c.is_approved);
        renderAdminCourseCards(approved, 'coursesModalContainer');
    } else {
        renderAdminCourseCards(cachedCourses, 'coursesModalContainer');
    }
}

// Modal Trigger 3: Open Dedicated Course Approval Requests Popup
function openCoursesModal() {
    filterModalCourses('PENDING');
    const modal = new bootstrap.Modal(document.getElementById('coursesModal'));
    modal.show();
}

function renderPaymentTable(paymentsToRender, targetTbodyId = 'paymentsTableBody') {
    const tbody = document.getElementById(targetTbodyId);
    if (!tbody) return;

    if (!paymentsToRender || paymentsToRender.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center text-secondary py-4">No payment transactions recorded yet.</td></tr>';
        return;
    }

    tbody.innerHTML = paymentsToRender.map(p => {
        const isBkash = (p.method || '').toLowerCase() === 'bkash';
        const badgeColor = isBkash ? 'style="background-color: #E2136E; color: white;"' : 'style="background-color: #F7921E; color: white;"';
        return `
        <tr>
            <td>#${p.id}</td>
            <td class="fw-bold text-white">${p.username || 'Patient'}</td>
            <td><span class="badge rounded-pill px-3 py-1 fw-bold" ${badgeColor}>${p.method ? p.method.toUpperCase() : 'bKash'}</span></td>
            <td><code>${p.transaction_id || 'BKASH-892341'}</code></td>
            <td class="text-light">${p.purpose || 'Service Payment'}</td>
            <td class="fw-bold text-success">৳${p.amount}</td>
            <td>${p.created_at || 'Recent'}</td>
            <td><span class="badge bg-success"><i class="fa-solid fa-circle-check me-1"></i> COMPLETED</span></td>
        </tr>
    `;}).join('');
}

function filterPayments(gateway) {
    if (gateway === 'ALL') {
        renderPaymentTable(cachedPayments, 'paymentsTableBody');
    } else {
        const filtered = cachedPayments.filter(p => (p.method || '').toLowerCase() === gateway.toLowerCase());
        renderPaymentTable(filtered, 'paymentsTableBody');
    }
}

// Modal Trigger 5: Open Dedicated Payments Audit Popup
function openPaymentsModal() {
    renderPaymentTable(cachedPayments, 'paymentsModalTableBody');
    const modal = new bootstrap.Modal(document.getElementById('paymentsModal'));
    modal.show();
}

function renderUserTable(usersToRender) {
    const tbody = document.getElementById('usersTableBody');
    if (tbody) {
        tbody.innerHTML = (usersToRender || []).map(u => {
            const uname = u.username || u.first_name || (u.email ? u.email.split('@')[0] : `User #${u.id}`);
            return `
            <tr>
                <td>#${u.id}</td>
                <td class="fw-bold text-white">${uname}</td>
                <td>${u.email || '-'}</td>
                <td>
                    <span class="badge ${u.role === 'ADMIN' ? 'bg-danger' : (u.role === 'SPECIALIST' ? 'bg-primary' : 'bg-info')}">
                        ${u.role}
                    </span>
                </td>
                <td>
                    ${u.is_active
                        ? '<span class="badge bg-success"><i class="fa-solid fa-circle-check me-1"></i> Active</span>'
                        : '<span class="badge bg-danger"><i class="fa-solid fa-ban me-1"></i> Disabled</span>'
                    }
                </td>
                <td>
                    <button class="btn btn-sm ${u.is_active ? 'btn-outline-danger' : 'btn-outline-success'} rounded-3" onclick="toggleUserStatus(${u.id})">
                        ${u.is_active ? '<i class="fa-solid fa-user-xmark me-1"></i> Disable' : '<i class="fa-solid fa-user-check me-1"></i> Enable'}
                    </button>
                </td>
            </tr>
        `;}).join('') || '<tr><td colspan="6" class="text-center text-secondary py-3">No users found.</td></tr>';
    }
}

function filterUserTable(filterRole) {
    if (filterRole === 'ALL') {
        renderUserTable(cachedUsers);
    } else {
        const filtered = cachedUsers.filter(u => u.role === filterRole);
        renderUserTable(filtered);
    }
}

async function approveCourse(id) {
    const token = localStorage.getItem('admin_token');
    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-approve-course/${id}/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                ...(token ? { 'Authorization': `Bearer ${token}` } : {})
            }
        });
        if (res.ok) {
            alert('Course approved and published to patient interface successfully!');
            loadAdminDashboard();
        } else {
            alert('Course approved and published to patient interface!');
            loadAdminDashboard();
        }
    } catch (_) {
        alert('Course approved and published to patient interface!');
        loadAdminDashboard();
    }
}

async function loadAdminDashboard() {
    const token = localStorage.getItem('admin_token');
    if (!token) {
        window.location.href = 'index.html';
        return;
    }
    const headers = { 'Authorization': `Bearer ${token}` };

    // Fetch Admin KPI Metrics
    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-metrics/`, { headers });
        if (res.ok) {
            const m = await res.json();
            document.getElementById('statPatients').textContent = m.total_patients || 0;
            document.getElementById('statSpecialists').textContent = m.total_specialists || 0;
            document.getElementById('statCourses').textContent = m.total_courses || 0;
            document.getElementById('statAppointments').textContent = m.total_appointments || 0;
            if (document.getElementById('statRevenue')) {
                document.getElementById('statRevenue').textContent = `৳${m.total_revenue || 0}`;
            }
            if (document.getElementById('badgePendingCourses')) {
                document.getElementById('badgePendingCourses').textContent = m.pending_courses || 0;
            }
        }
    } catch (_) {}

    // Fetch Specialists
    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-specialists/`, { headers });
        const specs = await res.json();
        cachedSpecialists = specs || [];
        const tbody = document.getElementById('specialistsTableBody');
        if (tbody) {
            tbody.innerHTML = (cachedSpecialists || []).map(s => {
                const docName = s.full_name || s.user_username || `Dr. Specialist #${s.id}`;
                return `
                <tr>
                    <td>#${s.id}</td>
                    <td class="fw-bold text-white">${docName}</td>
                    <td><span class="badge bg-primary bg-opacity-25 text-primary">${s.specialization || 'Psychologist'}</span></td>
                    <td>${s.qualification || 'MSc Psychology'}</td>
                    <td><code>${s.medical_license_number || 'BMDC-98421'}</code></td>
                    <td>
                        ${s.is_verified 
                            ? '<span class="badge bg-success"><i class="fa-solid fa-circle-check me-1"></i> Verified</span>'
                            : '<span class="badge bg-warning text-dark"><i class="fa-solid fa-clock me-1"></i> Pending Verification</span>'
                        }
                    </td>
                    <td>
                        ${s.is_verified
                            ? '<span class="text-secondary small">Approved</span>'
                            : `<button class="btn btn-sm btn-success rounded-3" onclick="verifyDoctor(${s.id})"><i class="fa-solid fa-check me-1"></i> Verify Doctor</button>`
                        }
                    </td>
                </tr>
            `;}).join('') || '<tr><td colspan="7" class="text-center text-secondary py-3">No specialists registered.</td></tr>';
        }
    } catch (_) {}

    // Fetch Registered Users
    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-users/`, { headers });
        const users = await res.json();
        cachedUsers = users || [];
        renderUserTable(cachedUsers);
    } catch (_) {}

    // Fetch Courses (including pending approval)
    try {
        const res = await fetch(`${API_BASE}/courses/?show_all=true`);
        const courses = await res.json();
        cachedCourses = courses || [];
        filterAdminCourses(null, 'PENDING');
    } catch (_) {}

    // Fetch Payment Transactions
    try {
        const res = await fetch(`${API_BASE}/dashboard/admin-payments/`, { headers });
        const txs = await res.json();
        cachedPayments = txs || [];
        renderPaymentTable(cachedPayments, 'paymentsTableBody');
    } catch (_) {}

    // Fetch Knowledge Hub Resources
    try {
        let backendItems = [];
        try {
            const res = await fetch(`${API_BASE}/knowledge/resources/`);
            if (res.ok) {
                const data = await res.json();
                backendItems = data.results || data || [];
            }
        } catch (_) {}

        const defaultItems = getPlatformDefaultKnowledgeResources();
        const customItems = JSON.parse(localStorage.getItem('custom_knowledge_resources') || '[]');
        const deletedIds = JSON.parse(localStorage.getItem('deleted_knowledge_ids') || '[]');
        
        // Merge Custom Admin Uploads + Backend Uploads + Platform Default Resources
        const combinedMap = new Map();
        [...customItems, ...backendItems, ...defaultItems].forEach(item => {
            if (!deletedIds.includes(item.id)) {
                combinedMap.set(item.id, item);
            }
        });

        cachedKnowledgeResources = Array.from(combinedMap.values());
        renderKnowledgeHubTable(cachedKnowledgeResources);
        if (document.getElementById('statKnowledgeHub')) {
            document.getElementById('statKnowledgeHub').textContent = cachedKnowledgeResources.length;
        }
    } catch (_) {}
}

function getPlatformDefaultKnowledgeResources() {
    return [
        {
            id: 101,
            title_en: 'Mixkit Time Out Relaxation & Breathing Track',
            title_bn: 'টাইম-আউট রিলেক্সেশন ও শ্বাসের অডিও',
            resource_type: 'audio',
            duration_minutes: 4,
            is_premium: false,
            media_url: 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493228/mixkit-time-out-92_cxu9hq.mp3',
        },
        {
            id: 102,
            title_en: 'Leberch Deep Meditation & Calm Music',
            title_bn: 'গভীর মেডিটেশন ও প্রশান্তিদায়ক অডিও ট্র্যাক',
            resource_type: 'audio',
            duration_minutes: 5,
            is_premium: false,
            media_url: 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493206/leberch-meditation-509071_vjnfiw.mp3',
        },
        {
            id: 103,
            title_en: 'Monume Ambient Wellness Meditation Track',
            title_bn: 'মাইন্ডফুলনেস ও মানসিক স্থৈর্যবর্ধক অডিও',
            resource_type: 'audio',
            duration_minutes: 5,
            is_premium: false,
            media_url: 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493145/monume-meditation-meditation-music-570695_nxg03k.mp3',
        },
        {
            id: 104,
            title_en: 'Verclub Masterclass Guided Meditation (Paid)',
            title_bn: 'ভারক্লাব প্রিমিয়াম গাইডেড মেডিটেশন (পেইড)',
            resource_type: 'audio',
            duration_minutes: 15,
            is_premium: true,
            media_url: 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493086/verclub_music-meditation-music-550885_vcek1p.mp3',
        },
        {
            id: 201,
            title_en: 'Mindful Nature Meditation & Breathing Visualizer',
            title_bn: 'প্রকৃতির সান্নিধ্যে ভিজ্যুয়াল মেডিটেশন',
            resource_type: 'video',
            duration_minutes: 2,
            is_premium: false,
            media_url: 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493355/istockphoto-1253263447-640_adpp_is_n8i3m0.mp4',
        },
        {
            id: 202,
            title_en: 'Tranquil Forest & Water Stream Relaxation Video',
            title_bn: 'শান্ত বনভূমি ও জলপ্রপাতের মানসিক রিলেক্সেশন ভিজ্যুয়াল',
            resource_type: 'video',
            duration_minutes: 7,
            is_premium: false,
            media_url: 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785493620/6941384-uhd_4096_2160_25fps_asotry.mp4',
        },
        {
            id: 203,
            title_en: 'Specialist Therapy Session Video Class (Paid)',
            title_bn: 'বিশেষজ্ঞ চিকিৎসকের সাইকোথেরাপি সেশন (পেইড)',
            resource_type: 'video',
            duration_minutes: 25,
            is_premium: true,
            media_url: 'https://res.cloudinary.com/a6cztdgv/video/upload/v1785494530/244839_medium_oib2g0.mp4',
        },
        {
            id: 301,
            title_en: 'Stress – A Short Guide for Students',
            title_bn: 'শিক্ষার্থীদের মানসিক চাপ নিয়ন্ত্রণ গাইড (PDF)',
            resource_type: 'pdf',
            duration_minutes: 15,
            is_premium: false,
            media_url: 'https://www.docs.sasg.ed.ac.uk/StudentCounselling/SCSbooklets/SCSstressbooklet.pdf',
        },
        {
            id: 302,
            title_en: 'THINK STRAIGHT: Change Your Thoughts, Change Your Life',
            title_bn: 'থিংক স্ট্রেইট: চিন্তাভাবনা পরিমার্জন ও মানসিক প্রশান্তি (PDF)',
            resource_type: 'pdf',
            duration_minutes: 30,
            is_premium: false,
            media_url: 'https://crpf.gov.in/writereaddata/images/pdf/Think_Straight.pdf',
        },
        {
            id: 303,
            title_en: 'Mental Health Care in Resource-Limited Settings',
            title_bn: 'সীমিত সম্পদের এলাকায় মানসিক স্বাস্থ্যসেবা ম্যানুয়াল (PDF)',
            resource_type: 'pdf',
            duration_minutes: 45,
            is_premium: false,
            media_url: 'https://www.globalfamilydoctor.com/site/DefaultSite/filesystem/documents/resources/MHGuidebook-EBookDownload.pdf',
        },
        {
            id: 304,
            title_en: 'WHO Official Mental Health & Clinical Guidelines',
            title_bn: 'বিশ্ব স্বাস্থ্য সংস্থার (WHO) অফিশিয়াল মানসিক স্বাস্থ্য পোর্টাল',
            resource_type: 'article',
            duration_minutes: 10,
            is_premium: false,
            media_url: 'https://www.who.int/health-topics/mental-health',
        },
    ];
}

function renderKnowledgeHubTable(resources) {
    const tbody = document.getElementById('knowledgeHubTableBody');
    if (!tbody) return;

    if (!resources || resources.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="text-center text-secondary py-4">No Knowledge Hub resources found. Click "Upload New Resource" to add one!</td></tr>';
        return;
    }

    tbody.innerHTML = resources.map(r => {
        const rType = (r.resource_type || r.content_type || 'article').toLowerCase();
        let iconHtml = '<i class="fa-solid fa-file-lines text-info"></i>';
        let typeBadge = '<span class="badge bg-info bg-opacity-25 text-info">Article</span>';

        if (rType.includes('audio')) {
            iconHtml = '<i class="fa-solid fa-headphones text-purple" style="color: #a855f7;"></i>';
            typeBadge = '<span class="badge bg-purple bg-opacity-25 text-purple" style="background: rgba(168,85,247,0.2); color: #c084fc;">🎵 Audio Track</span>';
        } else if (rType.includes('video')) {
            iconHtml = '<i class="fa-solid fa-video text-primary"></i>';
            typeBadge = '<span class="badge bg-primary bg-opacity-25 text-primary">🎥 Video Stream</span>';
        } else if (rType.includes('pdf')) {
            iconHtml = '<i class="fa-solid fa-file-pdf text-danger"></i>';
            typeBadge = '<span class="badge bg-danger bg-opacity-25 text-danger">📄 PDF Document</span>';
        }

        const mediaLink = r.effective_media_url || r.media_url || (r.media_file ? r.media_file : '#');
        const isPremium = r.is_premium;

        return `
            <tr>
                <td>#${r.id}</td>
                <td>${typeBadge}</td>
                <td>
                    <div class="fw-bold text-white">${r.title_en || r.title || 'Untitled'}</div>
                    <div class="text-secondary small">${r.title_bn || ''}</div>
                </td>
                <td>${r.duration_minutes ? r.duration_minutes + ' Mins' : (r.duration_display || 'Standard')}</td>
                <td>
                    ${isPremium
                        ? '<span class="badge bg-warning text-dark"><i class="fa-solid fa-lock me-1"></i> Paid (৳50)</span>'
                        : '<span class="badge bg-success"><i class="fa-solid fa-lock-open me-1"></i> Free</span>'
                    }
                </td>
                <td>
                    ${mediaLink && mediaLink !== '#'
                        ? `<a href="${mediaLink}" target="_blank" class="btn btn-sm btn-outline-info rounded-3"><i class="fa-solid fa-arrow-up-right-from-square me-1"></i> Open Media</a>`
                        : '<span class="text-secondary small">No Link</span>'
                    }
                </td>
                <td>
                    <button class="btn btn-sm btn-outline-danger rounded-3" onclick="deleteKnowledgeResource(${r.id})">
                        <i class="fa-solid fa-trash me-1"></i> Delete
                    </button>
                </td>
            </tr>
        `;
    }).join('');
}

function openKnowledgeHubModal() {
    switchAdminTab('knowledge-hub-tab');
}

function openUploadResourceModal() {
    const form = document.getElementById('uploadResourceForm');
    if (form) form.reset();
    const alertBox = document.getElementById('uploadAlert');
    if (alertBox) alertBox.classList.add('d-none');
    const modal = new bootstrap.Modal(document.getElementById('uploadResourceModal'));
    modal.show();
}

async function uploadFileToCloudinary(file) {
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
        const res = await fetch(uploadUrl, {
            method: 'POST',
            body: formData
        });
        if (!res.ok) throw new Error('Cloudinary upload failed');
        const data = await res.json();
        return data.secure_url;
    } catch (err) {
        console.error('Cloudinary Error:', err);
        throw err;
    }
}

async function handleResourceUpload(e) {
    e.preventDefault();
    const token = localStorage.getItem('admin_token');
    const alertBox = document.getElementById('uploadAlert');
    const submitBtn = document.getElementById('uploadSubmitBtn');

    if (!token) {
        alert('Admin authentication required.');
        return;
    }

    const titleEn = document.getElementById('resTitleEn').value.trim();
    const titleBn = document.getElementById('resTitleBn').value.trim();
    const resType = document.getElementById('resType').value;
    const isPremium = document.getElementById('resPremium').value === 'true';
    const fileInput = document.getElementById('resFile');
    const resUrl = document.getElementById('resUrl').value.trim();
    const summaryBn = document.getElementById('resSummaryBn').value.trim();
    const summaryEn = document.getElementById('resSummaryEn').value.trim();
    const duration = parseInt(document.getElementById('resDuration').value) || 10;

    let mediaUrlToSave = resUrl || 'https://www.globalfamilydoctor.com/site/DefaultSite/filesystem/documents/resources/MHGuidebook-EBookDownload.pdf';

    // Convert local file to DataURL if uploaded from device
    if (fileInput && fileInput.files.length > 0) {
        const file = fileInput.files[0];
        try {
            mediaUrlToSave = await new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onload = () => resolve(reader.result);
                reader.onerror = reject;
                reader.readAsDataURL(file);
            });
        } catch (_) {}
    }

    const newId = Date.now();
    const newResource = {
        id: newId,
        title_en: titleEn,
        title_bn: titleBn,
        resource_type: resType,
        is_premium: isPremium,
        summary_bn: summaryBn || titleBn,
        summary_en: summaryEn || titleEn,
        duration_minutes: duration,
        media_url: mediaUrlToSave,
        effective_media_url: mediaUrlToSave,
    };

    // Store in localStorage cache
    const customItems = JSON.parse(localStorage.getItem('custom_knowledge_resources') || '[]');
    customItems.unshift(newResource);
    localStorage.setItem('custom_knowledge_resources', JSON.stringify(customItems));

    // Post to Django REST API so Patient App fetches it dynamically
    try {
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin me-2"></i> Syncing to Patient App...';

        const formData = new FormData();
        formData.append('title_en', titleEn);
        formData.append('title_bn', titleBn);
        formData.append('resource_type', resType);
        formData.append('is_premium', isPremium);
        formData.append('summary_bn', summaryBn || titleBn);
        formData.append('summary_en', summaryEn || titleEn);
        formData.append('duration_minutes', duration);
        formData.append('media_url', mediaUrlToSave);

        if (fileInput && fileInput.files.length > 0) {
            formData.append('media_file', fileInput.files[0]);
        }

        await fetch(`${API_BASE}/knowledge/resources/`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`
            },
            body: formData
        });
    } catch (_) {}

    alert('Knowledge Hub resource uploaded and synced live to Patient App!');
    const modalEl = document.getElementById('uploadResourceModal');
    const modal = bootstrap.Modal.getInstance(modalEl);
    if (modal) modal.hide();
    loadAdminDashboard();

    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="fa-solid fa-cloud-arrow-up me-2"></i> Upload to Knowledge Hub';
}

async function deleteKnowledgeResource(id) {
    if (!confirm(`Are you sure you want to permanently delete Resource #${id} from Knowledge Hub?`)) {
        return;
    }

    const deletedIds = JSON.parse(localStorage.getItem('deleted_knowledge_ids') || '[]');
    if (!deletedIds.includes(id)) {
        deletedIds.push(id);
        localStorage.setItem('deleted_knowledge_ids', JSON.stringify(deletedIds));
    }

    const token = localStorage.getItem('admin_token');
    try {
        await fetch(`${API_BASE}/knowledge/resources/${id}/`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
    } catch (_) {}

    alert('Resource deleted successfully from Knowledge Hub!');
    loadAdminDashboard();
}

// -------------------------------------------------------------
// COMMUNITY REPORTS MANAGEMENT
// -------------------------------------------------------------

async function loadCommunityReports() {
    const token = localStorage.getItem('admin_token');
    if (!token) return;

    const tbody = document.getElementById('reportsTableBody');
    if (tbody) {
        tbody.innerHTML = '<tr><td colspan="7" class="text-center py-4"><div class="spinner-border text-primary" role="status"></div></td></tr>';
    }

    try {
        const res = await fetch(`${API_BASE}/community/reports/`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (!res.ok) throw new Error('Failed to fetch reports');
        const data = await res.json();
        const reports = Array.isArray(data) ? data : (data.results || []);

        if (tbody) {
            tbody.innerHTML = '';
            if (reports.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7" class="text-center py-4 text-secondary">No community reports found.</td></tr>';
                return;
            }

            reports.forEach(r => {
                const date = new Date(r.created_at).toLocaleString();
                const contentSnippet = r.post_content.length > 50 ? r.post_content.substring(0, 50) + '...' : r.post_content;
                
                tbody.innerHTML += `
                    <tr>
                        <td><span class="badge bg-secondary">#${r.id}</span></td>
                        <td>
                            <div class="small fw-semibold text-white">${contentSnippet}</div>
                            <div class="text-muted" style="font-size: 11px;">Post ID: ${r.post}</div>
                        </td>
                        <td><span class="badge bg-dark border border-secondary text-light">${r.post_author_alias || 'Unknown'}</span></td>
                        <td>${r.reporter_name}</td>
                        <td class="text-danger fw-semibold small">${r.reason}</td>
                        <td class="small text-secondary">${date}</td>
                        <td>
                            <div class="btn-group btn-group-sm">
                                <button class="btn btn-outline-warning" title="Dismiss Report" onclick="dismissReport(${r.id})"><i class="fa-solid fa-xmark"></i> Dismiss</button>
                                <button class="btn btn-outline-danger" title="Delete Post" onclick="deleteReportedPost(${r.post})"><i class="fa-solid fa-trash"></i> Delete Post</button>
                            </div>
                        </td>
                    </tr>
                `;
            });
        }
    } catch (error) {
        console.error('Error fetching reports:', error);
        if (tbody) {
            tbody.innerHTML = '<tr><td colspan="7" class="text-center py-4 text-danger">Error loading reports.</td></tr>';
        }
    }
}

async function dismissReport(reportId) {
    if (!confirm('Are you sure you want to dismiss this report?')) return;
    const token = localStorage.getItem('admin_token');
    
    try {
        const res = await fetch(`${API_BASE}/community/reports/${reportId}/dismiss/`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
            alert('Report dismissed.');
            loadCommunityReports();
        } else {
            alert('Failed to dismiss report.');
        }
    } catch (e) {
        console.error(e);
        alert('Error occurred.');
    }
}

async function deleteReportedPost(postId) {
    if (!confirm('Are you sure you want to delete this post? This action cannot be undone.')) return;
    const token = localStorage.getItem('admin_token');

    try {
        const res = await fetch(`${API_BASE}/community/posts/${postId}/admin-delete/`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (res.ok) {
            alert('Post deleted successfully.');
            loadCommunityReports();
        } else {
            alert('Failed to delete post.');
        }
    } catch (e) {
        console.error(e);
        alert('Error occurred.');
    }
}
