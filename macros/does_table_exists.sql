{% macro does_table_exists(
        source_name,
        table_name
    ) %}
    {%- set source_relation = adapter.get_relation(
        database = source(
            source_name,
            table_name
        ).database,
        schema = source(
            source_name,
            table_name
        ).schema,
        identifier = source(
            source_name,
            table_name
        ).name
    ) -%}
    {{ return(
        source_relation is not none
    ) }}
{% endmacro %}
