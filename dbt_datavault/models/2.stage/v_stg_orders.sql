{{ 
    config(
    materialized='view'
    )
}}

{% set yaml_metadata %}
source_model: raw_orders
derived_columns:
    CUSTOMER_KEY: "CUSTOMERKEY"
    NATION_KEY: "CUSTOMER_NATION_KEY"
    REGION_KEY: "CUSTOMER_REGION_KEY"
    RECORD_SOURCE: "!TPCH-ORDERS"
    LOAD_DATE: DATEADD(DAY, 30, ORDERDATE)
    EFFECTIVE_FROM: ORDERDATE
    START_DATE: ORDERDATE
    END_DATE: TO_DATE('9999-12-31')
hashed_columns:
    CUSTOMER_HK: CUSTOMERKEY
    LINK_CUSTOMER_NATION_HK:
        - "CUSTOMER_KEY"
        - "CUSTOMER_NATION_KEY"
    CUSTOMER_NATION_HK: "CUSTOMER_NATION_KEY"
    NATION_HK: "CUSTOMER_NATION_KEY"
    ORDER_HK: ORDERKEY
    ORDER_CUSTOMER_HK:
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
    ORDER_HASHDIFF:
        is_hashdiff: true
        columns:
            - 'ORDERKEY'
            - 'CLERK'
            - 'ORDERDATE'
            - 'ORDERPRIORITY'
            - 'ORDERSTATUS'
            - 'ORDER_COMMENT'
            - 'SHIPPRIORITY'
            - 'TOTALPRICE'


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
