{% set c1_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c1_dev_core_setting_user_parquet'
) %}
{% set c2_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c2_dev_core_setting_user_parquet'
) %}
{% set c3_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c3_dev_core_setting_user_parquet'
) %}
WITH c1_table AS ({% if c1_table_exists %}
SELECT
    id_user AS user_id, path_name, LOWER("value") AS user_language, 'c1' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c1_dev_core_setting_user_parquet') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS path_name, NULL AS user_language, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c2_table AS ({% if c2_table_exists %}
SELECT
    id_user AS user_id, path_name, LOWER("value") AS user_language, 'c2' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c2_dev_core_setting_user_parquet') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS path_name, NULL AS user_language, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c3_table AS ({% if c3_table_exists %}
SELECT
    id_user AS user_id, path_name, LOWER("value") AS user_language, 'c3' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c3_dev_core_setting_user_parquet') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS path_name, NULL AS user_language, NULL AS customer_name
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
    user_language,
    customer_name
FROM
    main_source
WHERE
    path_name = 'ui.language'
