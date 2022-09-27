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
            
{%- set yaml_metadata -%}
source_model: 'v_stg_orders'
src_pk: 'CUSTOMER_HK'
src_hashdiff:
    source_column: 'CUSTOMER_HASHDIFF'
    alias: 'HASHDIFF'
src_payload:
    - 'CUSTOMER_NAME'
    - 'CUSTOMER_ADDRESS'
    - 'CUSTOMER_PHONE'
src_eff: 'EFFECTIVE_FROM'
src_ldts: 'LOAD_DATE'
src_source: 'RECORD_SOURCE'
{%- endset -%}

{%- set metadata_dict = fromyaml(yaml_metadata) -%}

{{
    dbtvault.sat(
            src_pk=metadata_dict["src_pk"],
            src_hashdiff=metadata_dict["src_hashdiff"],
            src_payload=metadata_dict["src_payload"],
            src_eff=metadata_dict["src_eff"],
            src_ldts=metadata_dict["src_ldts"],
            src_source=metadata_dict["src_source"],
            source_model=metadata_dict["source_model"]
    )
}}