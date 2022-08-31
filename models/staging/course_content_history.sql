{% set c1_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c1_dev_learning_courseuser'
) %}
{% set c2_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c2_dev_learning_courseuser'
) %}
{% set c3_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c3_dev_learning_courseuser'
) %}
WITH c1_table AS ({% if c1_table_exists %}
SELECT
    idUser AS user_id, idCourse AS course_id, "status", last_update AS "timestamp", {{ recency_bigint('last_update') }} AS recency, 'c1' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c1_dev_learning_courseuser') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS course_id, NULL AS "status", NULL AS "timestamp", NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c2_table AS ({% if c2_table_exists %}
SELECT
    idUser AS user_id, idCourse AS course_id, "status", last_update AS "timestamp", {{ recency_bigint('last_update') }} AS recency, 'c2' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c2_dev_learning_courseuser') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS course_id, NULL AS "status", NULL AS "timestamp", NULL AS recency, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c3_table AS ({% if c3_table_exists %}
SELECT
    idUser AS user_id, idCourse AS course_id, "status", last_update AS "timestamp", {{ recency_bigint('last_update') }} AS recency, 'c3' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c3_dev_learning_courseuser') }}
{% else %}
SELECT
    NULL AS user_id, NULL AS course_id, NULL AS "status", NULL AS "timestamp", NULL AS recency, NULL AS customer_name
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
    course_id AS item_id,
    "status",
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
