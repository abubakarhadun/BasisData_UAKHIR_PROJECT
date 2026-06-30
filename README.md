# ✦ Sociaverse — Simple Social Media Platform

> **Tugas Besar Mata Kuliah Basis Data**
> Implementasi Oracle Database dengan PL/SQL, Trigger, Procedure, Function, Package, View, dan TCL

---

## 📋 Daftar Isi

- [Gambaran Umum](#-gambaran-umum)
- [Tech Stack](#-tech-stack)
- [ERD & Database Design](#-erd--database-design)
- [Normalisasi](#-normalisasi)
- [Struktur Folder](#-struktur-folder)
- [Instalasi & Konfigurasi](#-instalasi--konfigurasi)
- [Menjalankan Aplikasi](#-menjalankan-aplikasi)
- [API Documentation](#-api-documentation)
- [Fitur Oracle Database](#-fitur-oracle-database)
- [Skenario Demo Presentasi](#-skenario-demo-presentasi)

---

## 🌐 Gambaran Umum

**Sociaverse** adalah aplikasi media sosial berbasis web sederhana yang dirancang dengan fokus utama pada implementasi **Oracle Database**. Semua logika bisnis inti diimplementasikan di sisi database melalui PL/SQL, bukan di layer aplikasi.

### Fitur Utama
| Fitur | Deskripsi |
|-------|-----------|
| 🔐 Autentikasi | Register, Login, Logout dengan JWT |
| 📝 Postingan | Buat, Edit, Hapus, Like, Komentar |
| 👥 Sosial | Follow/Unfollow pengguna |
| 🔔 Notifikasi | Auto-notifikasi via Oracle Trigger |
| ⚠️ Pelaporan | Report postingan, review oleh admin |
| ⚙️ Admin | Dashboard manajemen pengguna & konten |

---

## 🛠 Tech Stack

```
Frontend   : HTML5, CSS3, Vanilla JavaScript
Backend    : Node.js, Express.js, JWT, Multer, MVC Architecture
Database   : Oracle Database (PL/SQL, Trigger, Procedure, Function, Package, View, TCL)
```

---

## 🗃 ERD & Database Design

### Relasi Antar Tabel

```
USERS ──┬──< POSTS ──┬──< COMMENTS
        │             ├──< LIKES
        │             └──< POST_REPORTS
        ├──< FOLLOWS (self-referential)
        └──< NOTIFICATIONS
```

### Diagram Relasi

```
┌─────────────┐       ┌──────────────┐
│   USERS     │──1──n─│    POSTS     │
│─────────────│       │──────────────│
│ user_id  PK │       │ post_id   PK │
│ username    │       │ user_id   FK │
│ email       │       │ content      │
│ password    │       │ image_url    │
│ fullname    │       │ created_at   │
│ bio         │       │ updated_at   │
│ profile_pic │       │ is_edited    │
│ role        │       └──────┬───────┘
│ is_active   │              │
│ created_at  │    ┌─────────┴────────┐
│ last_login  │    │                  │
└──────┬──────┘    ▼                  ▼
       │     ┌──────────┐    ┌──────────────┐
       │     │ COMMENTS │    │    LIKES     │
       │     │──────────│    │──────────────│
       │     │comment_id│    │ like_id   PK │
       │     │post_id FK│    │ post_id   FK │
       │     │user_id FK│    │ user_id   FK │
       │     │text      │    │ created_at   │
       │     │created_at│    │ UNIQUE(user, │
       │     └──────────┘    │  post)       │
       │                     └──────────────┘
       │
       ├──────────────────────────────────────┐
       │                                      │
       ▼                                      ▼
┌─────────────────┐              ┌─────────────────┐
│    FOLLOWS      │              │  NOTIFICATIONS  │
│─────────────────│              │─────────────────│
│ follow_id    PK │              │notification_id  │
│ follower_id  FK │              │ sender_id    FK │
│ following_id FK │              │ receiver_id  FK │
│ created_at      │              │ type (like/     │
│ UNIQUE(follower,│              │  comment/follow)│
│  following)     │              │ reference_id    │
│ CHECK(follower  │              │ message         │
│  <> following)  │              │ is_read         │
└─────────────────┘              └─────────────────┘

┌──────────────────┐
│  POST_REPORTS    │
│──────────────────│
│ report_id     PK │
│ post_id       FK │
│ reporter_id   FK │
│ reason           │
│ status (pending/ │
│  reviewed/       │
│  resolved/       │
│  dismissed)      │
└──────────────────┘
```

---

## 📊 Normalisasi

### 1NF (First Normal Form)
- ✅ Setiap kolom berisi nilai atomik (tidak ada multiple values dalam satu kolom)
- ✅ Setiap baris memiliki primary key yang unik
- ✅ Tidak ada repeating groups
- Contoh: `users.bio` menyimpan satu nilai teks, bukan list

### 2NF (Second Normal Form)
- ✅ Sudah memenuhi 1NF
- ✅ Setiap atribut non-key bergantung penuh pada primary key (tidak ada partial dependency)
- Contoh: `comments.comment_text` bergantung penuh pada `comment_id`, bukan hanya pada `post_id` atau `user_id`

### 3NF (Third Normal Form)
- ✅ Sudah memenuhi 2NF
- ✅ Tidak ada transitive dependency (atribut non-key bergantung pada atribut non-key lain)
- Contoh: `posts` tidak menyimpan `username` (yang bergantung pada `user_id`). Username diambil via JOIN ke tabel `users`
- Contoh: `likes` tidak menyimpan `like_count` — dihitung via COUNT() atau fungsi `get_post_engagement()`

---

## 📁 Struktur Folder

```
sociaverse/
│
├── database/                   # Semua file SQL Oracle
│   ├── ddl.sql                 # CREATE TABLE, PK, FK, Constraints
│   ├── sequences.sql           # Sequences untuk auto-increment
│   ├── triggers.sql            # Triggers (auto-ID + notifikasi otomatis)
│   ├── procedures.sql          # Stored Procedures
│   ├── functions.sql           # Stored Functions
│   ├── views.sql               # Database Views
│   ├── package.sql             # Oracle Package (spec + body)
│   ├── sample_data.sql         # Data sample (10 users, 20 posts, dll)
│   └── tcl_demo.sql            # Demo COMMIT, ROLLBACK, SAVEPOINT
│
├── backend/                    # Node.js Express Backend
│   ├── config/
│   │   ├── database.js         # Oracle connection pool
│   │   └── multer.js           # File upload config
│   ├── controllers/
│   │   ├── authController.js   # Register, Login, Logout, Me
│   │   ├── postController.js   # CRUD posts, likes, comments
│   │   ├── userController.js   # Profile, follow, search
│   │   ├── notificationController.js
│   │   └── adminController.js  # Admin dashboard operations
│   ├── middleware/
│   │   ├── auth.js             # JWT authenticate & authorize
│   │   └── errorHandler.js     # Centralized error handling
│   ├── routes/
│   │   ├── authRoutes.js
│   │   ├── postRoutes.js
│   │   ├── userRoutes.js       # (+ notif, report, admin routes)
│   │   └── ...
│   ├── uploads/                # Uploaded images stored here
│   ├── app.js                  # Express app config
│   ├── server.js               # Entry point
│   ├── package.json
│   └── .env.example
│
└── frontend/                   # Vanilla HTML/CSS/JS
    ├── css/
    │   └── style.css           # Global stylesheet (dark mode)
    ├── js/
    │   └── api.js              # API client + utilities
    ├── pages/
    │   ├── login.html
    │   ├── register.html
    │   ├── timeline.html       # Main feed
    │   ├── profile.html        # User profile
    │   ├── notifications.html
    │   ├── search.html
    │   └── admin.html          # Admin dashboard
    └── index.html              # Entry redirect
```

---

## ⚙️ Instalasi & Konfigurasi

### Prasyarat
- Oracle Database 19c / 21c / XE (versi apapun yang mendukung PL/SQL)
- Node.js v18+
- npm v9+

### 1. Setup Oracle Database

```sql
-- Login sebagai DBA atau user yang punya privileges
-- Buat user baru (opsional)
CREATE USER sociaverse IDENTIFIED BY password123;
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE PROCEDURE,
      CREATE TRIGGER, CREATE SEQUENCE TO sociaverse;

-- Jalankan file SQL secara berurutan di SQL*Plus atau SQL Developer:
@database/ddl.sql
@database/sequences.sql
@database/triggers.sql
@database/functions.sql
@database/procedures.sql
@database/views.sql
@database/package.sql
@database/sample_data.sql
```

### 2. Setup Backend

```bash
cd backend

# Install dependencies
npm install

# Salin file environment
cp .env.example .env

# Edit .env sesuai konfigurasi Oracle Anda
nano .env
```

Isi file `.env`:
```
PORT=5000
DB_USER=sociaverse
DB_PASSWORD=password123
DB_CONNECT_STRING=localhost:1521/XEPDB1
JWT_SECRET=ganti_dengan_secret_yang_kuat_dan_panjang
JWT_EXPIRES_IN=7d
UPLOAD_PATH=uploads
```

### 3. Jalankan Backend

```bash
# Development (auto-reload)
npm run dev

# Production
npm start
```

Backend berjalan di: `http://localhost:5000`

### 4. Jalankan Frontend

Frontend adalah file HTML statis. Buka langsung di browser:

```bash
# Opsi 1: Buka langsung
open frontend/index.html

# Opsi 2: Gunakan Live Server (VS Code extension)
# Opsi 3: Gunakan serve (npm)
npx serve frontend -p 3000
```

Frontend berjalan di: `http://localhost:3000`

---

## 📡 API Documentation

### Base URL: `http://localhost:5000/api`

#### 🔐 Authentication
| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/auth/register` | ✗ | Daftar akun baru |
| POST | `/auth/login` | ✗ | Login |
| POST | `/auth/logout` | ✓ | Logout |
| GET | `/auth/me` | ✓ | Info user saat ini |

#### 📝 Posts
| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/posts` | Optional | Timeline (paginated) |
| GET | `/posts/:id` | Optional | Detail post + komentar |
| POST | `/posts` | ✓ | Buat post baru |
| PUT | `/posts/:id` | ✓ | Edit post |
| DELETE | `/posts/:id` | ✓ | Hapus post |
| POST | `/posts/:id/like` | ✓ | Toggle like/unlike |
| POST | `/posts/:id/comment` | ✓ | Tambah komentar |
| DELETE | `/posts/:id/comments/:cid` | ✓ | Hapus komentar |

#### 👥 Users
| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/users/search?q=` | ✓ | Cari pengguna |
| GET | `/users/:username` | Optional | Profil pengguna |
| PUT | `/users/profile/edit` | ✓ | Edit profil |
| PUT | `/users/profile/password` | ✓ | Ganti password |
| POST | `/users/:id/follow` | ✓ | Follow/unfollow |
| GET | `/users/:id/followers` | Optional | Daftar followers |
| GET | `/users/:id/following` | Optional | Daftar following |

#### 🔔 Notifications
| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/notifications` | ✓ | Semua notifikasi |
| PUT | `/notifications/read-all` | ✓ | Tandai semua dibaca |
| PUT | `/notifications/:id/read` | ✓ | Tandai 1 dibaca |

#### ⚠️ Reports
| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/reports` | ✓ | Laporkan postingan |

#### ⚙️ Admin (requires admin role)
| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/admin/stats` | Admin | Statistik dashboard |
| GET | `/admin/users` | Admin | Semua pengguna |
| POST | `/admin/users/:id/ban` | Admin | Ban/unban user |
| GET | `/admin/posts` | Admin | Semua postingan |
| GET | `/admin/reports` | Admin | Daftar laporan |
| PUT | `/admin/reports/:id` | Admin | Update status laporan |

---

## 🗄 Fitur Oracle Database

### Sequences
| Sequence | Digunakan untuk |
|----------|----------------|
| `seq_users` | `users.user_id` |
| `seq_posts` | `posts.post_id` |
| `seq_comments` | `comments.comment_id` |
| `seq_likes` | `likes.like_id` |
| `seq_follows` | `follows.follow_id` |
| `seq_notifications` | `notifications.notification_id` |
| `seq_reports` | `post_reports.report_id` |

### Triggers
| Trigger | Event | Fungsi |
|---------|-------|--------|
| `trg_users_bi` | BEFORE INSERT on users | Auto-increment user_id |
| `trg_posts_bi` | BEFORE INSERT on posts | Auto-increment post_id |
| `trg_comments_bi` | BEFORE INSERT on comments | Auto-increment comment_id |
| `trg_likes_bi` | BEFORE INSERT on likes | Auto-increment like_id |
| `trg_follows_bi` | BEFORE INSERT on follows | Auto-increment follow_id |
| `trg_notifications_bi` | BEFORE INSERT on notifications | Auto-increment notification_id |
| `trg_reports_bi` | BEFORE INSERT on post_reports | Auto-increment report_id |
| `trg_likes_notif` | AFTER INSERT on likes | **Buat notifikasi otomatis** |
| `trg_comments_notif` | AFTER INSERT on comments | **Buat notifikasi otomatis** |
| `trg_follows_notif` | AFTER INSERT on follows | **Buat notifikasi otomatis** |
| `trg_posts_bu` | BEFORE UPDATE on posts | Set `updated_at` & `is_edited = 1` |

### Stored Procedures (dalam Package `social_media_pkg`)
| Procedure | Deskripsi |
|-----------|-----------|
| `create_post` | Validasi + insert post |
| `follow_user` | Toggle follow/unfollow |
| `ban_user` | Admin ban/unban user |
| `report_post` | Validasi + submit laporan |

### Functions (dalam Package `social_media_pkg`)
| Function | Return | Deskripsi |
|----------|--------|-----------|
| `get_follower_count(user_id)` | NUMBER | Jumlah followers |
| `get_following_count(user_id)` | NUMBER | Jumlah following |
| `get_post_engagement(post_id)` | NUMBER | Total likes + komentar |
| `get_unread_notification_count(user_id)` | NUMBER | Notifikasi belum dibaca |

### Views
| View | Deskripsi |
|------|-----------|
| `timeline_view` | Feed postingan dengan like_count, comment_count, info user |
| `user_profile_view` | Profil user dengan total_posts, followers, following |
| `admin_reports_view` | Laporan dengan detail post dan user |
| `notifications_detail_view` | Notifikasi dengan info pengirim |

### Package: `social_media_pkg`
Package tunggal yang mengenkapsulasi semua procedure dan function. Ini adalah best practice Oracle untuk mengelompokkan logika bisnis terkait.

---

## 🎬 Skenario Demo Presentasi

### Skenario 1: Alur Registrasi & Login
1. Buka `frontend/pages/register.html`
2. Daftar dengan username `demo_user`
3. Login → token JWT tersimpan di localStorage
4. Tampilkan tabel `users` di Oracle → user baru ada

### Skenario 2: Trigger Notifikasi Otomatis
1. Login sebagai `budi_pratama` → Like post milik `sari_dewi`
2. Tampilkan tabel `notifications` di Oracle → notifikasi baru otomatis terbuat oleh trigger `trg_likes_notif`
3. Login sebagai `sari_dewi` → lihat halaman Notifikasi → notifikasi "budi_pratama menyukai postingan Anda"

### Skenario 3: Stored Procedure via API
1. Buat postingan baru
2. Di Oracle: `EXEC social_media_pkg.create_post(...)` → tunjukkan validasi berjalan
3. Coba buat post dengan konten kosong → prosedur mengembalikan error

### Skenario 4: Oracle Package & Functions
```sql
-- Jalankan di SQL*Plus / SQL Developer
SELECT username,
       social_media_pkg.get_follower_count(user_id)   AS followers,
       social_media_pkg.get_following_count(user_id)  AS following,
       social_media_pkg.get_post_engagement(
           (SELECT MIN(post_id) FROM posts WHERE user_id = u.user_id)
       ) AS post_engagement
FROM users u
WHERE rownum <= 5;
```

### Skenario 5: Views
```sql
-- Timeline View
SELECT username, content, like_count, comment_count
FROM   timeline_view
FETCH FIRST 5 ROWS ONLY;

-- User Profile View
SELECT username, total_posts, total_followers, total_following
FROM   user_profile_view
WHERE  username = 'budi_pratama';
```

### Skenario 6: TCL Demo
```sql
@database/tcl_demo.sql
-- Tunjukkan COMMIT, ROLLBACK, dan SAVEPOINT secara langsung
```

### Skenario 7: Admin Dashboard
1. Login sebagai `admin` / `admin@sociaverse.id` (password: `Password123!`)
2. Buka halaman Admin → tampilkan statistik
3. Blokir user → konfirmasi `is_active = 0` di Oracle
4. Review laporan → update status dari `pending` ke `resolved`

---

## 👨‍💻 Akun Default (Sample Data)

| Username | Email | Role | Password (plain) |
|----------|-------|------|-----------------|
| `admin` | admin@sociaverse.id | admin | *update hash di sample_data.sql* |
| `budi_pratama` | budi@email.com | user | *update hash di sample_data.sql* |
| `sari_dewi` | sari@email.com | user | *update hash di sample_data.sql* |

> **Catatan:** Hash bcrypt di `sample_data.sql` perlu di-generate ulang. Gunakan script Node.js:
> ```javascript
> const bcrypt = require('bcryptjs');
> const hash = await bcrypt.hash('Password123!', 10);
> console.log(hash); // Paste ke sample_data.sql
> ```

---

## 📝 Catatan Teknis

- **OracleDB Thin Mode:** Jika tidak ada Oracle Client terinstal, comment baris `oracledb.initOracleClient()` di `config/database.js` untuk menggunakan Thin mode
- **CORS:** Pastikan `FRONTEND_URL` di `.env` sesuai URL frontend Anda
- **Uploads:** Direktori `backend/uploads/` dibuat otomatis saat server start
- **JWT:** Token berlaku 7 hari (dapat diubah via `JWT_EXPIRES_IN` di `.env`)
