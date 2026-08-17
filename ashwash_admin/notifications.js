// Ashwash Executive Admin Notification System
const NOTIF_API_BASE = 'https://ashwash-backend.onrender.com';

function getAdminToken() {
    return localStorage.getItem('admin_token') || localStorage.getItem('adminToken');
}

// Real Firebase project config
const firebaseConfig = {
    apiKey: "AIzaSyCKNb5xzn07zwOnz8i0M3llDEOOrOqJZm4",
    authDomain: "ashwash-b0441.firebaseapp.com",
    projectId: "ashwash-b0441",
    storageBucket: "ashwash-b0441.firebasestorage.app",
    messagingSenderId: "498385268612",
    appId: "1:498385268612:web:ecf2c65fb168fbd0a5f7d1"
};

try {
    if (typeof firebase !== 'undefined' && !firebase.apps.length) {
        firebase.initializeApp(firebaseConfig);
    }
    const messaging = (typeof firebase !== 'undefined' && firebase.messaging) ? firebase.messaging() : null;

    // Request Permission
    function requestNotificationPermission() {
        if (!('Notification' in window) || !messaging) return;
        Notification.requestPermission().then((permission) => {
            if (permission === 'granted') {
                messaging.getToken().then((currentToken) => {
                    if (currentToken) {
                        sendTokenToServer(currentToken);
                    }
                }).catch((err) => {
                    console.log('Firebase token error:', err);
                });
            }
        });
    }

    // Send Token to Django Backend
    function sendTokenToServer(token) {
        const adminToken = getAdminToken();
        if (!adminToken) return;

        fetch(`${NOTIF_API_BASE}/api/notifications/register-device/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${adminToken}`
            },
            body: JSON.stringify({ fcm_token: token, device_type: 'web' })
        })
        .then(res => res.json())
        .catch(err => console.log('Device register note:', err));
    }

    // Listen for foreground messages
    if (messaging) {
        messaging.onMessage((payload) => {
            const title = payload.notification?.title || payload.data?.title || 'New Notification';
            const body = payload.notification?.body || payload.data?.body || '';
            showNotificationToast(title, body);
            fetchUnreadCount();
            const panel = document.getElementById('notificationsOffcanvas');
            if (panel && panel.classList.contains('show')) {
                loadNotifications();
            }
        });
    }
} catch (e) {
    console.warn("Firebase Push disabled or running in fallback mode:", e);
}

function showNotificationToast(title, body) {
    const toastContainer = document.getElementById('toastContainer');
    if (!toastContainer) return;
    const toastId = 'toast_' + Date.now();
    const toastHTML = `
        <div class="toast align-items-center text-white bg-dark border border-primary border-opacity-50 shadow-lg" role="alert" aria-live="assertive" aria-atomic="true" id="${toastId}" data-bs-autohide="true" data-bs-delay="6000">
          <div class="d-flex">
            <div class="toast-body d-flex align-items-start gap-2">
              <span class="text-primary fs-5"><i class="fa-solid fa-bell"></i></span>
              <div>
                <strong class="text-white">${title}</strong>
                <div class="text-secondary small mt-1">${body}</div>
              </div>
            </div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
          </div>
        </div>
    `;
    toastContainer.insertAdjacentHTML('beforeend', toastHTML);
    const toastEl = document.getElementById(toastId);
    if (toastEl && typeof bootstrap !== 'undefined') {
        const toast = new bootstrap.Toast(toastEl);
        toast.show();
    }
}

// Fetch Unread Count
function fetchUnreadCount() {
    const token = getAdminToken();
    if (!token) return;

    fetch(`${NOTIF_API_BASE}/api/notifications/count/`, {
        headers: { 'Authorization': `Bearer ${token}` }
    })
    .then(res => res.json())
    .then(data => {
        const badge = document.getElementById('notificationBadge');
        if (badge) {
            const count = data.unread_count || 0;
            if (count > 0) {
                badge.textContent = count > 99 ? '99+' : count;
                badge.classList.remove('d-none');
            } else {
                badge.classList.add('d-none');
            }
        }
    })
    .catch(() => {});
}

// Open Notifications Drawer
function openNotificationsPanel() {
    const offcanvasEl = document.getElementById('notificationsOffcanvas');
    if (offcanvasEl && typeof bootstrap !== 'undefined') {
        const bsOffcanvas = bootstrap.Offcanvas.getOrCreateInstance(offcanvasEl);
        bsOffcanvas.show();
        loadNotifications();
    }
}

function getNotificationTypeMeta(type) {
    switch (type) {
        case 'APPOINTMENT':
            return { icon: 'fa-calendar-check', color: '#3B82F6', bg: 'rgba(59, 130, 246, 0.15)', badgeClass: 'bg-primary' };
        case 'COURSE':
            return { icon: 'fa-graduation-cap', color: '#F59E0B', bg: 'rgba(245, 158, 11, 0.15)', badgeClass: 'bg-warning text-dark' };
        case 'COMMUNITY':
            return { icon: 'fa-comments', color: '#8B5CF6', bg: 'rgba(139, 92, 246, 0.15)', badgeClass: 'bg-info' };
        case 'PROFILE':
            return { icon: 'fa-user-check', color: '#10B981', bg: 'rgba(16, 185, 129, 0.15)', badgeClass: 'bg-success' };
        case 'SYSTEM':
            return { icon: 'fa-shield-halved', color: '#EF4444', bg: 'rgba(239, 68, 68, 0.15)', badgeClass: 'bg-danger' };
        default:
            return { icon: 'fa-bell', color: '#06B6D4', bg: 'rgba(6, 182, 212, 0.15)', badgeClass: 'bg-primary' };
    }
}

function groupNotificationsByDate(items) {
    const now = new Date();
    const todayStr = now.toDateString();
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toDateString();

    const groups = { today: [], yesterday: [], older: [] };
    items.forEach(item => {
        const itemDate = new Date(item.created_at).toDateString();
        if (itemDate === todayStr) {
            groups.today.push(item);
        } else if (itemDate === yesterdayStr) {
            groups.yesterday.push(item);
        } else {
            groups.older.push(item);
        }
    });
    return groups;
}

function handleAdminNotificationClick(id, notifType, relType, relId) {
    // 1. Mark as read
    markNotificationRead(id);

    // 2. Close Offcanvas drawer
    const offcanvasEl = document.getElementById('notificationsOffcanvas');
    if (offcanvasEl && typeof bootstrap !== 'undefined') {
        const bsOffcanvas = bootstrap.Offcanvas.getInstance(offcanvasEl);
        if (bsOffcanvas) bsOffcanvas.hide();
    }

    // 3. Navigate to relevant tab or open modal
    const upperType = (notifType || '').toUpperCase();
    const upperRel = (relType || '').toUpperCase();

    if (upperType === 'COURSE' || upperRel === 'COURSE' || upperRel === 'LESSON') {
        const tabBtn = document.querySelector('[data-bs-target="#courses-admin-tab"]');
        if (tabBtn) {
            const tab = bootstrap.Tab.getOrCreateInstance(tabBtn);
            tab.show();
            tabBtn.scrollIntoView({ behavior: 'smooth', block: 'start' });
        } else if (typeof openCoursesModal === 'function') {
            openCoursesModal();
        }
    } else if (upperType === 'APPOINTMENT' || upperRel === 'APPOINTMENT') {
        if (typeof openAppointmentsModal === 'function') {
            openAppointmentsModal();
        }
    } else if (upperType === 'PROFILE' || upperRel === 'SPECIALIST' || upperRel === 'SPECIALISTPROFILE') {
        const tabBtn = document.querySelector('[data-bs-target="#specialists-tab"]');
        if (tabBtn) {
            const tab = bootstrap.Tab.getOrCreateInstance(tabBtn);
            tab.show();
            tabBtn.scrollIntoView({ behavior: 'smooth', block: 'start' });
        } else if (typeof openSpecialistsModal === 'function') {
            openSpecialistsModal();
        }
    } else if (upperType === 'USER' || upperType === 'SYSTEM' || upperType === 'COMMUNITY') {
        const tabBtn = document.querySelector('[data-bs-target="#users-tab"]');
        if (tabBtn) {
            const tab = bootstrap.Tab.getOrCreateInstance(tabBtn);
            tab.show();
            tabBtn.scrollIntoView({ behavior: 'smooth', block: 'start' });
        } else if (typeof openPatientsModal === 'function') {
            openPatientsModal();
        }
    }
}

function renderNotificationCard(n) {
    const meta = getNotificationTypeMeta(n.notification_type);
    const timeStr = new Date(n.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const isUnread = !n.is_read;

    return `
        <div class="card bg-dark border ${isUnread ? 'border-primary' : 'border-secondary'} border-opacity-25 mb-2 rounded-3 shadow-sm transition-all" id="notif-card-${n.id}" style="cursor: pointer;" onclick="handleAdminNotificationClick(${n.id}, '${n.notification_type || ''}', '${n.related_object_type || ''}', '${n.related_object_id || ''}')">
            <div class="card-body p-3">
                <div class="d-flex align-items-start gap-3">
                    <div class="rounded-circle d-flex align-items-center justify-content-center flex-shrink-0" style="width: 38px; height: 38px; background: ${meta.bg}; color: ${meta.color}; font-size: 16px;">
                        <i class="fa-solid ${meta.icon}"></i>
                    </div>
                    <div class="flex-grow-1">
                        <div class="d-flex align-items-center justify-content-between">
                            <span class="badge ${meta.badgeClass} rounded-pill px-2 py-1 small" style="font-size: 10px;">${n.notification_type || 'SYSTEM'}</span>
                            <span class="text-secondary small" style="font-size: 11px;">${timeStr}</span>
                        </div>
                        <h6 class="text-white fw-bold mb-1 mt-2" style="font-size: 14px;">${n.title}</h6>
                        <p class="text-secondary mb-2" style="font-size: 12px; line-height: 1.4;">${n.body}</p>
                        <div class="d-flex align-items-center justify-content-between pt-1 border-top border-secondary border-opacity-25" onclick="event.stopPropagation();">
                            ${isUnread ? `
                                <button class="btn btn-link btn-sm text-primary p-0 text-decoration-none small" style="font-size: 11px;" onclick="markNotificationRead(${n.id}, event)">
                                    <i class="fa-solid fa-check me-1"></i>Mark Read
                                </button>
                            ` : `<span class="text-muted small" style="font-size: 11px;"><i class="fa-solid fa-check-double me-1"></i>Read</span>`}
                            <button class="btn btn-link btn-sm text-danger p-0 text-decoration-none small" style="font-size: 11px;" onclick="deleteNotificationItem(${n.id}, event)">
                                <i class="fa-solid fa-trash-can"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;
}

function loadNotifications() {
    const token = getAdminToken();
    if (!token) return;

    const listEl = document.getElementById('notificationsList');
    if (!listEl) return;

    listEl.innerHTML = `
        <div class="text-center py-5">
            <div class="spinner-border spinner-border-sm text-primary" role="status"></div>
            <p class="text-secondary small mt-2">Loading notifications...</p>
        </div>
    `;

    fetch(`${NOTIF_API_BASE}/api/notifications/`, {
        headers: { 'Authorization': `Bearer ${token}` }
    })
    .then(res => res.json())
    .then(data => {
        const items = Array.isArray(data) ? data : (data.results || []);
        if (!items.length) {
            listEl.innerHTML = `
                <div class="text-center py-5">
                    <div class="text-secondary mb-2" style="font-size: 32px;"><i class="fa-regular fa-bell-slash"></i></div>
                    <p class="text-secondary small">No notifications found.</p>
                </div>
            `;
            return;
        }

        const groups = groupNotificationsByDate(items);
        let html = '';

        if (groups.today.length) {
            html += `<div class="text-secondary text-uppercase fw-bold mb-2 small" style="font-size: 11px; letter-spacing: 0.5px;"><i class="fa-regular fa-calendar-day me-1 text-primary"></i> Today</div>`;
            html += groups.today.map(renderNotificationCard).join('');
        }
        if (groups.yesterday.length) {
            html += `<div class="text-secondary text-uppercase fw-bold mb-2 mt-3 small" style="font-size: 11px; letter-spacing: 0.5px;"><i class="fa-regular fa-clock me-1 text-warning"></i> Yesterday</div>`;
            html += groups.yesterday.map(renderNotificationCard).join('');
        }
        if (groups.older.length) {
            html += `<div class="text-secondary text-uppercase fw-bold mb-2 mt-3 small" style="font-size: 11px; letter-spacing: 0.5px;"><i class="fa-regular fa-calendar-days me-1 text-secondary"></i> Older</div>`;
            html += groups.older.map(renderNotificationCard).join('');
        }

        listEl.innerHTML = html;
        fetchUnreadCount();
    })
    .catch(err => {
        listEl.innerHTML = `
            <div class="text-center py-4 text-danger small">
                <i class="fa-solid fa-triangle-exclamation mb-1 fs-5"></i><br>
                Failed to load notifications.
            </div>
        `;
    });
}

function markNotificationRead(id, event) {
    if (event) event.stopPropagation();
    const token = getAdminToken();
    if (!token) return;

    fetch(`${NOTIF_API_BASE}/api/notifications/${id}/read/`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
    })
    .then(() => {
        const card = document.getElementById(`notif-card-${id}`);
        if (card) {
            card.classList.remove('border-primary');
            card.classList.add('border-secondary');
        }
        loadNotifications();
        fetchUnreadCount();
    })
    .catch(() => {});
}

function markAllNotificationsRead() {
    const token = getAdminToken();
    if (!token) return;

    fetch(`${NOTIF_API_BASE}/api/notifications/read-all/`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
    })
    .then(() => {
        loadNotifications();
        fetchUnreadCount();
    })
    .catch(() => {});
}

function deleteNotificationItem(id, event) {
    if (event) event.stopPropagation();
    const token = getAdminToken();
    if (!token) return;

    fetch(`${NOTIF_API_BASE}/api/notifications/${id}/delete/`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
    })

    .then(() => {
        const card = document.getElementById(`notif-card-${id}`);
        if (card) card.remove();
        fetchUnreadCount();
    })
    .catch(() => {});
}

function clearAllNotifications() {
    const token = getAdminToken();
    if (!token) return;
    if (!confirm('Are you sure you want to delete all notifications?')) return;

    fetch(`${NOTIF_API_BASE}/api/notifications/delete-all/`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
    })
    .then(() => {
        loadNotifications();
        fetchUnreadCount();
    })
    .catch(() => {});
}

// Initial Boot & Polling
document.addEventListener('DOMContentLoaded', () => {
    if (getAdminToken()) {
        try { requestNotificationPermission(); } catch (_) {}
        fetchUnreadCount();
        // Polling fallback every 20 seconds for instant real-time sync
        setInterval(fetchUnreadCount, 20000);
    }
});

