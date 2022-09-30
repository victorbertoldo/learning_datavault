{{ config(materialized='incremental',
            post_hook=['''ALTER TABLE {{ this }} 
                        DROP PRIMARY KEY''',
                'ALTER TABLE {{ this }} ADD CONSTRAINT pk_{{ this.identifier }} PRIMARY KEY ({{ (this.identifier).split("_")[-1] }}_hk)'],
            re_data_monitored=true,
            re_data_time_filter='LOAD_DATE'
            ) }}

{% set source_model = "v_stg_orders" %}
{% set src_pk = "CUSTOMER_HK" %}
{% set src_nk = "CUSTOMERKEY" %}
{% set src_ldts = "LOAD_DATE" %}
{% set src_source = "RECORD_SOURCE" %}

{{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                src_source=src_source, source_model=source_model) }}
