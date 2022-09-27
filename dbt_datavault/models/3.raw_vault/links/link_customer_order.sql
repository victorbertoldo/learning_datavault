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

{% set source_model = "v_stg_orders" %}
{% set src_pk = "ORDER_CUSTOMER_HK" %}
{% set src_fk = ["CUSTOMER_HK", "ORDER_HK"] %}
{% set src_ldts = "LOAD_DATE" %}
{% set src_source = "RECORD_SOURCE" %}


{{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                src_source=src_source, source_model=source_model) }}