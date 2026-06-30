-- ============================================================
-- SOCIAVERSE - Simple Social Media Platform
-- File: ddl.sql
-- Description: Data Definition Language - All table schemas
-- Author: Database Design Team
-- ============================================================

-- Drop existing tables (in reverse FK order)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE post_reports CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE notifications CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE follows CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE likes CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE comments CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE posts CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE users CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- TABLE: USERS
-- ============================================================
CREATE TABLE users (
    user_id         NUMBER          CONSTRAINT pk_users PRIMARY KEY,
    username        VARCHAR2(50)    CONSTRAINT uq_users_username UNIQUE
                                    CONSTRAINT nn_users_username NOT NULL,
    email           VARCHAR2(100)   CONSTRAINT uq_users_email UNIQUE
                                    CONSTRAINT nn_users_email NOT NULL,
    password        VARCHAR2(255)   CONSTRAINT nn_users_password NOT NULL,
    fullname        VARCHAR2(100)   CONSTRAINT nn_users_fullname NOT NULL,
    bio             VARCHAR2(500),
    profile_picture VARCHAR2(300)   DEFAULT 'uploads/default_avatar.png',
    role            VARCHAR2(10)    DEFAULT 'user'
                                    CONSTRAINT chk_users_role CHECK (role IN ('user', 'admin')),
    is_active       NUMBER(1)       DEFAULT 1
                                    CONSTRAINT chk_users_active CHECK (is_active IN (0, 1)),
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    last_login      TIMESTAMP
);

COMMENT ON TABLE users IS 'Stores all registered users of the platform';
COMMENT ON COLUMN users.role IS 'user = regular user, admin = platform administrator';
COMMENT ON COLUMN users.is_active IS '1 = active, 0 = banned by admin';

-- ============================================================
-- TABLE: POSTS
-- ============================================================
CREATE TABLE posts (
    post_id     NUMBER          CONSTRAINT pk_posts PRIMARY KEY,
    user_id     NUMBER          CONSTRAINT nn_posts_user_id NOT NULL
                                CONSTRAINT fk_posts_users REFERENCES users(user_id) ON DELETE CASCADE,
    content     VARCHAR2(2000)  CONSTRAINT nn_posts_content NOT NULL,
    image_url   VARCHAR2(300),
    created_at  TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP,
    is_edited   NUMBER(1)       DEFAULT 0
                                CONSTRAINT chk_posts_edited CHECK (is_edited IN (0, 1))
);

COMMENT ON TABLE posts IS 'Stores all posts created by users';
COMMENT ON COLUMN posts.is_edited IS '1 = post has been edited, 0 = original';

-- ============================================================
-- TABLE: COMMENTS
-- ============================================================
CREATE TABLE comments (
    comment_id      NUMBER          CONSTRAINT pk_comments PRIMARY KEY,
    post_id         NUMBER          CONSTRAINT nn_comments_post_id NOT NULL
                                    CONSTRAINT fk_comments_posts REFERENCES posts(post_id) ON DELETE CASCADE,
    user_id         NUMBER          CONSTRAINT nn_comments_user_id NOT NULL
                                    CONSTRAINT fk_comments_users REFERENCES users(user_id) ON DELETE CASCADE,
    comment_text    VARCHAR2(1000)  CONSTRAINT nn_comments_text NOT NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE comments IS 'Stores all comments on posts';

-- ============================================================
-- TABLE: LIKES
-- ============================================================
CREATE TABLE likes (
    like_id     NUMBER      CONSTRAINT pk_likes PRIMARY KEY,
    post_id     NUMBER      CONSTRAINT nn_likes_post_id NOT NULL
                            CONSTRAINT fk_likes_posts REFERENCES posts(post_id) ON DELETE CASCADE,
    user_id     NUMBER      CONSTRAINT nn_likes_user_id NOT NULL
                            CONSTRAINT fk_likes_users REFERENCES users(user_id) ON DELETE CASCADE,
    created_at  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_likes UNIQUE (user_id, post_id)
);

COMMENT ON TABLE likes IS 'Tracks which users liked which posts. One like per user per post enforced.';

-- ============================================================
-- TABLE: FOLLOWS
-- ============================================================
CREATE TABLE follows (
    follow_id       NUMBER      CONSTRAINT pk_follows PRIMARY KEY,
    follower_id     NUMBER      CONSTRAINT nn_follows_follower NOT NULL
                                CONSTRAINT fk_follows_follower REFERENCES users(user_id) ON DELETE CASCADE,
    following_id    NUMBER      CONSTRAINT nn_follows_following NOT NULL
                                CONSTRAINT fk_follows_following REFERENCES users(user_id) ON DELETE CASCADE,
    created_at      TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_follows UNIQUE (follower_id, following_id),
    CONSTRAINT chk_follows_self CHECK (follower_id <> following_id)
);

COMMENT ON TABLE follows IS 'Tracks follow relationships between users. Self-follow not allowed.';

-- ============================================================
-- TABLE: NOTIFICATIONS
-- ============================================================
CREATE TABLE notifications (
    notification_id NUMBER          CONSTRAINT pk_notifications PRIMARY KEY,
    sender_id       NUMBER          CONSTRAINT fk_notif_sender REFERENCES users(user_id) ON DELETE CASCADE,
    receiver_id     NUMBER          CONSTRAINT nn_notif_receiver NOT NULL
                                    CONSTRAINT fk_notif_receiver REFERENCES users(user_id) ON DELETE CASCADE,
    type            VARCHAR2(20)    CONSTRAINT nn_notif_type NOT NULL
                                    CONSTRAINT chk_notif_type CHECK (type IN ('like', 'comment', 'follow')),
    reference_id    NUMBER,
    message         VARCHAR2(300)   CONSTRAINT nn_notif_message NOT NULL,
    is_read         NUMBER(1)       DEFAULT 0
                                    CONSTRAINT chk_notif_read CHECK (is_read IN (0, 1)),
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE notifications IS 'System-generated notifications for user activity';
COMMENT ON COLUMN notifications.reference_id IS 'FK to the related entity (post_id, follow_id, etc.)';

-- ============================================================
-- TABLE: POST_REPORTS
-- ============================================================
CREATE TABLE post_reports (
    report_id   NUMBER          CONSTRAINT pk_reports PRIMARY KEY,
    post_id     NUMBER          CONSTRAINT nn_reports_post_id NOT NULL
                                CONSTRAINT fk_reports_posts REFERENCES posts(post_id) ON DELETE CASCADE,
    reporter_id NUMBER          CONSTRAINT nn_reports_reporter NOT NULL
                                CONSTRAINT fk_reports_users REFERENCES users(user_id) ON DELETE CASCADE,
    reason      VARCHAR2(500)   CONSTRAINT nn_reports_reason NOT NULL,
    status      VARCHAR2(20)    DEFAULT 'pending'
                                CONSTRAINT chk_reports_status CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    created_at  TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE post_reports IS 'Tracks user-submitted reports about posts for admin review';

-- Indexes for performance
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_likes_post_id ON likes(post_id);
CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);
CREATE INDEX idx_notif_receiver ON notifications(receiver_id, is_read);
CREATE INDEX idx_reports_status ON post_reports(status);

COMMIT;

PROMPT '✅ DDL completed successfully - All tables created';
