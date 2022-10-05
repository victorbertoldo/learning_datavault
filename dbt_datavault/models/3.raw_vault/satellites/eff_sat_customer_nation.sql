{{ 
    config(
        materialized='table',
        post_hook=['''ALTER TABLE {{ this }} DROP FOREIGN KEY ({{ (this.identifier).split("_")[2] }}_hk)''',
        '''ALTER TABLE {{ this }} 
                    ADD FOREIGN KEY({{ (this.identifier).split("_")[2] }}_hk) 
                    REFERENCES {{ this.database }}.{{ this.schema }}.hub_{{ (this.identifier).split("_")[2] }} 
                    MATCH FULL 
                    ON UPDATE NO ACTION 
                    ON DELETE NO ACTION'''],
        re_data_monitored=true,
        re_data_time_filter='START_DATE'
        ) 
}}
            

{%- set source_model = "v_stg_orders" -%}
{%- set src_pk = "CUSTOMER_NATION_HK" -%}
{%- set src_dfk = "CUSTOMER_HK" -%}
{%- set src_sfk = "NATION_HK" -%}
{%- set src_start_date = "START_DATE" -%}
{%- set src_end_date = "END_DATE" -%}

{%- set src_eff = "EFFECTIVE_FROM" -%}
{%- set src_ldts = "LOAD_DATE" -%}
{%- set src_source = "RECORD_SOURCE" -%}

{{ config(is_auto_end_dating=true) }}

{{ dbtvault.eff_sat(
                    src_pk=src_pk,
                    src_dfk=src_dfk,
                    src_sfk=src_sfk,
                    src_start_date=src_start_date,
                    src_end_date=src_end_date,
                    src_eff=src_eff,
                    src_source=src_source,
                    source_model=source_model
                    )
}}
