-- ============================================================
-- SOCIAVERSE - Simple Social Media Platform
-- File: tcl_demo.sql
-- Description: Transaction Control Language (TCL) Demonstration
--              Menunjukkan penggunaan COMMIT, ROLLBACK, SAVEPOINT
-- ============================================================

-- ============================================================
-- TCL SKENARIO 1: COMMIT - Transaksi Berhasil
-- 
-- Skenario: User baru mendaftar dan langsung membuat post pertama.
-- Kedua operasi ini harus SUKSES bersamaan atau GAGAL bersamaan.
-- ============================================================
PROMPT '=== SKENARIO 1: COMMIT - Registrasi + Post Pertama ===';

BEGIN
    -- Langkah 1: Insert user baru
    INSERT INTO users (username, email, password, fullname, bio, role, is_active)
    VALUES ('demo_commit', 'demo_commit@email.com', 'hashedpassword', 
            'Demo Commit User', 'Testing TCL COMMIT', 'user', 1);

    PROMPT 'Step 1: User "demo_commit" berhasil ditambahkan.';

    -- Langkah 2: Insert post pertama untuk user tersebut
    -- (user_id akan didapat dari sequence via trigger)
    INSERT INTO posts (user_id, content, created_at)
    SELECT user_id, 'Post pertama saya di Sociaverse! Excited! 🎉', CURRENT_TIMESTAMP
    FROM   users WHERE username = 'demo_commit';

    PROMPT 'Step 2: Post pertama "demo_commit" berhasil dibuat.';

    -- COMMIT: Simpan kedua operasi secara permanen ke database
    COMMIT;

    PROMPT 'COMMIT berhasil. Semua perubahan disimpan secara permanen.';

EXCEPTION
    WHEN OTHERS THEN
        -- Jika terjadi error, batalkan semua perubahan dalam blok ini
        ROLLBACK;
        PROMPT 'ERROR! ROLLBACK dilakukan. Tidak ada perubahan yang tersimpan.';
        RAISE;
END;
/

-- ============================================================
-- TCL SKENARIO 2: ROLLBACK - Transaksi Dibatalkan
--
-- Skenario: Admin mencoba ban user, tapi terjadi error validasi.
-- Seluruh transaksi dibatalkan untuk menjaga konsistensi data.
-- ============================================================
PROMPT '';
PROMPT '=== SKENARIO 2: ROLLBACK - Ban Gagal karena Validasi ===';

DECLARE
    v_target_role users.role%TYPE;
BEGIN
    -- Langkah 1: Misalnya kita mulai update status user
    UPDATE users SET is_active = 0 WHERE username = 'demo_commit';
    PROMPT 'Step 1: Update is_active = 0 berhasil (belum COMMIT).';

    -- Langkah 2: Validasi — cek apakah target adalah admin
    SELECT role INTO v_target_role FROM users WHERE username = 'demo_commit';

    IF v_target_role = 'admin' THEN
        -- Jika admin, batalkan semua perubahan dalam transaksi ini
        ROLLBACK;
        PROMPT 'VALIDASI GAGAL: Target adalah admin. ROLLBACK dilakukan.';
        PROMPT 'Status user tidak berubah.';
    ELSE
        -- Jika bukan admin, lanjutkan dan commit
        COMMIT;
        PROMPT 'COMMIT: User berhasil dinonaktifkan.';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        PROMPT 'ERROR: User tidak ditemukan. ROLLBACK dilakukan.';
    WHEN OTHERS THEN
        ROLLBACK;
        PROMPT 'ERROR: ' || SQLERRM || '. ROLLBACK dilakukan.';
END;
/

-- ============================================================
-- TCL SKENARIO 3: SAVEPOINT - Partial Rollback
--
-- Skenario: Proses import batch data. Beberapa langkah berhasil
-- dan kita ingin kembali ke titik tertentu jika ada yang gagal,
-- tanpa membatalkan semua transaksi.
-- ============================================================
PROMPT '';
PROMPT '=== SKENARIO 3: SAVEPOINT - Partial Rollback pada Batch Import ===';

DECLARE
    v_post_id_1 posts.post_id%TYPE;
    v_post_id_2 posts.post_id%TYPE;
    v_user_id   users.user_id%TYPE;
BEGIN
    -- Dapatkan user_id demo_commit untuk demo
    SELECT user_id INTO v_user_id FROM users WHERE username = 'demo_commit';

    -- SAVEPOINT 1: sebelum insert post batch
    SAVEPOINT sp_before_batch;
    PROMPT 'SAVEPOINT sp_before_batch dibuat.';

    -- Langkah 1: Insert post pertama (valid)
    INSERT INTO posts (user_id, content, created_at)
    VALUES (v_user_id, 'Batch post #1 - konten valid 📝', CURRENT_TIMESTAMP)
    RETURNING post_id INTO v_post_id_1;
    PROMPT 'Post #1 berhasil diinsert. post_id = ' || v_post_id_1;

    -- SAVEPOINT 2: setelah post pertama berhasil
    SAVEPOINT sp_after_post1;
    PROMPT 'SAVEPOINT sp_after_post1 dibuat.';

    -- Langkah 2: Insert post kedua (valid)
    INSERT INTO posts (user_id, content, created_at)
    VALUES (v_user_id, 'Batch post #2 - konten valid juga 🌟', CURRENT_TIMESTAMP)
    RETURNING post_id INTO v_post_id_2;
    PROMPT 'Post #2 berhasil diinsert. post_id = ' || v_post_id_2;

    -- Langkah 3: Simulasi error — misalnya mencoba like post dengan user_id yang sama (duplicate)
    -- Ini akan menyebabkan error karena UNIQUE constraint pada (user_id, post_id)
    BEGIN
        -- Simulasi: coba rollback ke savepoint karena business rule dilanggar
        -- (misalnya: post konten kosong)
        IF LENGTH('') = 0 THEN
            -- Rollback hanya ke sp_after_post1 (post #1 tetap ada, post #2 dibatalkan)
            ROLLBACK TO SAVEPOINT sp_after_post1;
            PROMPT 'Validasi gagal pada Post #3. ROLLBACK TO sp_after_post1.';
            PROMPT 'Post #1 tetap ada, Post #2 dibatalkan.';
        END IF;
    END;

    -- Commit semua perubahan yang valid (hanya post #1 yang tersimpan)
    COMMIT;
    PROMPT 'COMMIT akhir: Hanya Post #1 yang tersimpan secara permanen.';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK TO SAVEPOINT sp_before_batch;
        PROMPT 'ERROR serius: ROLLBACK ke sp_before_batch. Semua batch dibatalkan.';
    WHEN OTHERS THEN
        ROLLBACK;
        PROMPT 'FATAL ERROR: Full ROLLBACK. Error: ' || SQLERRM;
END;
/

-- ============================================================
-- VERIFIKASI HASIL TCL DEMO
-- ============================================================
PROMPT '';
PROMPT '=== VERIFIKASI DATA SETELAH TCL DEMO ===';

SELECT 
    u.username,
    u.fullname,
    u.is_active,
    COUNT(p.post_id) AS total_posts
FROM users u
LEFT JOIN posts p ON u.user_id = p.user_id
WHERE u.username = 'demo_commit'
GROUP BY u.username, u.fullname, u.is_active;

-- Bersihkan data demo
DELETE FROM posts WHERE user_id = (SELECT user_id FROM users WHERE username = 'demo_commit');
DELETE FROM users WHERE username = 'demo_commit';
COMMIT;

PROMPT 'Data demo dibersihkan. TCL Demo selesai.';

-- ============================================================
-- RINGKASAN TCL
-- ============================================================
/*
COMMIT   : Menyimpan SEMUA perubahan dalam transaksi saat ini
           secara permanen ke database. Tidak bisa diundo.
           Gunakan setelah semua operasi dalam transaksi sukses.

ROLLBACK : Membatalkan SEMUA perubahan yang belum di-COMMIT.
           Mengembalikan database ke kondisi terakhir COMMIT.
           Gunakan saat terjadi error atau validasi gagal.

ROLLBACK TO SAVEPOINT <name>:
           Membatalkan perubahan hanya sampai titik SAVEPOINT.
           Perubahan sebelum SAVEPOINT tetap ada (belum committed).
           Perlu COMMIT atau ROLLBACK penuh setelahnya.

SAVEPOINT <name>:
           Menandai titik dalam transaksi yang bisa dijadikan
           target ROLLBACK parsial. Berguna untuk transaksi
           panjang dengan beberapa tahap validasi.
*/
