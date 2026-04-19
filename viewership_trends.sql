- ============================================================
-- 1. USER LEVEL SUMMARY (One row per user - safe for pivoting)
-- ============================================================
SELECT 
    v.UserID0                                       AS user_id,
    COALESCE(TRIM(u.GENDER), 'Unknown')             AS gender,
    COALESCE(TRIM(u.RACE), 'Unknown')               AS race,
    COALESCE(TRIM(u.PROVINCE), 'Unknown')           AS province,
    INITCAP(TRIM(u.NAME))                           AS name,
    INITCAP(TRIM(u.SURNAME))                        AS surname,
    u.AGE,
    CASE 
        WHEN u.AGE IS NULL      THEN 'Unknown'
        WHEN u.AGE < 13         THEN 'Child'
        WHEN u.AGE < 18         THEN 'Teen'
        WHEN u.AGE < 35         THEN 'Youth'
        WHEN u.AGE < 50         THEN 'Adult'
        WHEN u.AGE < 65         THEN 'Middle Aged'
        WHEN u.AGE >= 65        THEN 'Retired'
        ELSE 'Other'
    END                                             AS age_group,
    COUNT(v.UserID0)                                AS total_views,
    COUNT(DISTINCT v.CHANNEL2)                      AS channels_watched,
    ROUND(SUM(v.`DURATION 2`) / 60, 2)             AS total_watch_hours,
    -- Most common viewing slot per user
    CASE 
        WHEN HOUR(MAX(v.RECORDDATE2 + INTERVAL 2 HOURS)) BETWEEN 5  AND 11 THEN 'Morning Viewing'
        WHEN HOUR(MAX(v.RECORDDATE2 + INTERVAL 2 HOURS)) BETWEEN 12 AND 17 THEN 'Afternoon Viewing'
        WHEN HOUR(MAX(v.RECORDDATE2 + INTERVAL 2 HOURS)) BETWEEN 18 AND 23 THEN 'Evening Viewing'
        ELSE 'Midnight Viewing'
    END                                             AS last_viewing_slot
FROM workspace.default.viewship v
LEFT JOIN workspace.default.user_profile u
    ON v.UserID0 = u.USERID
GROUP BY 
    v.UserID0,
    COALESCE(TRIM(u.GENDER), 'Unknown'),
    COALESCE(TRIM(u.RACE), 'Unknown'),
    COALESCE(TRIM(u.PROVINCE), 'Unknown'),
    INITCAP(TRIM(u.NAME)),
    INITCAP(TRIM(u.SURNAME)),
    u.AGE,
    CASE 
        WHEN u.AGE IS NULL      THEN 'Unknown'
        WHEN u.AGE < 13         THEN 'Child'
        WHEN u.AGE < 18         THEN 'Teen'
        WHEN u.AGE < 35         THEN 'Youth'
        WHEN u.AGE < 50         THEN 'Adult'
        WHEN u.AGE < 65         THEN 'Middle Aged'
        WHEN u.AGE >= 65        THEN 'Retired'
        ELSE 'Other'
    END;

-- ============================================================
-- 2. TOTAL DISTINCT VIEWERS
-- ============================================================
SELECT COUNT(DISTINCT v.UserID0) AS total_unique_viewers
FROM workspace.default.viewship v;

-- ============================================================
-- 3. DISTINCT VIEWERS BY PROVINCE
-- ============================================================
SELECT 
    COALESCE(TRIM(u.PROVINCE), 'Unknown') AS province,
    COUNT(DISTINCT v.UserID0) AS total_viewers
FROM workspace.default.viewship v
LEFT JOIN workspace.default.user_profile u
    ON v.UserID0 = u.USERID
GROUP BY COALESCE(TRIM(u.PROVINCE), 'Unknown')
ORDER BY total_viewers DESC;

-- ============================================================
-- 4. MOST WATCHED CHANNELS (DISTINCT VIEWERS)
-- ============================================================
SELECT 
    v.CHANNEL2 AS channel,
    COUNT(DISTINCT v.UserID0) AS total_viewers
FROM workspace.default.viewship v
GROUP BY v.CHANNEL2
ORDER BY total_viewers DESC;

-- ============================================================
-- 5. VIEWERSHIP BY AGE GROUP
-- ============================================================
SELECT 
    age_group,
    COUNT(DISTINCT user_id) AS viewer_count
FROM (
    SELECT 
        v.UserID0 AS user_id,
        CASE 
            WHEN u.AGE IS NULL THEN 'Unknown'
            WHEN u.AGE < 13    THEN 'Child'
            WHEN u.AGE < 18    THEN 'Teen'
            WHEN u.AGE < 35    THEN 'Youth'
            WHEN u.AGE < 50    THEN 'Adult'
            WHEN u.AGE < 65    THEN 'Middle Aged'
            WHEN u.AGE >= 65   THEN 'Retired'
            ELSE 'Other'
        END AS age_group
    FROM workspace.default.viewship v
    LEFT JOIN workspace.default.user_profile u
        ON v.UserID0 = u.USERID
) t
GROUP BY age_group
ORDER BY viewer_count DESC;

-- ============================================================
-- 6. VIEWERSHIP BY TIME SLOT
-- ============================================================
SELECT 
    CASE 
        WHEN HOUR(v.RECORDDATE2 + INTERVAL 2 HOURS) BETWEEN 5  AND 11 THEN 'Morning Viewing'
        WHEN HOUR(v.RECORDDATE2 + INTERVAL 2 HOURS) BETWEEN 12 AND 17 THEN 'Afternoon Viewing'
        WHEN HOUR(v.RECORDDATE2 + INTERVAL 2 HOURS) BETWEEN 18 AND 23 THEN 'Evening Viewing'
        ELSE 'Midnight Viewing'
    END AS viewing_slot,
    COUNT(DISTINCT v.UserID0) AS viewer_count
FROM workspace.default.viewship v
GROUP BY 
    CASE 
        WHEN HOUR(v.RECORDDATE2 + INTERVAL 2 HOURS) BETWEEN 5  AND 11 THEN 'Morning Viewing'
        WHEN HOUR(v.RECORDDATE2 + INTERVAL 2 HOURS) BETWEEN 12 AND 17 THEN 'Afternoon Viewing'
        WHEN HOUR(v.RECORDDATE2 + INTERVAL 2 HOURS) BETWEEN 18 AND 23 THEN 'Evening Viewing'
        ELSE 'Midnight Viewing'
    END
ORDER BY viewer_count DESC;

-- ============================================================
-- 7. VIEWERSHIP BY GENDER AND RACE
-- ============================================================
SELECT 
    COALESCE(TRIM(u.GENDER), 'Unknown') AS gender,
    COALESCE(TRIM(u.RACE), 'Unknown')   AS race,
    COUNT(DISTINCT v.UserID0)           AS viewer_count
FROM workspace.default.viewship v
LEFT JOIN workspace.default.user_profile u
    ON v.UserID0 = u.USERID
GROUP BY 
    COALESCE(TRIM(u.GENDER), 'Unknown'),
    COALESCE(TRIM(u.RACE), 'Unknown')
ORDER BY viewer_count DESC;

-- ============================================================
-- 8. VIEWERSHIP BY DAY OF WEEK
-- ============================================================
SELECT 
    date_format(v.RECORDDATE2 + INTERVAL 2 HOURS, 'EEEE') AS day_name,
    COUNT(DISTINCT v.UserID0) AS viewer_count
FROM workspace.default.viewship v
GROUP BY date_format(v.RECORDDATE2 + INTERVAL 2 HOURS, 'EEEE')
ORDER BY 
    CASE date_format(v.RECORDDATE2 + INTERVAL 2 HOURS, 'EEEE')
        WHEN 'Monday'    THEN 1
        WHEN 'Tuesday'   THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday'  THEN 4
        WHEN 'Friday'    THEN 5
        WHEN 'Saturday'  THEN 6
        WHEN 'Sunday'    THEN 7
    END;
