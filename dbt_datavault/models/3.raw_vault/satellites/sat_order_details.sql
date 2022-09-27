{{ 
    config(
        materialized='incremental',
        post_hook=['''ALTER TABLE {{ this }} DROP FOREIGN KEY ({{ (this.identifier).split("_")[1] }}_hk)''',
        '''ALTER TABLE {{ this }} 
                    ADD FOREIGN KEY({{ (this.identifier).split("_")[1] }}_hk) 
                    REFERENCES {{ this.database }}.{{ this.schema }}.hub_{{ (this.identifier).split("_")[1] }} 
                    MATCH FULL 
                    ON UPDATE NO ACTION 
                    ON DELETE NO ACTION''']
            ) }}
            
{%- set source_model = "v_stg_orders" -%}
{%- set src_pk = "ORDER_HK" -%}
{%- set src_hashdiff = "ORDER_HASHDIFF" -%}
{%- set src_payload = ["ORDERSTATUS", "TOTALPRICE", "ORDERDATE", "ORDERPRIORITY",
                       "CLERK", "SHIPPRIORITY", "ORDER_COMMENT"] -%}
{%- set src_eff = "EFFECTIVE_FROM" -%}
{%- set src_ldts = "LOAD_DATE" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ dbtvault.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                src_payload=src_payload, src_eff=src_eff,
                src_ldts=src_ldts, src_source=src_source,
                source_model=source_model) }}