{% set c1_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c1_dev_learning_course_parquet'
) %}
{% set c2_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c2_dev_learning_course_parquet'
) %}
{% set c3_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c3_dev_learning_course_parquet'
) %}
WITH c1_table AS ({% if c1_table_exists %}
SELECT
    idcourse AS item_id, "name", idCategory AS category_id, lang_code, course_type, difficult, "status", create_date, {{ recency_bigint('create_date') }} AS recency, 'c1' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c1_dev_learning_course_parquet') }}
{% else %}
SELECT
    NULL AS item_id, NULL AS "name", NULL AS category_id, NULL AS lang_code, NULL AS course_type, NULL AS difficult, NULL AS "status", NULL AS create_date, NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c2_table AS ({% if c2_table_exists %}
SELECT
    idcourse AS item_id, "name", idCategory AS category_id, lang_code, course_type, difficult, "status", create_date, {{ recency_bigint('create_date') }} AS recency, 'c2' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c2_dev_learning_course_parquet') }}
{% else %}
SELECT
    NULL AS item_id, NULL AS "name", NULL AS category_id, NULL AS lang_code, NULL AS course_type, NULL AS difficult, NULL AS "status", NULL AS create_date, NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c3_table AS ({% if c3_table_exists %}
SELECT
    idcourse AS item_id, "name", idCategory AS category_id, lang_code, course_type, difficult, "status", create_date, {{ recency_bigint('create_date') }} AS recency, 'c3' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c3_dev_learning_course_parquet') }}
{% else %}
SELECT
    NULL AS item_id, NULL AS "name", NULL AS category_id, NULL AS lang_code, NULL AS course_type, NULL AS difficult, NULL AS "status", NULL AS create_date, NULL AS recency, NULL AS customer_name
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
    "name",
    category_id,
    lang_code,
    difficult,
    "status",
    create_date,
    recency,
    customer_name
FROM
    main_source
