{{ config(
    materialized = 'table'
) }}

WITH content_history AS (

    SELECT
        *,
        'interaction' AS "type",
        0 AS "priority"
    FROM
        {{ ref ('course_content_history') }}
),
ratings AS (
    SELECT
        *
    FROM
        {{ ref('course_rating') }}
)
SELECT
    content_history.user_id,
    content_history.item_id,
    content_history.timestamp,
    content_history.recency,
    ratings.rating,
    content_history.type,
    content_history.priority
FROM
    content_history
    LEFT JOIN ratings
    ON content_history.user_id = ratings.user_id
    AND content_history.item_id = ratings.item_id
