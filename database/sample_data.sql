-- ============================================================
-- SOCIAVERSE - Simple Social Media Platform
-- File: sample_data.sql
-- Description: Initial seed data for development & demo
-- NOTE: Passwords below are bcrypt hashes of "Password123!"
-- ============================================================

-- ============================================================
-- USERS (10 users: 1 admin + 9 regular)
-- ============================================================
INSERT INTO users (username, email, password, fullname, bio, profile_picture, role, is_active)
VALUES ('admin', 'admin@sociaverse.id', '$2b$10$z2p6mOodVKTPdYGDq2yVd.HZYMvFWD.Urnwh.Wynsh9LUEKH/hQaG', 'Super Admin',
        'Platform administrator.', 'uploads/default_avatar.png', 'admin', 1);

INSERT INTO users (username, email, password, fullname, bio, profile_picture, role, is_active)
VALUES ('budi_pratama', 'budi@email.com', '$2b$10$z2p6mOodVKTPdYGDq2yVd.HZYMvFWD.Urnwh.Wynsh9LUEKH/hQaG', 'Budi Pratama',
        'Fotografer jalanan | Malang 📷', 'uploads/default_avatar.png', 'user', 1);

INSERT INTO users (username, email, password, fullname, bio, profile_picture, role, is_active)
VALUES ('sari_dewi', 'sari@email.com', '$2b$10$z2p6mOodVKTPdYGDq2yVd.HZYMvFWD.Urnwh.Wynsh9LUEKH/hQaG', 'Sari Dewi',
        'Pecinta kuliner dan travel ✈️🍜', 'uploads/default_avatar.png', 'user', 1);

INSERT INTO users (username, email, password, fullname, bio, profile_picture, role, is_active)
VALUES ('rizky_adi', 'rizky@email.com', '$2b$10$z2p6mOodVKTPdYGDq2yVd.HZYMvFWD.Urnwh.Wynsh9LUEKH/hQaG', 'Rizky Aditya',
        'Developer & coffee addict ☕', 'uploads/default_avatar.png', 'user', 1);

INSERT INTO users (username, email, password, fullname, bio, profile_picture, role, is_active)
VALUES ('maya_lestari', 'maya@email.com', '$2b$10$z2p6mOodVKTPdYGDq2yVd.HZYMvFWD.Urnwh.Wynsh9LUEKH/hQaG', 'Maya Lestari',
        'UI/UX Designer | Making things beautiful ✨', 'uploads/default_avatar.png', 'user', 1);

INSERT INTO users (username, email, password, fullname, bio, profile_picture, role, is_active)
VALUES ('dani_putra', 'dani@email.com', '$2b$10$z2p6mOodVKTPdYGDq2yVd.HZYMvFWD.Urnwh.Wynsh9LUEKH/hQaG', 'Dani Putra',
        'Gamer & anime enthusiast 🎮', 'uploads/default_avatar.png', 'user', 1);

INSERT INTO users (username, email, password, fullname, bio, profile_picture, role, is_active)
VALUES ('ayu_fitri', 'ayu@email.com', '$2b$10$z2p6mOodVKTPdYGDq2yVd.HZYMvFWD.Urnwh.Wynsh9LUEKH/hQaG', 'Ayu Fitria',
        'Mahasiswi Informatika | Coding is art 💻', 'uploads/default_avatar.png', 'user', 1);

INSERT INTO users (username, email, password, fullname, bio, profile_picture, role, is_active)
VALUES ('eko_wahyu', 'eko@email.com', '$2b$10$z2p6mOodVKTPdYGDq2yVd.HZYMvFWD.Urnwh.Wynsh9LUEKH/hQaG', 'Eko Wahyudi',
        'Mountain lover | 3000m above sea level 🏔️', 'uploads/default_avatar.png', 'user', 1);

INSERT INTO users (username, email, password, fullname, bio, profile_picture, role, is_active)
VALUES ('linda_sari', 'linda@email.com', '$2b$10$z2p6mOodVKTPdYGDq2yVd.HZYMvFWD.Urnwh.Wynsh9LUEKH/hQaG', 'Linda Sari',
        'Book lover | Kutu buku sejati 📚', 'uploads/default_avatar.png', 'user', 1);

INSERT INTO users (username, email, password, fullname, bio, profile_picture, role, is_active)
VALUES ('fajar_nugroho', 'fajar@email.com', '$2b$10$z2p6mOodVKTPdYGDq2yVd.HZYMvFWD.Urnwh.Wynsh9LUEKH/hQaG', 'Fajar Nugroho',
        'Musisi indie | Suara hati lewat melodi 🎸', 'uploads/default_avatar.png', 'user', 1);

COMMIT;

-- ============================================================
-- POSTS (20 posts)
-- ============================================================
INSERT INTO posts (user_id, content) VALUES (2, 'Pagi ini jalanan Malang begitu tenang. Ada momen-momen kecil yang sering kita lewatkan ketika buru-buru. Slow down, notice more. 🌅');
INSERT INTO posts (user_id, content) VALUES (3, 'Akhirnya nyoba Bakso Malang yang legendaris! Dagingnya beneran tebal, kuahnya gurih banget. Highly recommended untuk yang mampir ke Malang 🍜');
INSERT INTO posts (user_id, content) VALUES (4, 'Selesai deploy fitur baru. After 3 days of debugging satu bug yang ternyata cuma missing semicolon... Hidup developer 😅 #coding #developer');
INSERT INTO posts (user_id, content) VALUES (5, 'Design system baru hampir selesai. Konsistensi itu kunci. Setiap detail kecil punya alasan. UI/UX bukan hanya soal cantik, tapi soal fungsi 🎨');
INSERT INTO posts (user_id, content) VALUES (6, 'Habis marathon anime baru. 24 episode dalam satu malam. Produktif? Enggak. Bahagia? Banget. 🎮✨');
INSERT INTO posts (user_id, content) VALUES (7, 'Baru selesai ngerjain tugas basis data. Oracle PL/SQL ternyata powerful banget! Trigger-nya bikin otomatisasi jadi gampang 💡 #Oracle #Database');
INSERT INTO posts (user_id, content) VALUES (8, 'Summit Semeru! 3676 mdpl. Perjalanan 2 hari penuh effort tapi viewnya worth it banget. Indonesia memang luar biasa 🏔️🇮🇩');
INSERT INTO posts (user_id, content) VALUES (9, 'Baru selesai baca "Atomic Habits" untuk ketiga kalinya. Setiap baca selalu ada insight baru. Perubahan kecil, dampak besar 📚');
INSERT INTO posts (user_id, content) VALUES (10, 'Open mic malam ini di Kafe Jingga! Come join us 🎸 Musik indie lokal Malang makin berkembang pesat. Bangga jadi bagian dari scene ini.');
INSERT INTO posts (user_id, content) VALUES (2, 'Golden hour photography adalah keajaiban. 30 menit sebelum sunset adalah waktu paling ajaib untuk motret. Warna langitnya gak bisa bohong 🌅📷');
INSERT INTO posts (user_id, content) VALUES (3, 'Bikin rendang sendiri hari ini. 4 jam masak, hasilnya... lumayan! Masih belajar, tapi prosesnya menyenangkan 😄🥘');
INSERT INTO posts (user_id, content) VALUES (4, 'Fun fact: 80% waktu coding dipakai untuk debugging, 20% sisanya untuk nulis bug baru. Classic developer cycle 😂 #TrueStory');
INSERT INTO posts (user_id, content) VALUES (5, 'Redesign halaman onboarding selesai! User testing menunjukkan completion rate naik 40%. Data-driven design itu powerful ✨📊');
INSERT INTO posts (user_id, content) VALUES (6, 'Gaming setup baru sudah siap. RGB semua. Istri bilang kebanyakan lampu, saya bilang itu seni. We agreed to disagree 😂🎮');
INSERT INTO posts (user_id, content) VALUES (7, 'Tips belajar programming: jangan cuma baca tutorial, langsung buat project! Learning by doing is the best way 💻🚀 #TipsKoding');
INSERT INTO posts (user_id, content) VALUES (8, 'Setelah hiking, satu hal yang selalu aku yakini: alam punya cara sendiri untuk reset pikiran kita. No wifi, no problem 🌿');
INSERT INTO posts (user_id, content) VALUES (9, 'Reading challenge 2024: 52 buku dalam setahun. Sudah di angka 38! Target masih bisa tercapai 💪📚 #ReadingChallenge');
INSERT INTO posts (user_id, content) VALUES (10, 'Rekaman demo EP pertama selesai! 4 lagu, full produksi sendiri. Proses yang panjang tapi sangat worth it 🎵🎸 #IndieMusic');
INSERT INTO posts (user_id, content) VALUES (3, 'Solo trip ke Yogyakarta minggu ini. Siapa yang punya rekomendasi tempat makan hidden gem di Jogja? Drop di komen ya! 🗺️');
INSERT INTO posts (user_id, content) VALUES (4, 'Baru selesai sertifikasi Oracle Database. Proses belajarnya berat tapi ilmunya sangat berharga. Never stop learning! 🎓✅');

COMMIT;

-- ============================================================
-- COMMENTS
-- ============================================================
INSERT INTO comments (post_id, user_id, comment_text) VALUES (1, 3, 'Setuju banget! Malang pagi hari memang beda vibe-nya 😊');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (1, 4, 'Foto sunrise-nya keren banget! Pakai kamera apa bang?');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (2, 2, 'Kapan-kapan ajak aku dong! Udah lama pengen nyobain 🍜');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (3, 7, 'Hahaha relatable banget! Missing semicolon is the enemy 😂');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (3, 5, 'Programmer problem: bug yang konyol tapi susah dicarinya 😅');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (4, 7, 'Keren kak! Boleh share design system-nya buat referensi?');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (6, 4, 'Oracle memang powerful! Stored procedure-nya bikin hidup lebih mudah');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (7, 3, 'WOOOW! Impian banget bisa ke sana. Kapan open trip? 🏔️');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (8, 10, 'Buku favorit aku juga! Yang bagian habit stacking itu mind-blowing 📚');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (9, 5, 'Sayang gabisa dateng malam ini. Lain kali info lebih awal ya!');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (19, 2, 'Coba ke Warung Sate Pak Karso, legendaris! Dan Es Dawet Bu Ratno 😋');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (19, 8, 'Harus ke Pantai Parangtritis kalau ke Jogja! Dan sunrise di Borobudur 🌅');
INSERT INTO comments (post_id, user_id, comment_text) VALUES (20, 7, 'Selamat! Sertifikasi Oracle itu prestisius. Keren banget kak! 🎉');

COMMIT;

-- ============================================================
-- LIKES
-- ============================================================
INSERT INTO likes (post_id, user_id) VALUES (1, 3);
INSERT INTO likes (post_id, user_id) VALUES (1, 4);
INSERT INTO likes (post_id, user_id) VALUES (1, 5);
INSERT INTO likes (post_id, user_id) VALUES (2, 2);
INSERT INTO likes (post_id, user_id) VALUES (2, 6);
INSERT INTO likes (post_id, user_id) VALUES (3, 7);
INSERT INTO likes (post_id, user_id) VALUES (3, 5);
INSERT INTO likes (post_id, user_id) VALUES (4, 7);
INSERT INTO likes (post_id, user_id) VALUES (4, 4);
INSERT INTO likes (post_id, user_id) VALUES (6, 4);
INSERT INTO likes (post_id, user_id) VALUES (6, 3);
INSERT INTO likes (post_id, user_id) VALUES (7, 2);
INSERT INTO likes (post_id, user_id) VALUES (7, 3);
INSERT INTO likes (post_id, user_id) VALUES (7, 9);
INSERT INTO likes (post_id, user_id) VALUES (8, 2);
INSERT INTO likes (post_id, user_id) VALUES (8, 6);
INSERT INTO likes (post_id, user_id) VALUES (9, 8);
INSERT INTO likes (post_id, user_id) VALUES (10, 5);
INSERT INTO likes (post_id, user_id) VALUES (20, 7);
INSERT INTO likes (post_id, user_id) VALUES (20, 6);

COMMIT;

-- ============================================================
-- FOLLOWS (follow relationships)
-- ============================================================
INSERT INTO follows (follower_id, following_id) VALUES (2, 3);
INSERT INTO follows (follower_id, following_id) VALUES (2, 4);
INSERT INTO follows (follower_id, following_id) VALUES (3, 2);
INSERT INTO follows (follower_id, following_id) VALUES (3, 5);
INSERT INTO follows (follower_id, following_id) VALUES (4, 2);
INSERT INTO follows (follower_id, following_id) VALUES (4, 7);
INSERT INTO follows (follower_id, following_id) VALUES (5, 4);
INSERT INTO follows (follower_id, following_id) VALUES (5, 7);
INSERT INTO follows (follower_id, following_id) VALUES (6, 10);
INSERT INTO follows (follower_id, following_id) VALUES (7, 4);
INSERT INTO follows (follower_id, following_id) VALUES (8, 2);
INSERT INTO follows (follower_id, following_id) VALUES (9, 8);
INSERT INTO follows (follower_id, following_id) VALUES (10, 6);
INSERT INTO follows (follower_id, following_id) VALUES (2, 8);
INSERT INTO follows (follower_id, following_id) VALUES (3, 9);

COMMIT;

PROMPT '✅ Sample data inserted successfully';
PROMPT '   Users: 10 | Posts: 20 | Comments: 13 | Likes: 20 | Follows: 15';
