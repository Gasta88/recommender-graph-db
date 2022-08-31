{% macro recency_varchar(column_name) %}
    CASE
        WHEN CAST(to_unixtime(now()) AS INTEGER) - CAST(
            (
                to_unixtime(date_parse({{ column_name }}, '%Y-%m-%dT%T.%fZ')) / 1000
            ) AS INTEGER
        ) < 604800 THEN 9
        WHEN CAST(to_unixtime(now()) AS INTEGER) - CAST(
            (
                to_unixtime(date_parse({{ column_name }}, '%Y-%m-%dT%T.%fZ')) / 1000
            ) AS INTEGER
        ) BETWEEN 604800
        AND 1209600 THEN 8
        WHEN CAST(to_unixtime(now()) AS INTEGER) - CAST(
            (
                to_unixtime(date_parse({{ column_name }}, '%Y-%m-%dT%T.%fZ')) / 1000
            ) AS INTEGER
        ) BETWEEN 1209600
        AND 2419200 THEN 7
        WHEN CAST(to_unixtime(now()) AS INTEGER) - CAST(
            (
                to_unixtime(date_parse({{ column_name }}, '%Y-%m-%dT%T.%fZ')) / 1000
            ) AS INTEGER
        ) BETWEEN 2419200
        AND 4838400 THEN 6
        WHEN CAST(to_unixtime(now()) AS INTEGER) - CAST(
            (
                to_unixtime(date_parse({{ column_name }}, '%Y-%m-%dT%T.%fZ')) / 1000
            ) AS INTEGER
        ) BETWEEN 4838400
        AND 9676800 THEN 5
        WHEN CAST(to_unixtime(now()) AS INTEGER) - CAST(
            (
                to_unixtime(date_parse({{ column_name }}, '%Y-%m-%dT%T.%fZ')) / 1000
            ) AS INTEGER
        ) BETWEEN 9676800
        AND 19353600 THEN 4
        WHEN CAST(to_unixtime(now()) AS INTEGER) - CAST(
            (
                to_unixtime(date_parse({{ column_name }}, '%Y-%m-%dT%T.%fZ')) / 1000
            ) AS INTEGER
        ) BETWEEN 19353600
        AND 38707200 THEN 3
        WHEN CAST(to_unixtime(now()) AS INTEGER) - CAST(
            (
                to_unixtime(date_parse({{ column_name }}, '%Y-%m-%dT%T.%fZ')) / 1000
            ) AS INTEGER
        ) BETWEEN 38707200
        AND 77414400 THEN 2
        ELSE 1
    END
{% endmacro %}
