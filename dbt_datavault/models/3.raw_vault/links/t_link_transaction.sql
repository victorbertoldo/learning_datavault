{{ 
    config(
        materialized='incremental',
        post_hook=['''ALTER TABLE {{ this }} DROP FOREIGN KEY (customer_hk)''',
        '''ALTER TABLE {{ this }} 
                    ADD FOREIGN KEY(customer_hk) 
                    REFERENCES {{ this.database }}.{{ this.schema }}.hub_customer 
                    MATCH FULL 
                    ON UPDATE NO ACTION 
                    ON DELETE NO ACTION''']
            ) }}

{%- set yaml_metadata -%}
source_model: 'v_stg_transactions'
src_pk: 'TRANSACTION_HK'
src_fk:
    - 'CUSTOMER_HK'
    - 'ORDER_HK'
src_payload:
    - 'TRANSACTION_NUMBER'
    - 'TRANSACTION_DATE'
    - 'TYPE'
    - 'AMOUNT'
src_eff: 'EFFECTIVE_FROM'
src_ldts: 'LOAD_DATE'
src_source: 'RECORD_SOURCE'
{%- endset -%}

{%- set metadata_dict = fromyaml(yaml_metadata) -%}

{{ dbtvault.t_link(
            src_pk=metadata_dict["src_pk"],
            src_fk=metadata_dict["src_fk"],
            src_payload=metadata_dict["src_payload"],
            src_eff=metadata_dict["src_eff"],
            src_ldts=metadata_dict["src_ldts"],
            src_source=metadata_dict["src_source"],
            source_model=metadata_dict["source_model"])
}}