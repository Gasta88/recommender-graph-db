{% set c1_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c1_dev_learning_coursepath_courses'
) %}
{% set c2_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c2_dev_learning_coursepath_courses'
) %}
{% set c3_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c3_dev_learning_coursepath_courses'
) %}
WITH c1_table AS ({% if c1_table_exists %}
SELECT
    id_item AS item_id, id_path, 'c1' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c1_dev_learning_coursepath_courses') }}
{% else %}
SELECT
    NULL AS item_id, NULL AS id_path, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c2_table AS ({% if c2_table_exists %}
SELECT
    id_item AS item_id, id_path, 'c2' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c2_dev_learning_coursepath_courses') }}
{% else %}
SELECT
    NULL AS item_id, NULL AS id_path, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c3_table AS ({% if c3_table_exists %}
SELECT
    id_item AS item_id, id_path, 'c3' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c3_dev_learning_coursepath_courses') }}
{% else %}
SELECT
    NULL AS item_id, NULL AS id_path, NULL AS customer_name
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
    id_path AS path_id,
    customer_name
FROM
    main_source
