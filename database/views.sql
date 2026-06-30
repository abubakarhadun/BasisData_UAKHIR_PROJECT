-- ============================================================
-- SOCIAVERSE - Simple Social Media Platform
-- File: views.sql
-- Description: Oracle Views for reusable, complex queries
-- ============================================================

-- ============================================================
-- VIEW: timeline_view
-- Purpose : Aggregated post data for the main timeline feed.
--           Includes author info, counts of likes and comments.
-- ============================================================
CREATE OR REPLACE VIEW timeline_view AS
SELECT
    p.post_id,
    p.user_id,
    u.username,
    u.fullname,
    u.profile_picture,
    p.content,
    p.image_url,
    p.created_at,
    p.updated_at,
    p.is_edited,
    (SELECT COUNT(*) FROM likes    l WHERE l.post_id = p.post_id) AS like_count,
    (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.post_id) AS comment_count,
    get_post_engagement(p.post_id) AS engagement_count
FROM
    posts p
    JOIN users u ON p.user_id = u.user_id
WHERE
    u.is_active = 1  -- Only show posts from active users
ORDER BY
    p.created_at DESC;

COMMENT ON TABLE timeline_view IS 'Main feed view with post data and engagement stats';

-- ============================================================
-- VIEW: user_profile_view
-- Purpose : Aggregated user profile statistics.
--           Shows total posts, followers, and following counts.
-- ============================================================
CREATE OR REPLACE VIEW user_profile_view AS
SELECT
    u.user_id,
    u.username,
    u.fullname,
    u.email,
    u.bio,
    u.profile_picture,
    u.role,
    u.is_active,
    u.created_at,
    u.last_login,
    (SELECT COUNT(*) FROM posts    p WHERE p.user_id = u.user_id) AS total_posts,
    get_follower_count(u.user_id)   AS total_followers,
    get_following_count(u.user_id)  AS total_following,
    get_unread_notification_count(u.user_id) AS unread_notifications
FROM
    users u;

COMMENT ON TABLE user_profile_view IS 'User profile view with aggregated statistics';

-- ============================================================
-- VIEW: admin_reports_view
-- Purpose : Report management view for the admin dashboard.
--           Includes reporter info and post content.
-- ============================================================
CREATE OR REPLACE VIEW admin_reports_view AS
SELECT
    r.report_id,
    r.status,
    r.reason,
    r.created_at AS reported_at,
    -- Post info
    p.post_id,
    p.content   AS post_content,
    p.image_url AS post_image,
    -- Post owner
    po.user_id   AS post_owner_id,
    po.username  AS post_owner_username,
    -- Reporter info
    rp.user_id   AS reporter_id,
    rp.username  AS reporter_username
FROM
    post_reports r
    JOIN posts  p  ON r.post_id     = p.post_id
    JOIN users  po ON p.user_id     = po.user_id
    JOIN users  rp ON r.reporter_id = rp.user_id
ORDER BY
    CASE r.status WHEN 'pending' THEN 1 WHEN 'reviewed' THEN 2 ELSE 3 END,
    r.created_at DESC;

COMMENT ON TABLE admin_reports_view IS 'Admin view for reviewing and resolving post reports';

-- ============================================================
-- VIEW: notifications_detail_view
-- Purpose : Notifications with sender details for display in UI
-- ============================================================
CREATE OR REPLACE VIEW notifications_detail_view AS
SELECT
    n.notification_id,
    n.receiver_id,
    n.type,
    n.reference_id,
    n.message,
    n.is_read,
    n.created_at,
    -- Sender info
    s.user_id        AS sender_id,
    s.username       AS sender_username,
    s.profile_picture AS sender_avatar
FROM
    notifications n
    LEFT JOIN users s ON n.sender_id = s.user_id
ORDER BY
    n.created_at DESC;

PROMPT '✅ All views created successfully';
