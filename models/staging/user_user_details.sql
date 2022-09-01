{% set c1_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c1_dev_core_user_parquet'
) %}
{% set c2_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c2_dev_core_user_parquet'
) %}
{% set c3_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c3_dev_core_user_parquet'
) %}
WITH c1_table AS ({% if c1_table_exists %}
SELECT
    DISTINCT idst AS user_id, can_manage_subordinates, valid, register_date AS registration_date, {{ recency_varchar('register_date') }} AS recency, 'c1' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c1_dev_core_user_parquet') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS can_manage_subordinates, NULL AS valid, NULL AS registration_date, NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c2_table AS ({% if c1_table_exists %}
SELECT
    DISTINCT idst AS user_id, can_manage_subordinates, valid, register_date AS registration_date, {{ recency_varchar('register_date') }} AS recency, 'c2' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c2_dev_core_user_parquet') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS can_manage_subordinates, NULL AS valid, NULL AS registration_date, NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c3_table AS ({% if c3_table_exists %}
SELECT
    DISTINCT idst AS user_id, can_manage_subordinates, valid, register_date AS registration_date, {{ recency_varchar('register_date') }} AS recency, 'c3' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c3_dev_core_user_parquet') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS can_manage_subordinates, NULL AS valid, NULL AS registration_date, NULL AS recency, NULL AS customer_name
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
)
SELECT
    user_id,
    can_manage_subordinates,
    valid,
    registration_date,
    recency,
    customer_name
FROM
    main_source
WHERE
    registration_date IS NOT NULL
