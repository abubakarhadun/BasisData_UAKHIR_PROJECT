-- ============================================================
-- SOCIAVERSE - Simple Social Media Platform
-- File: sequences.sql
-- Description: Oracle Sequences for all primary key auto-increment
-- ============================================================

-- Drop existing sequences
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_users'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_posts'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_comments'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_likes'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_follows'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_notifications'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_reports'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- SEQUENCE: seq_users
-- Used by: USERS table, user_id column
-- ============================================================
CREATE SEQUENCE seq_users
    START WITH 1
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    NOCACHE;

-- ============================================================
-- SEQUENCE: seq_posts
-- Used by: POSTS table, post_id column
-- ============================================================
CREATE SEQUENCE seq_posts
    START WITH 1
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    NOCACHE;

-- ============================================================
-- SEQUENCE: seq_comments
-- Used by: COMMENTS table, comment_id column
-- ============================================================
CREATE SEQUENCE seq_comments
    START WITH 1
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    NOCACHE;

-- ============================================================
-- SEQUENCE: seq_likes
-- Used by: LIKES table, like_id column
-- ============================================================
CREATE SEQUENCE seq_likes
    START WITH 1
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    NOCACHE;

-- ============================================================
-- SEQUENCE: seq_follows
-- Used by: FOLLOWS table, follow_id column
-- ============================================================
CREATE SEQUENCE seq_follows
    START WITH 1
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    NOCACHE;

-- ============================================================
-- SEQUENCE: seq_notifications
-- Used by: NOTIFICATIONS table, notification_id column
-- ============================================================
CREATE SEQUENCE seq_notifications
    START WITH 1
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    NOCACHE;

-- ============================================================
-- SEQUENCE: seq_reports
-- Used by: POST_REPORTS table, report_id column
-- ============================================================
CREATE SEQUENCE seq_reports
    START WITH 1
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE
    NOCACHE;

COMMIT;

PROMPT '✅ Sequences created successfully';
