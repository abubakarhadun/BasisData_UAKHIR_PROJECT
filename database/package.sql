-- ============================================================
-- SOCIAVERSE - Simple Social Media Platform
-- File: package.sql
-- Description: social_media_pkg - Unified package for all
--              procedures and functions (Oracle best practice)
-- ============================================================

-- ============================================================
-- PACKAGE SPECIFICATION
-- Declares all public procedures and functions
-- ============================================================
CREATE OR REPLACE PACKAGE social_media_pkg AS

    -- --------------------------------------------------------
    -- PROCEDURES
    -- --------------------------------------------------------

    -- Create a new post with validation
    PROCEDURE create_post (
        p_user_id   IN  posts.user_id%TYPE,
        p_content   IN  posts.content%TYPE,
        p_image_url IN  posts.image_url%TYPE DEFAULT NULL,
        p_post_id   OUT posts.post_id%TYPE,
        p_status    OUT VARCHAR2
    );

    -- Follow or unfollow a user (toggle)
    PROCEDURE follow_user (
        p_follower_id   IN  follows.follower_id%TYPE,
        p_following_id  IN  follows.following_id%TYPE,
        p_action        OUT VARCHAR2
    );

    -- Admin: ban or unban a user
    PROCEDURE ban_user (
        p_admin_id  IN  users.user_id%TYPE,
        p_target_id IN  users.user_id%TYPE,
        p_ban       IN  NUMBER,
        p_status    OUT VARCHAR2
    );

    -- Report a post for admin review
    PROCEDURE report_post (
        p_reporter_id   IN  post_reports.reporter_id%TYPE,
        p_post_id       IN  post_reports.post_id%TYPE,
        p_reason        IN  post_reports.reason%TYPE,
        p_report_id     OUT post_reports.report_id%TYPE,
        p_status        OUT VARCHAR2
    );

    -- --------------------------------------------------------
    -- FUNCTIONS
    -- --------------------------------------------------------

    -- Return follower count for a user
    FUNCTION get_follower_count (
        p_user_id IN users.user_id%TYPE
    ) RETURN NUMBER;

    -- Return following count for a user
    FUNCTION get_following_count (
        p_user_id IN users.user_id%TYPE
    ) RETURN NUMBER;

    -- Return total engagement (likes + comments) for a post
    FUNCTION get_post_engagement (
        p_post_id IN posts.post_id%TYPE
    ) RETURN NUMBER;

    -- Return unread notification count for a user
    FUNCTION get_unread_notification_count (
        p_user_id IN users.user_id%TYPE
    ) RETURN NUMBER;

END social_media_pkg;
/

-- ============================================================
-- PACKAGE BODY
-- Full implementation of all declared members
-- ============================================================
CREATE OR REPLACE PACKAGE BODY social_media_pkg AS

    -- --------------------------------------------------------
    -- PROCEDURE: create_post
    -- --------------------------------------------------------
    PROCEDURE create_post (
        p_user_id   IN  posts.user_id%TYPE,
        p_content   IN  posts.content%TYPE,
        p_image_url IN  posts.image_url%TYPE DEFAULT NULL,
        p_post_id   OUT posts.post_id%TYPE,
        p_status    OUT VARCHAR2
    ) AS
        v_is_active users.is_active%TYPE;
        v_count     NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM users WHERE user_id = p_user_id;
        IF v_count = 0 THEN
            p_status := 'ERROR: User tidak ditemukan.'; RETURN;
        END IF;

        SELECT is_active INTO v_is_active FROM users WHERE user_id = p_user_id;
        IF v_is_active = 0 THEN
            p_status := 'ERROR: Akun Anda telah dinonaktifkan.'; RETURN;
        END IF;

        IF TRIM(p_content) IS NULL OR LENGTH(TRIM(p_content)) = 0 THEN
            p_status := 'ERROR: Konten postingan tidak boleh kosong.'; RETURN;
        END IF;

        IF LENGTH(p_content) > 2000 THEN
            p_status := 'ERROR: Konten melebihi batas 2000 karakter.'; RETURN;
        END IF;

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
    END create_post;

    -- --------------------------------------------------------
    -- PROCEDURE: follow_user
    -- --------------------------------------------------------
    PROCEDURE follow_user (
        p_follower_id   IN  follows.follower_id%TYPE,
        p_following_id  IN  follows.following_id%TYPE,
        p_action        OUT VARCHAR2
    ) AS
        v_count NUMBER;
        v_follower_active  users.is_active%TYPE;
        v_following_active users.is_active%TYPE;
    BEGIN
        IF p_follower_id = p_following_id THEN
            p_action := 'ERROR: Tidak dapat mengikuti diri sendiri.'; RETURN;
        END IF;

        SELECT is_active INTO v_follower_active  FROM users WHERE user_id = p_follower_id;
        SELECT is_active INTO v_following_active FROM users WHERE user_id = p_following_id;

        IF v_follower_active = 0  THEN p_action := 'ERROR: Akun Anda tidak aktif.'; RETURN; END IF;
        IF v_following_active = 0 THEN p_action := 'ERROR: Pengguna tidak aktif.';  RETURN; END IF;

        SELECT COUNT(*) INTO v_count FROM follows
        WHERE follower_id = p_follower_id AND following_id = p_following_id;

        IF v_count > 0 THEN
            DELETE FROM follows WHERE follower_id = p_follower_id AND following_id = p_following_id;
            COMMIT;
            p_action := 'UNFOLLOWED';
        ELSE
            INSERT INTO follows (follower_id, following_id, created_at)
            VALUES (p_follower_id, p_following_id, CURRENT_TIMESTAMP);
            COMMIT;
            p_action := 'FOLLOWED';
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN ROLLBACK; p_action := 'ERROR: Pengguna tidak ditemukan.';
        WHEN OTHERS THEN       ROLLBACK; p_action := 'ERROR: ' || SQLERRM;
    END follow_user;

    -- --------------------------------------------------------
    -- PROCEDURE: ban_user
    -- --------------------------------------------------------
    PROCEDURE ban_user (
        p_admin_id  IN  users.user_id%TYPE,
        p_target_id IN  users.user_id%TYPE,
        p_ban       IN  NUMBER,
        p_status    OUT VARCHAR2
    ) AS
        v_admin_role  users.role%TYPE;
        v_target_role users.role%TYPE;
        v_count       NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM users WHERE user_id = p_admin_id;
        IF v_count = 0 THEN p_status := 'ERROR: Admin tidak ditemukan.'; RETURN; END IF;

        SELECT role INTO v_admin_role FROM users WHERE user_id = p_admin_id;
        IF v_admin_role <> 'admin' THEN p_status := 'ERROR: Tidak memiliki izin admin.'; RETURN; END IF;

        SELECT COUNT(*) INTO v_count FROM users WHERE user_id = p_target_id;
        IF v_count = 0 THEN p_status := 'ERROR: Pengguna tidak ditemukan.'; RETURN; END IF;

        SELECT role INTO v_target_role FROM users WHERE user_id = p_target_id;
        IF v_target_role = 'admin' THEN p_status := 'ERROR: Tidak dapat ban admin.'; RETURN; END IF;
        IF p_admin_id = p_target_id   THEN p_status := 'ERROR: Tidak dapat ban diri sendiri.'; RETURN; END IF;

        UPDATE users SET is_active = (CASE WHEN p_ban = 1 THEN 0 ELSE 1 END)
        WHERE user_id = p_target_id;

        COMMIT;
        p_status := CASE WHEN p_ban = 1 THEN 'SUCCESS: Pengguna dinonaktifkan.'
                         ELSE 'SUCCESS: Pengguna diaktifkan kembali.' END;
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; p_status := 'ERROR: ' || SQLERRM;
    END ban_user;

    -- --------------------------------------------------------
    -- PROCEDURE: report_post
    -- --------------------------------------------------------
    PROCEDURE report_post (
        p_reporter_id   IN  post_reports.reporter_id%TYPE,
        p_post_id       IN  post_reports.post_id%TYPE,
        p_reason        IN  post_reports.reason%TYPE,
        p_report_id     OUT post_reports.report_id%TYPE,
        p_status        OUT VARCHAR2
    ) AS
        v_count      NUMBER;
        v_is_active  users.is_active%TYPE;
        v_post_owner posts.user_id%TYPE;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM users WHERE user_id = p_reporter_id;
        IF v_count = 0 THEN p_status := 'ERROR: Pengguna tidak ditemukan.'; RETURN; END IF;

        SELECT is_active INTO v_is_active FROM users WHERE user_id = p_reporter_id;
        IF v_is_active = 0 THEN p_status := 'ERROR: Akun tidak aktif.'; RETURN; END IF;

        SELECT COUNT(*) INTO v_count FROM posts WHERE post_id = p_post_id;
        IF v_count = 0 THEN p_status := 'ERROR: Postingan tidak ditemukan.'; RETURN; END IF;

        SELECT user_id INTO v_post_owner FROM posts WHERE post_id = p_post_id;
        IF v_post_owner = p_reporter_id THEN
            p_status := 'ERROR: Tidak dapat melaporkan postingan sendiri.'; RETURN;
        END IF;

        IF TRIM(p_reason) IS NULL OR LENGTH(TRIM(p_reason)) < 10 THEN
            p_status := 'ERROR: Alasan minimal 10 karakter.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO v_count FROM post_reports
        WHERE post_id = p_post_id AND reporter_id = p_reporter_id AND status = 'pending';
        IF v_count > 0 THEN
            p_status := 'ERROR: Laporan sudah ada dan sedang diproses.'; RETURN;
        END IF;

        INSERT INTO post_reports (post_id, reporter_id, reason, status, created_at)
        VALUES (p_post_id, p_reporter_id, TRIM(p_reason), 'pending', CURRENT_TIMESTAMP)
        RETURNING report_id INTO p_report_id;

        COMMIT;
        p_status := 'SUCCESS';
    EXCEPTION
        WHEN OTHERS THEN ROLLBACK; p_report_id := NULL; p_status := 'ERROR: ' || SQLERRM;
    END report_post;

    -- --------------------------------------------------------
    -- FUNCTION: get_follower_count
    -- --------------------------------------------------------
    FUNCTION get_follower_count (p_user_id IN users.user_id%TYPE) RETURN NUMBER AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM follows WHERE following_id = p_user_id;
        RETURN v_count;
    EXCEPTION WHEN OTHERS THEN RETURN 0;
    END get_follower_count;

    -- --------------------------------------------------------
    -- FUNCTION: get_following_count
    -- --------------------------------------------------------
    FUNCTION get_following_count (p_user_id IN users.user_id%TYPE) RETURN NUMBER AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM follows WHERE follower_id = p_user_id;
        RETURN v_count;
    EXCEPTION WHEN OTHERS THEN RETURN 0;
    END get_following_count;

    -- --------------------------------------------------------
    -- FUNCTION: get_post_engagement
    -- --------------------------------------------------------
    FUNCTION get_post_engagement (p_post_id IN posts.post_id%TYPE) RETURN NUMBER AS
        v_likes    NUMBER;
        v_comments NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_likes    FROM likes    WHERE post_id = p_post_id;
        SELECT COUNT(*) INTO v_comments FROM comments WHERE post_id = p_post_id;
        RETURN v_likes + v_comments;
    EXCEPTION WHEN OTHERS THEN RETURN 0;
    END get_post_engagement;

    -- --------------------------------------------------------
    -- FUNCTION: get_unread_notification_count
    -- --------------------------------------------------------
    FUNCTION get_unread_notification_count (p_user_id IN users.user_id%TYPE) RETURN NUMBER AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM notifications
        WHERE receiver_id = p_user_id AND is_read = 0;
        RETURN v_count;
    EXCEPTION WHEN OTHERS THEN RETURN 0;
    END get_unread_notification_count;

END social_media_pkg;
/

PROMPT '✅ Package social_media_pkg created successfully';
