{{ 
    config(
    materialized='view'
    )
}}

{% set yaml_metadata %}
source_model: raw_orders
derived_columns:
    RECORD_SOURCE: "!TPCH-ORDERS"
    LOAD_DATE: DATEADD(DAY, 30, ORDERDATE)
    EFFECTIVE_FROM: ORDERDATE
hashed_columns:
    CUSTOMER_PK: CUSTOMERKEY
    ORDER_PK: ORDERKEY
    ORDER_CUSTOMER_PK:
        - CUSTOMERKEY
        - ORDERKEY
    CUSTOMER_HASHDIFF:
        is_hashdiff: true
        columns:
            - CUSTOMERKEY
            - CUSTOMER_NAME
            - CUSTOMER_ADDRESS
            - CUSTOMER_PHONE
            - CUSTOMER_ACCBAL
            - CUSTOMER_MKTSEGMENT
            - CUSTOMER_COMMENT
            - EFFECTIVE_FROM


{% endset %}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict['source_model'] %}
{% set derived_columns = metadata_dict['derived_columns'] %}
{% set hashed_columns = metadata_dict['hashed_columns'] %}


{{ dbtvault.stage(
                include_source_columns=true,
                source_model=source_model,
                derived_columns=derived_columns,
                hashed_columns=hashed_columns)
                }}
