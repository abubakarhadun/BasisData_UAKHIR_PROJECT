// ============================================================
// js/api.js
// Centralized API client — all fetch calls go through here
// ============================================================

const API_BASE = 'http://localhost:5000/api';

// ---- Token helpers ----
const getToken  = ()        => localStorage.getItem('sv_token');
const setToken  = (token)   => localStorage.setItem('sv_token', token);
const setUser   = (user)    => localStorage.setItem('sv_user', JSON.stringify(user));
const getUser   = ()        => { try { return JSON.parse(localStorage.getItem('sv_user')); } catch { return null; } };
const clearAuth = ()        => { localStorage.removeItem('sv_token'); localStorage.removeItem('sv_user'); };
const isLoggedIn = ()       => !!getToken();
const isAdmin    = ()       => { const u = getUser(); return u && u.role === 'admin'; };

/**
 * Core fetch wrapper.
 * Automatically attaches Authorization header and handles JSON.
 */
async function apiFetch(endpoint, options = {}) {
    const token = getToken();
    const headers = { 'Content-Type': 'application/json', ...options.headers };

    if (token) headers['Authorization'] = `Bearer ${token}`;

    // Don't set Content-Type for FormData (let browser set boundary)
    if (options.body instanceof FormData) delete headers['Content-Type'];

    const response = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
    const data = await response.json().catch(() => ({ success: false, message: 'Server error' }));

    if (response.status === 401) {
        clearAuth();
        if (!window.location.href.includes('login')) {
            window.location.href = '/frontend/pages/login.html';
        }
    }

    return { ok: response.ok, status: response.status, data };
}

// ============================================================
// AUTH
// ============================================================
const Auth = {
    async register(username, email, password, fullname) {
        return apiFetch('/auth/register', {
            method: 'POST',
            body: JSON.stringify({ username, email, password, fullname }),
        });
    },
    async login(login, password) {
        return apiFetch('/auth/login', {
            method: 'POST',
            body: JSON.stringify({ login, password }),
        });
    },
    async me() { return apiFetch('/auth/me'); },
    logout() {
        clearAuth();
        window.location.href = '/frontend/pages/login.html';
    },
};

// ============================================================
// POSTS
// ============================================================
const Posts = {
    async getTimeline(page = 1, limit = 10) {
        return apiFetch(`/posts?page=${page}&limit=${limit}`);
    },
    async getPost(id) { return apiFetch(`/posts/${id}`); },
    async create(formData) {
        return apiFetch('/posts', { method: 'POST', body: formData });
    },
    async update(id, content) {
        return apiFetch(`/posts/${id}`, { method: 'PUT', body: JSON.stringify({ content }) });
    },
    async delete(id) { return apiFetch(`/posts/${id}`, { method: 'DELETE' }); },
    async toggleLike(id) { return apiFetch(`/posts/${id}/like`, { method: 'POST' }); },
    async addComment(id, comment_text) {
        return apiFetch(`/posts/${id}/comment`, {
            method: 'POST',
            body: JSON.stringify({ comment_text }),
        });
    },
    async deleteComment(postId, commentId) {
        return apiFetch(`/posts/${postId}/comments/${commentId}`, { method: 'DELETE' });
    },
};

// ============================================================
// USERS
// ============================================================
const Users = {
    async getProfile(username) { return apiFetch(`/users/${username}`); },
    async updateProfile(formData) {
        return apiFetch('/users/profile/edit', { method: 'PUT', body: formData });
    },
    async changePassword(current_password, new_password) {
        return apiFetch('/users/profile/password', {
            method: 'PUT',
            body: JSON.stringify({ current_password, new_password }),
        });
    },
    async follow(userId) { return apiFetch(`/users/${userId}/follow`, { method: 'POST' }); },
    async getFollowers(userId) { return apiFetch(`/users/${userId}/followers`); },
    async getFollowing(userId) { return apiFetch(`/users/${userId}/following`); },
    async search(query) { return apiFetch(`/users/search?q=${encodeURIComponent(query)}`); },
};

// ============================================================
// NOTIFICATIONS
// ============================================================
const Notifications = {
    async getAll() { return apiFetch('/notifications'); },
    async markAllRead() { return apiFetch('/notifications/read-all', { method: 'PUT' }); },
    async markRead(id) { return apiFetch(`/notifications/${id}/read`, { method: 'PUT' }); },
};

// ============================================================
// REPORTS
// ============================================================
const Reports = {
    async submit(post_id, reason) {
        return apiFetch('/reports', { method: 'POST', body: JSON.stringify({ post_id, reason }) });
    },
};

// ============================================================
// ADMIN
// ============================================================
const Admin = {
    async getStats()           { return apiFetch('/admin/stats'); },
    async getUsers(page = 1, search = '') {
        return apiFetch(`/admin/users?page=${page}&search=${encodeURIComponent(search)}`);
    },
    async banUser(userId, ban) {
        return apiFetch(`/admin/users/${userId}/ban`, { method: 'POST', body: JSON.stringify({ ban }) });
    },
    async getPosts(page = 1)   { return apiFetch(`/admin/posts?page=${page}`); },
    async getReports(status = 'pending') { return apiFetch(`/admin/reports?status=${status}`); },
    async updateReport(id, status) {
        return apiFetch(`/admin/reports/${id}`, { method: 'PUT', body: JSON.stringify({ status }) });
    },
};

// ============================================================
// UI UTILITIES
// ============================================================

/** Show a toast notification */
function showToast(message, type = 'info', duration = 3500) {
    let container = document.getElementById('toast-container');
    if (!container) {
        container = document.createElement('div');
        container.id = 'toast-container';
        container.className = 'toast-container';
        document.body.appendChild(container);
    }

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    container.appendChild(toast);

    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(40px)';
        toast.style.transition = '0.3s ease';
        setTimeout(() => toast.remove(), 300);
    }, duration);
}

/** Format a timestamp to relative time (e.g. "2 jam lalu") */
function timeAgo(dateStr) {
    const date = new Date(dateStr);
    const now  = new Date();
    const diff = Math.floor((now - date) / 1000);

    if (diff < 60)    return 'baru saja';
    if (diff < 3600)  return `${Math.floor(diff / 60)} menit lalu`;
    if (diff < 86400) return `${Math.floor(diff / 3600)} jam lalu`;
    if (diff < 604800) return `${Math.floor(diff / 86400)} hari lalu`;
    return date.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' });
}

/** Escape HTML to prevent XSS */
function escHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

/** Redirect to login if not authenticated */
function requireAuth() {
    if (!isLoggedIn()) {
        window.location.href = '/frontend/pages/login.html';
        return false;
    }
    return true;
}

/** Redirect to home if already logged in */
function redirectIfLoggedIn() {
    if (isLoggedIn()) {
        window.location.href = '/frontend/pages/timeline.html';
    }
}

/** Get avatar URL, fallback to placeholder */
function avatarUrl(path) {
    if (!path) return `https://ui-avatars.com/api/?background=7c4dff&color=fff&name=U`;
    if (path.startsWith('http')) return path;
    return `http://localhost:5000/${path}`;
}

/** Build sidebar HTML and inject into page */
function buildSidebar(activePage = '') {
    const user = getUser();
    if (!user) return;

    const navItems = [
        { href: 'timeline.html',      icon: '🏠', label: 'Beranda',      id: 'timeline' },
        { href: 'profile.html',       icon: '👤', label: 'Profil',       id: 'profile' },
        { href: 'notifications.html', icon: '🔔', label: 'Notifikasi',   id: 'notifications', badge: true },
        { href: 'search.html',        icon: '🔍', label: 'Cari',         id: 'search' },
    ];

    if (user.role === 'admin') {
        navItems.push({ href: 'admin.html', icon: '⚙️', label: 'Admin', id: 'admin' });
    }

    const navHtml = navItems.map(item => `
        <a href="${item.href}" class="nav-item ${activePage === item.id ? 'active' : ''}" id="nav-${item.id}">
            <span class="nav-icon">${item.icon}</span>
            <span>${item.label}</span>
            ${item.badge ? `<span class="nav-badge" id="notif-badge" style="display:none">0</span>` : ''}
        </a>
    `).join('');

    const sidebarHtml = `
        <div class="sidebar-logo">
            <div class="logo-icon">✦</div>
            <span>Sociaverse</span>
        </div>
        <nav class="sidebar-nav">${navHtml}</nav>
        <div class="sidebar-user" onclick="window.location.href='profile.html'">
            <img src="${avatarUrl(user.profile_picture)}" class="avatar avatar-sm" alt="avatar">
            <div class="user-info">
                <div class="name">${escHtml(user.fullname)}</div>
                <div class="handle">@${escHtml(user.username)}</div>
            </div>
        </div>
    `;

    const sidebar = document.getElementById('sidebar');
    if (sidebar) sidebar.innerHTML = sidebarHtml;

    // Load unread notification count
    loadUnreadCount();
}

async function loadUnreadCount() {
    try {
        const { data } = await Notifications.getAll();
        if (data.success) {
            const unread = data.data.filter(n => !n.IS_READ).length;
            const badge  = document.getElementById('notif-badge');
            if (badge) {
                badge.textContent = unread > 0 ? (unread > 9 ? '9+' : unread) : '';
                badge.style.display = unread > 0 ? 'flex' : 'none';
            }
        }
    } catch { /* silent */ }
}
