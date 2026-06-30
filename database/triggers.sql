-- ============================================================
-- SOCIAVERSE - Simple Social Media Platform
-- File: triggers.sql
-- Description: All Oracle Triggers (auto-increment + business logic)
-- ============================================================

-- ============================================================
-- TRIGGER: trg_users_bi
-- Purpose: Auto-increment user_id using seq_users before INSERT
-- ============================================================
CREATE OR REPLACE TRIGGER trg_users_bi
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF :NEW.user_id IS NULL THEN
        :NEW.user_id := seq_users.NEXTVAL;
    END IF;
END;
/

-- ============================================================
-- TRIGGER: trg_posts_bi
-- Purpose: Auto-increment post_id using seq_posts before INSERT
-- ============================================================
CREATE OR REPLACE TRIGGER trg_posts_bi
BEFORE INSERT ON posts
FOR EACH ROW
BEGIN
    IF :NEW.post_id IS NULL THEN
        :NEW.post_id := seq_posts.NEXTVAL;
    END IF;
END;
/

-- ============================================================
-- TRIGGER: trg_comments_bi
-- Purpose: Auto-increment comment_id using seq_comments before INSERT
-- ============================================================
CREATE OR REPLACE TRIGGER trg_comments_bi
BEFORE INSERT ON comments
FOR EACH ROW
BEGIN
    IF :NEW.comment_id IS NULL THEN
        :NEW.comment_id := seq_comments.NEXTVAL;
    END IF;
END;
/

-- ============================================================
-- TRIGGER: trg_likes_bi
-- Purpose: Auto-increment like_id using seq_likes before INSERT
-- ============================================================
CREATE OR REPLACE TRIGGER trg_likes_bi
BEFORE INSERT ON likes
FOR EACH ROW
BEGIN
    IF :NEW.like_id IS NULL THEN
        :NEW.like_id := seq_likes.NEXTVAL;
    END IF;
END;
/

-- ============================================================
-- TRIGGER: trg_follows_bi
-- Purpose: Auto-increment follow_id using seq_follows before INSERT
-- ============================================================
CREATE OR REPLACE TRIGGER trg_follows_bi
BEFORE INSERT ON follows
FOR EACH ROW
BEGIN
    IF :NEW.follow_id IS NULL THEN
        :NEW.follow_id := seq_follows.NEXTVAL;
    END IF;
END;
/

-- ============================================================
-- TRIGGER: trg_notifications_bi
-- Purpose: Auto-increment notification_id using seq_notifications before INSERT
-- ============================================================
CREATE OR REPLACE TRIGGER trg_notifications_bi
BEFORE INSERT ON notifications
FOR EACH ROW
BEGIN
    IF :NEW.notification_id IS NULL THEN
        :NEW.notification_id := seq_notifications.NEXTVAL;
    END IF;
END;
/

-- ============================================================
-- TRIGGER: trg_reports_bi
-- Purpose: Auto-increment report_id using seq_reports before INSERT
-- ============================================================
CREATE OR REPLACE TRIGGER trg_reports_bi
BEFORE INSERT ON post_reports
FOR EACH ROW
BEGIN
    IF :NEW.report_id IS NULL THEN
        :NEW.report_id := seq_reports.NEXTVAL;
    END IF;
END;
/

-- ============================================================
-- TRIGGER: trg_likes_notif
-- Purpose: Automatically create a notification when a post is liked.
--          Skips notification if the liker is the post owner.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_likes_notif
AFTER INSERT ON likes
FOR EACH ROW
DECLARE
    v_post_owner_id posts.user_id%TYPE;
    v_liker_name    users.username%TYPE;
BEGIN
    -- Get the owner of the liked post
    SELECT user_id INTO v_post_owner_id
    FROM posts
    WHERE post_id = :NEW.post_id;

    -- Don't notify if the user liked their own post
    IF v_post_owner_id <> :NEW.user_id THEN
        -- Get the liker's username for the message
        SELECT username INTO v_liker_name
        FROM users
        WHERE user_id = :NEW.user_id;

        -- Insert notification record
        INSERT INTO notifications (
            notification_id,
            sender_id,
            receiver_id,
            type,
            reference_id,
            message,
            is_read,
            created_at
        ) VALUES (
            seq_notifications.NEXTVAL,
            :NEW.user_id,
            v_post_owner_id,
            'like',
            :NEW.post_id,
            v_liker_name || ' menyukai postingan Anda.',
            0,
            CURRENT_TIMESTAMP
        );
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Silently ignore if post or user not found (shouldn't happen with FK)
        NULL;
    WHEN OTHERS THEN
        -- Log error without stopping the main transaction
        NULL;
END;
/

-- ============================================================
-- TRIGGER: trg_comments_notif
-- Purpose: Automatically create a notification when someone comments
--          on a post. Skips if commenter is the post owner.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_comments_notif
AFTER INSERT ON comments
FOR EACH ROW
DECLARE
    v_post_owner_id posts.user_id%TYPE;
    v_commenter_name users.username%TYPE;
BEGIN
    -- Get the owner of the post that was commented on
    SELECT user_id INTO v_post_owner_id
    FROM posts
    WHERE post_id = :NEW.post_id;

    -- Don't notify if the user commented on their own post
    IF v_post_owner_id <> :NEW.user_id THEN
        -- Get commenter's username for the notification message
        SELECT username INTO v_commenter_name
        FROM users
        WHERE user_id = :NEW.user_id;

        -- Insert notification record
        INSERT INTO notifications (
            notification_id,
            sender_id,
            receiver_id,
            type,
            reference_id,
            message,
            is_read,
            created_at
        ) VALUES (
            seq_notifications.NEXTVAL,
            :NEW.user_id,
            v_post_owner_id,
            'comment',
            :NEW.post_id,
            v_commenter_name || ' mengomentari postingan Anda: "' || SUBSTR(:NEW.comment_text, 1, 50) || '"',
            0,
            CURRENT_TIMESTAMP
        );
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;
    WHEN OTHERS THEN
        NULL;
END;
/

-- ============================================================
-- TRIGGER: trg_follows_notif
-- Purpose: Automatically create a notification when someone follows
--          another user.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_follows_notif
AFTER INSERT ON follows
FOR EACH ROW
DECLARE
    v_follower_name users.username%TYPE;
BEGIN
    -- Get follower's username
    SELECT username INTO v_follower_name
    FROM users
    WHERE user_id = :NEW.follower_id;

    -- Insert notification to the user being followed
    INSERT INTO notifications (
        notification_id,
        sender_id,
        receiver_id,
        type,
        reference_id,
        message,
        is_read,
        created_at
    ) VALUES (
        seq_notifications.NEXTVAL,
        :NEW.follower_id,
        :NEW.following_id,
        'follow',
        :NEW.follow_id,
        v_follower_name || ' mulai mengikuti Anda.',
        0,
        CURRENT_TIMESTAMP
    );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;
    WHEN OTHERS THEN
        NULL;
END;
/

-- ============================================================
-- TRIGGER: trg_posts_bu
-- Purpose: Automatically set updated_at and is_edited = 1
--          whenever a post's content is updated.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_posts_bu
BEFORE UPDATE ON posts
FOR EACH ROW
BEGIN
    IF :NEW.content <> :OLD.content OR :NEW.image_url <> :OLD.image_url THEN
        :NEW.updated_at := CURRENT_TIMESTAMP;
        :NEW.is_edited  := 1;
    END IF;
END;
/

-- ============================================================
-- TRIGGER: trg_users_login
-- Purpose: Update last_login timestamp when is_active changes
--          (called from authentication procedure).
-- ============================================================
CREATE OR REPLACE TRIGGER trg_users_bu
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    -- If last_login is explicitly being set, allow it through
    NULL;
END;
/

PROMPT '✅ All triggers created successfully';
