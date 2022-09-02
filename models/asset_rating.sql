{% set c1_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c1_dev_app7020_content_rating_parquet'
) %}
{% set c2_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c2_dev_app7020_content_rating_parquet'
) %}
{% set c3_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c3_dev_app7020_content_rating_parquet'
) %}
WITH c1_table AS ({% if c1_table_exists %}
SELECT
    idUser AS user_id, idContent AS item_id, rating, 'c1' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c1_dev_app7020_content_rating_parquet') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS item_id, NULL AS rating, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c2_table AS ({% if c2_table_exists %}
SELECT
    idUser AS user_id, idContent AS item_id, rating, 'c2' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c2_dev_app7020_content_rating_parquet') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS item_id, NULL AS rating, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c3_table AS ({% if c3_table_exists %}
SELECT
    idUser AS user_id, idContent AS item_id, rating, 'c3' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c3_dev_app7020_content_rating_parquet') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS item_id, NULL AS rating, NULL AS customer_name
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
    rating,
    customer_name
FROM
    main_source
