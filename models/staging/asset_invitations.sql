{% set c1_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c1_dev_app7020_invitations_parquet'
) %}
{% set c2_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c2_dev_app7020_invitations_parquet'
) %}
{% set c3_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c3_dev_app7020_invitations_parquet'
) %}
WITH c1_table AS ({% if c1_table_exists %}
SELECT
    idContent AS content_id, idInvited AS invited_id, idInviter AS inviter_id, created, created, {{ recency_bigint('created') }} AS recency, 'c1' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c1_dev_app7020_invitations_parquet') }}
{% else %}
SELECT
    NULL AS content_id, NULL AS invited_id, NULL AS inviter_id, NULL AS created, NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c2_table AS ({% if c2_table_exists %}
SELECT
    idContent AS content_id, idInvited AS invited_id, idInviter AS inviter_id, created, {{ recency_bigint('created') }} AS recency, 'c2' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c2_dev_app7020_invitations_parquet') }}
{% else %}
SELECT
    NULL AS content_id, NULL AS invited_id, NULL AS inviter_id, NULL AS created, NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c3_table AS ({% if c3_table_exists %}
SELECT
    idContent AS content_id, idInvited AS invited_id, idInviter AS inviter_id, created, {{ recency_bigint('created') }} AS recency, 'c3' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c3_dev_app7020_invitations_parquet') }}
{% else %}
SELECT
    NULL AS content_id, NULL AS invited_id, NULL AS inviter_id, NULL AS created, NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
main_source AS (
    (
        SELECT
            *
        FROM
            c1_table
    )
    UNION
        (
            SELECT
                *
            FROM
                c2_table
        )
    UNION
        (
            SELECT
                *
            FROM
                c3_table
        )
),
inviters AS (
    SELECT
        inviter_id AS user_id,
        content_id AS item_id,
        created AS "timestamp",
        'is_inviting' AS "type",
        1 AS "priority",
        recency,
        customer_name
    FROM
        main_source
),
invited AS (
    SELECT
        invited_id AS user_id,
        content_id AS item_id,
        created AS "timestamp",
        'is_invited' AS "type",
        1 AS "priority",
        recency,
        customer_name
    FROM
        main_source
),
full_invitation AS (
    (
        SELECT
            user_id,
            item_id,
            "timestamp",
            "type",
            "priority",
            recency,
            customer_name
        FROM
            inviters
    )
    UNION
        (
            SELECT
                user_id,
                item_id,
                "timestamp",
                "type",
                "priority",
                recency,
                customer_name
            FROM
                invited
        )
)
SELECT
    *
FROM
    full_invitation
