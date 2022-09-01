{% set c1_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c1_dev_core_group_members_parquet'
) %}
{% set c2_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c2_dev_core_group_members_parquet'
) %}
{% set c3_table_exists = does_table_exists(
    'recommender_graph_db_dev',
    'c3_dev_core_group_members_parquet'
) %}
WITH c1_table AS ({% if c1_table_exists %}
SELECT
    idst AS group_id, idstMember AS user_id, 'c1' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c1_dev_core_group_members_parquet') }}
{% else %}
SELECT
    NULL AS group_id, NULL AS user_id, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c2_table AS ({% if c2_table_exists %}
SELECT
    idst AS group_id, idstMember AS user_id, 'c2' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c2_dev_core_group_members_parquet') }}
{% else %}
SELECT
    NULL AS group_id, NULL AS user_id, NULL AS customer_name
WHERE
    FALSE
{% endif %}),
c3_table AS ({% if c3_table_exists %}
SELECT
    idst AS group_id, idstMember AS user_id, 'c3' AS customer_name
FROM
    {{ source('recommender_graph_db_dev', 'c3_dev_core_group_members_parquet') }}
{% else %}
SELECT
    NULL AS group_id, NULL AS user_id, NULL AS customer_name
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
    group_id,
    user_id,
    customer_name
FROM
    main_source
