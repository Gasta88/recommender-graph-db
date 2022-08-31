{% set c1_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c1_dev_app7020_content_history'
) %}
{% set c2_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c2_dev_app7020_content_history'
) %}
{% set c3_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c3_dev_app7020_content_history'
) %}
WITH c1_table AS ({% if c1_table_exists %}
SELECT
    idUser AS user_id, idContent AS item_id, viewed AS "timestamp", {{ recency_bigint('viewed') }} AS recency, 'c1' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c1_dev_app7020_content_history') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS item_id, NULL AS "timestamp", NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c2_table AS ({% if c2_table_exists %}
SELECT
    idUser AS user_id, idContent AS item_id, viewed AS "timestamp", {{ recency_bigint('viewed') }} AS recency, 'c2' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c2_dev_app7020_content_history') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS item_id, NULL AS "timestamp", NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c3_table AS ({% if c3_table_exists %}
SELECT
    idUser AS user_id, idContent AS item_id, viewed AS "timestamp", {{ recency_bigint('viewed') }} AS recency, 'c3' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c3_dev_app7020_content_history') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS item_id, NULL AS "timestamp", NULL AS recency, NULL AS customer_name
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
    item_id,
    "timestamp",
    recency,
    customer_name
FROM
    main_source
WHERE
    user_id IN (
        SELECT
            user_id
        FROM
            main_source
        GROUP BY
            user_id
        HAVING
            COUNT(*) > 1
    )
