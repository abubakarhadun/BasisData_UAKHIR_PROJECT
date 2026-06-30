-- ============================================================
-- SOCIAVERSE - Simple Social Media Platform
-- File: functions.sql
-- Description: Oracle Functions for computed/read-only logic
-- ============================================================

-- ============================================================
-- FUNCTION: get_follower_count
-- Purpose : Returns the number of followers for a given user
-- Returns : NUMBER (count of followers)
-- ============================================================
CREATE OR REPLACE FUNCTION get_follower_count (
    p_user_id IN users.user_id%TYPE
) RETURN NUMBER AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM follows
    WHERE following_id = p_user_id;

    RETURN v_count;

EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END get_follower_count;
/

-- ============================================================
-- FUNCTION: get_following_count
-- Purpose : Returns the number of users a given user is following
-- Returns : NUMBER
-- ============================================================
CREATE OR REPLACE FUNCTION get_following_count (
    p_user_id IN users.user_id%TYPE
) RETURN NUMBER AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM follows
    WHERE follower_id = p_user_id;

    RETURN v_count;

EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END get_following_count;
/

-- ============================================================
-- FUNCTION: get_post_engagement
-- Purpose : Calculates total engagement (likes + comments) for a post
-- Returns : NUMBER (combined engagement count)
-- ============================================================
CREATE OR REPLACE FUNCTION get_post_engagement (
    p_post_id IN posts.post_id%TYPE
) RETURN NUMBER AS
    v_like_count    NUMBER;
    v_comment_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_like_count
    FROM likes WHERE post_id = p_post_id;

    SELECT COUNT(*) INTO v_comment_count
    FROM comments WHERE post_id = p_post_id;

    RETURN v_like_count + v_comment_count;

EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END get_post_engagement;
/

-- ============================================================
-- FUNCTION: get_unread_notification_count
-- Purpose : Returns unread notification count for a user
-- Returns : NUMBER
-- ============================================================
CREATE OR REPLACE FUNCTION get_unread_notification_count (
    p_user_id IN users.user_id%TYPE
) RETURN NUMBER AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM notifications
    WHERE receiver_id = p_user_id AND is_read = 0;

    RETURN v_count;

EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END get_unread_notification_count;
/

PROMPT '✅ All functions created successfully';
