{% set c1_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c1_dev_app7020_content_parquet'
) %}
{% set c2_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c2_dev_app7020_content_parquet'
) %}
{% set c3_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c3_dev_app7020_content_parquet'
) %}
WITH c1_table AS ({% if c1_table_exists %}
SELECT
    DISTINCT id AS item_id, created AS creation_date, contentType AS content_type, {{ recency_bigint('created') }} AS recency, 'c1' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c1_dev_app7020_content_parquet') }}
{% else %}
SELECT
    NULL AS item_id, NULL AS creation_date, NULL AS content_type, NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c2_table AS ({% if c2_table_exists %}
SELECT
    DISTINCT id AS item_id, created AS creation_date, contentType AS content_type, {{ recency_bigint('created') }} AS recency, 'c2' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c2_dev_app7020_content_parquet') }}
{% else %}
SELECT
    NULL AS item_id, NULL AS creation_date, NULL AS content_type, NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c3_table AS ({% if c3_table_exists %}
SELECT
    DISTINCT id AS item_id, created AS creation_date, contentType AS content_type, {{ recency_bigint('created') }} AS recency, 'c3' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c3_dev_app7020_content_parquet') }}
{% else %}
SELECT
    NULL AS item_id, NULL AS creation_date, NULL AS content_type, NULL AS recency, NULL AS customer_name
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
    item_id,
    creation_date,
    content_type,
    recency,
    customer_name
FROM
    main_source
WHERE
    content_type IS NOT NULL
