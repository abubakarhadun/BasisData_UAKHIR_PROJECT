-- ============================================================
-- SOCIAVERSE - Simple Social Media Platform
-- File: procedures.sql
-- Description: Stored Procedures for core business logic
-- ============================================================

-- ============================================================
-- PROCEDURE: sp_create_post
-- Purpose  : Create a new post with validation
-- Params   : p_user_id    - Author's user ID
--            p_content    - Post text content (min 1 char)
--            p_image_url  - Optional image URL
--            p_post_id    - OUT: the created post's ID
--            p_status     - OUT: 'SUCCESS' or error message
-- ============================================================
CREATE OR REPLACE PROCEDURE sp_create_post (
    p_user_id   IN  posts.user_id%TYPE,
    p_content   IN  posts.content%TYPE,
    p_image_url IN  posts.image_url%TYPE DEFAULT NULL,
    p_post_id   OUT posts.post_id%TYPE,
    p_status    OUT VARCHAR2
) AS
    v_is_active users.is_active%TYPE;
    v_count     NUMBER;
BEGIN
    -- Validate: user must exist
    SELECT COUNT(*) INTO v_count FROM users WHERE user_id = p_user_id;
    IF v_count = 0 THEN
        p_status := 'ERROR: User tidak ditemukan.';
        RETURN;
    END IF;

    -- Validate: user must be active (not banned)
    SELECT is_active INTO v_is_active FROM users WHERE user_id = p_user_id;
    IF v_is_active = 0 THEN
        p_status := 'ERROR: Akun Anda telah dinonaktifkan.';
        RETURN;
    END IF;

    -- Validate: content cannot be empty or only whitespace
    IF TRIM(p_content) IS NULL OR LENGTH(TRIM(p_content)) = 0 THEN
        p_status := 'ERROR: Konten postingan tidak boleh kosong.';
        RETURN;
    END IF;

    -- Validate: content max length
    IF LENGTH(p_content) > 2000 THEN
        p_status := 'ERROR: Konten melebihi batas 2000 karakter.';
        RETURN;
    END IF;

    -- Insert the post (trigger handles auto-increment)
    INSERT INTO posts (user_id, content, image_url, created_at)
    VALUES (p_user_id, TRIM(p_content), p_image_url, CURRENT_TIMESTAMP)
    RETURNING post_id INTO p_post_id;

    COMMIT;
    p_status := 'SUCCESS';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_post_id := NULL;
        p_status  := 'ERROR: ' || SQLERRM;
END sp_create_post;
/

-- ============================================================
-- PROCEDURE: sp_follow_user
-- Purpose  : Follow or unfollow a user (toggle)
-- Params   : p_follower_id   - User who wants to follow
--            p_following_id  - User to be followed
--            p_action        - OUT: 'FOLLOWED', 'UNFOLLOWED', or error
-- ============================================================
CREATE OR REPLACE PROCEDURE sp_follow_user (
    p_follower_id   IN  follows.follower_id%TYPE,
    p_following_id  IN  follows.following_id%TYPE,
    p_action        OUT VARCHAR2
) AS
    v_count         NUMBER;
    v_follow_id     follows.follow_id%TYPE;
    v_follower_active users.is_active%TYPE;
    v_following_active users.is_active%TYPE;
BEGIN
    -- Validate: cannot follow yourself
    IF p_follower_id = p_following_id THEN
        p_action := 'ERROR: Anda tidak dapat mengikuti diri sendiri.';
        RETURN;
    END IF;

    -- Validate: both users must exist and be active
    SELECT is_active INTO v_follower_active FROM users WHERE user_id = p_follower_id;
    SELECT is_active INTO v_following_active FROM users WHERE user_id = p_following_id;

    IF v_follower_active = 0 THEN
        p_action := 'ERROR: Akun Anda telah dinonaktifkan.';
        RETURN;
    END IF;

    IF v_following_active = 0 THEN
        p_action := 'ERROR: Pengguna yang ingin diikuti tidak aktif.';
        RETURN;
    END IF;

    -- Check if already following
    SELECT COUNT(*) INTO v_count
    FROM follows
    WHERE follower_id = p_follower_id AND following_id = p_following_id;

    IF v_count > 0 THEN
        -- Already following → UNFOLLOW
        DELETE FROM follows
        WHERE follower_id = p_follower_id AND following_id = p_following_id;

        COMMIT;
        p_action := 'UNFOLLOWED';
    ELSE
        -- Not following → FOLLOW (trigger will create notification)
        INSERT INTO follows (follower_id, following_id, created_at)
        VALUES (p_follower_id, p_following_id, CURRENT_TIMESTAMP);

        COMMIT;
        p_action := 'FOLLOWED';
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        p_action := 'ERROR: Pengguna tidak ditemukan.';
    WHEN OTHERS THEN
        ROLLBACK;
        p_action := 'ERROR: ' || SQLERRM;
END sp_follow_user;
/

-- ============================================================
-- PROCEDURE: sp_ban_user
-- Purpose  : Admin bans (deactivates) or unbans a user
-- Params   : p_admin_id   - Admin performing the action
--            p_target_id  - User to ban/unban
--            p_ban        - 1 to ban, 0 to unban
--            p_status     - OUT: 'SUCCESS' or error message
-- ============================================================
CREATE OR REPLACE PROCEDURE sp_ban_user (
    p_admin_id  IN  users.user_id%TYPE,
    p_target_id IN  users.user_id%TYPE,
    p_ban       IN  NUMBER,
    p_status    OUT VARCHAR2
) AS
    v_admin_role    users.role%TYPE;
    v_target_role   users.role%TYPE;
    v_count         NUMBER;
BEGIN
    -- Validate: admin must exist
    SELECT COUNT(*) INTO v_count FROM users WHERE user_id = p_admin_id;
    IF v_count = 0 THEN
        p_status := 'ERROR: Admin tidak ditemukan.';
        RETURN;
    END IF;

    -- Validate: actor must be an admin
    SELECT role INTO v_admin_role FROM users WHERE user_id = p_admin_id;
    IF v_admin_role <> 'admin' THEN
        p_status := 'ERROR: Anda tidak memiliki izin admin.';
        RETURN;
    END IF;

    -- Validate: target user must exist
    SELECT COUNT(*) INTO v_count FROM users WHERE user_id = p_target_id;
    IF v_count = 0 THEN
        p_status := 'ERROR: Pengguna target tidak ditemukan.';
        RETURN;
    END IF;

    -- Validate: cannot ban another admin
    SELECT role INTO v_target_role FROM users WHERE user_id = p_target_id;
    IF v_target_role = 'admin' THEN
        p_status := 'ERROR: Tidak dapat menonaktifkan akun admin lain.';
        RETURN;
    END IF;

    -- Validate: cannot ban yourself
    IF p_admin_id = p_target_id THEN
        p_status := 'ERROR: Anda tidak dapat menonaktifkan akun Anda sendiri.';
        RETURN;
    END IF;

    -- Validate: p_ban value
    IF p_ban NOT IN (0, 1) THEN
        p_status := 'ERROR: Nilai ban tidak valid. Gunakan 1 (ban) atau 0 (unban).';
        RETURN;
    END IF;

    -- Update user status
    UPDATE users SET is_active = (CASE WHEN p_ban = 1 THEN 0 ELSE 1 END)
    WHERE user_id = p_target_id;

    COMMIT;
    p_status := CASE WHEN p_ban = 1 THEN 'SUCCESS: Pengguna berhasil dinonaktifkan.'
                     ELSE 'SUCCESS: Pengguna berhasil diaktifkan kembali.'
                END;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_status := 'ERROR: ' || SQLERRM;
END sp_ban_user;
/

-- ============================================================
-- PROCEDURE: sp_report_post
-- Purpose  : Submit a report against a post
-- Params   : p_reporter_id - User submitting the report
--            p_post_id     - Post being reported
--            p_reason      - Description of the violation
--            p_report_id   - OUT: Created report ID
--            p_status      - OUT: 'SUCCESS' or error message
-- ============================================================
CREATE OR REPLACE PROCEDURE sp_report_post (
    p_reporter_id   IN  post_reports.reporter_id%TYPE,
    p_post_id       IN  post_reports.post_id%TYPE,
    p_reason        IN  post_reports.reason%TYPE,
    p_report_id     OUT post_reports.report_id%TYPE,
    p_status        OUT VARCHAR2
) AS
    v_count         NUMBER;
    v_is_active     users.is_active%TYPE;
    v_post_owner    posts.user_id%TYPE;
BEGIN
    -- Validate: reporter must exist and be active
    SELECT COUNT(*) INTO v_count FROM users WHERE user_id = p_reporter_id;
    IF v_count = 0 THEN
        p_status := 'ERROR: Pengguna tidak ditemukan.';
        RETURN;
    END IF;

    SELECT is_active INTO v_is_active FROM users WHERE user_id = p_reporter_id;
    IF v_is_active = 0 THEN
        p_status := 'ERROR: Akun Anda telah dinonaktifkan.';
        RETURN;
    END IF;

    -- Validate: post must exist
    SELECT COUNT(*) INTO v_count FROM posts WHERE post_id = p_post_id;
    IF v_count = 0 THEN
        p_status := 'ERROR: Postingan tidak ditemukan.';
        RETURN;
    END IF;

    -- Validate: cannot report your own post
    SELECT user_id INTO v_post_owner FROM posts WHERE post_id = p_post_id;
    IF v_post_owner = p_reporter_id THEN
        p_status := 'ERROR: Anda tidak dapat melaporkan postingan Anda sendiri.';
        RETURN;
    END IF;

    -- Validate: reason cannot be empty
    IF TRIM(p_reason) IS NULL OR LENGTH(TRIM(p_reason)) < 10 THEN
        p_status := 'ERROR: Alasan laporan minimal 10 karakter.';
        RETURN;
    END IF;

    -- Validate: cannot report the same post twice
    SELECT COUNT(*) INTO v_count
    FROM post_reports
    WHERE post_id = p_post_id AND reporter_id = p_reporter_id AND status = 'pending';

    IF v_count > 0 THEN
        p_status := 'ERROR: Anda sudah melaporkan postingan ini dan masih dalam proses review.';
        RETURN;
    END IF;

    -- Insert the report
    INSERT INTO post_reports (post_id, reporter_id, reason, status, created_at)
    VALUES (p_post_id, p_reporter_id, TRIM(p_reason), 'pending', CURRENT_TIMESTAMP)
    RETURNING report_id INTO p_report_id;

    COMMIT;
    p_status := 'SUCCESS';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_report_id := NULL;
        p_status    := 'ERROR: ' || SQLERRM;
END sp_report_post;
/

PROMPT '✅ All stored procedures created successfully';
