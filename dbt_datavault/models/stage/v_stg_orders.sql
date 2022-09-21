{{ 
    config(
    materialized='view'
    )
}}

{% set yaml_metadata %}
source_model: raw_orders
{% endset %}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict['source_model'] %}

{{ dbtvault.stage(
                include_source_columns=true,
                source_model=source_model,
                derived_columns=derived_columns,
                hashed_columns=hashed_columns)
                }}
