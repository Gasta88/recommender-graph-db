{{ config(
    materialized = 'table'
) }}

WITH content_history AS (

    SELECT
        *,
        'interaction' AS "type",
        0 AS "priority"
    FROM
        {{ ref ('asset_content_history') }}
),
invitations AS (
    SELECT
        *
    FROM
        {{ ref('asset_invitations') }}
),
ratings AS (
    SELECT
        *
    FROM
        {{ ref('asset_rating') }}
) (
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
)
UNION ALL
    (
        SELECT
            user_id,
            item_id,
            "timestamp",
            recency,
            NULL AS rating,
            "type",
            priority
        FROM
            invitations
    )
