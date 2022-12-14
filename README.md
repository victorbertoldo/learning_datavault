# Aprendendo Data Vault

...
...

___

## dbtvault (lib)

Para começar a utilizar a lib, a primeira coisa a se fazer é obter uma base de dados compativel com a biblioteca. Aqui usarei ``Snowflake``, pois é o ``SQL Flavor`` que mais tem aderencia ao funcionamento geral da biblioteca.

Apos configurar uma conta trial do Snowflake, vamos isolar nosso ambiente utilizando virtualenv. Para instalar o dbt neste ambiente isolado, seguiremos os passos abaixo:

``` shell
virtualenv .venv

pip install dbt-snowflake

pip freeze >> requirements.txt
```

Para utilizar o ambiente isolado posteriormente é só utilizar o comando abaixo:

``` shell
pip install -r requirements.txt
```

Vamos iniciar nosso projeto dbtvault. Primeiro, execute o comando:

``` shell
dbt init <nomedoprojeto>
```
> Aqui forneça as informações que foram pedidas para configurar a conexão do ambiente.

Agora entre na pasta do projeto dbt e rode o seguinte comando, para verificar se sua conexão está ok.

``` shell
cd <pasta_projeto_dbt>
dbt debug
```

Obtendo o retorno positivo, crie o arquivo `packages.yml` na raiz do projeto dbt e deixe ele assim:

``` yml
packages:
  - package: Datavault-UK/dbtvault
    version: 0.9.0
```

Agora rode o seguinte comando, para instalar a lib dbtvault:

``` shell
dbt deps
```

Note que agora seu projeto possui uma pasta chamada `dbt_packages` e dentro dela está a lib.

Agora que temos tudo instalado, temos que configurar algumas coisas no nosso projeto.

### Configurando **``dbt_project.yml``**

Adicionando variaveis ao arquivo:

``` yml
vars:
  load_date: '1992-01-08'
  tpch_size: 10 #1, 10, 100, 1000, 10000
```

### Configurando **``sources.yml``**

``` yml
version: 2

sources:
  - name: tpch_sample
    database: SNOWFLAKE_SAMPLE_DATA
    schema: TPCH_SF{{ var('tpch_size', 10) }}
    tables:
      - name: LINEITEM
      - name: CUSTOMER
      - name: ORDERS
      - name: PARTSUPP
      - name: SUPPLIER
      - name: PART
      - name: NATION
      - name: REGION
```

### Arquitetura da camada stage

```mermaid
flowchart TD
    A[Raw Staging Layer]-->B;
    B[Hashed Staging Layer]-->C[Raw Data - dados existentes];
    B[Hashed Staging Layer]-->D[Hashes - Adição de colunas Metadados];
    B[Hashed Staging Layer]-->E[Constants - Adição de colunas Metadados];
    C[Raw Data - dados existentes]-->F[Raw Vault];
    D[Hashes - Adição de colunas Metadados]-->F[Raw Vault];
    E[Constants - Adição de colunas Metadados]-->F[Raw Vault];
```    

- **Raw Staging Layer** - A camada raw da stage geralmente é apenas uma view que pega os dados brutos da origem da forma que ele vem.

- **Hashed Staging Layer** - Pega os dados da ``Raw stage`` e adiciona metadados referentes ao **Data Vault**, como o ``load date`` e o ``record source``, como novas colunas.

A configuração basica da ``stage`` pode ser feita separando por pastas:

``` shell
models
  |
  -- raw_stage
  |  |
  |  -- raw_orders.sql # view, dados brutos AS-IS
  |
  -- stage
      |
      -- v_stg_orders.sql

```
Para iniciarmos a construção da `Hashed Staging Layer`, vamos começar criando o arquivo citado acima `v_stg_orders.sql`, e vamos adicionar algumas variáveis:

``` sql
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

```

> Aqui nesse exemplo estamos criando uma variavel em formato de yml, apenas com 1 chave-valor, que apenas referenciar a tabela da `Raw Stage`. Depois usamos uma função para transformar o yml em dicionário e passamos o valor para a variavel reservada do **``dbtvault``** (source_model). E no final estamos utilizando a macro stage do **``dbtvault``**. Note que no exemplo acima ainda não criamos as variaveis: ``derived_columns`` e ``hashed_columns``.

Até aqui, da forma que construimos ao rodar o script, o arquivo `v_stg_orders.sql` vai gerar uma view igual à `raw_orders.sql`.

**É importante notar isso, pois a partir daqui começamos a adicionar caracteristicas do Data Vault em nosso modelo.**

Para que nossa `Prime Stage` seja construida da melhor forma iremos adicionar o parametro `derived_columns` no modelo:

``` sql
...
{% set yaml_metadata %}
source_model: raw_orders
derived_columns:
    RECORD_SOURCE: "!TPCH-ORDERS"
    LOAD_DATE: DATEADD(DAY, 30, ORDERDATE)
    EFFECTIVE_FROM: ORDERDATE
{% endset %}
...
```
> - Note que o valor referente ao ``record_source`` possui um "!" no inicio. Esta é uma funcionalidade do dbtvault que diz ao modelo que o valor declarado é uma constante a ser atribuida para todas as linhas do modelo.
> - Como para este dataset não temos um campo de quando o dado foi carregado, estamos simulando que o `load_date` corresponde à 30 dias após a realização do pedido.
> - O parametro `EFFECTIVE_FROM` é utilizado para gerar a data de inicio (``src_start_date``) de um registro de `Effectivity Satellites`.

Após adicionar as colunas derivadas ao yml, não se esqueça de extrair esta informação para a que a variavel `derived_columns` da macro stage extraia as informações para adicionar ao modelo.

``` sql
{% set derived_columns = metadata_dict['derived_columns'] %}
```

Seguindo estes passos, o nosso modelo irá gerar as colunas derivadas em nossa `Prime Stage`.

Agora seguimos para uma das caracteristicas mais importantes do dbtvault que é a geração das chaves com hash. Para isso vamos modificar a nossa variavel yaml, adicionando a sessão de `hashed_columns`:

``` sql
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
```
> Como podemos ver, para gerar o hashdiff é necessário utilizar a chamada `is_hashdiff: true`  e declarar os campos que farão parte desta chave para que nossa `Prime Stage fique completa`.

Não esqueça de declarar a variavel `hashed_columns` logo abaixo:

``` sql
{% set hashed_columns = metadata_dict['hashed_columns'] %}
```

Agora, ao rodar o modelo em questão `v_stg_orders.sql`, temos uma tabela com dados brutos, enriquecida com colunas derivadas e hashs, ajudarão na gestão do data vault e na geração dos objetos.

## Iniciando nosso Raw Vault
Primeiramente criaremos uma pasta chamada raw_vault e ela terá a seguinte estrutura:
``` shell
models
  |
  -- raw_vault
     |
     -- hubs
     |
     -- links
     |
     -- satellites
```
Com a estrutura acima definida, criaremos os objetos em suas respectivas pastas.
### Hubs
Vamos criar nosso primeiro Hub, `hub_customer.sql`, apos a criação do arquivo dentro da pasta hub, vamos configurar as variaveis necessarias para obter nosso hub.

Conforme a documentação do **``dbtvault``**, a chamada da macro de geração de hubs, se dá da seguinte maneira:

``` sql
{{ dbtvault.hub(src_pk=src_pk, src_nk=src_nk, src_ldts=src_ldts,
                src_source=src_source, source_model=source_model) }}
```

Para obtermos os valores necessários para tal, vamos iniciar algumas variaveis antes:

``` sql
{{ config(materialized='incremental') }}

{% set source_model = "v_stg_orders" %}
{% set src_pk = "CUSTOMER_PK" %}
{% set src_nk = "CUSTOMERKEY" %}
{% set src_ldts = "LOAD_DATE" %}
{% set src_source = "RECORD_SOURCE" %}
```
> É importante que o modelo seja definido como incremental e que as variaveis sejam criadas associando cada valor ao dado referente. Não é necessário chamar a tabela para pegar as colunas, definindo o ``source_model``, o dbtvault consegue fazer isso automaticamente.

Logo abaixo do codigo acima, é que chamamos a macro hub para gerar nossa tabela.

### Links

O codigo de geração dos links é muito similar ao codigo de geração dos ``Hubs``.

Precisamos atender o que é dito na documentação:

``` sql
{{ dbtvault.link(src_pk=src_pk, src_fk=src_fk, src_ldts=src_ldts,
                src_source=src_source, source_model=source_model) }}
```
Se atente que a principal diferença dos links para os hubs é o uso da variavel `src_fk`. Qua aqui possui esta notação de fk, justamente por seu papel de foreign key na modelagem dos links.

O links também são incrementais, então o código para atribuir as variaveis funciona assim:

``` sql
{{ config(materialized='incremental') }}

{% set source_model = "v_stg_orders" %}
{% set src_pk = "ORDER_CUSTOMER_PK" %}
{% set src_fk = ["CUSTOMER_PK", "ORDER_PK"] %}
{% set src_ldts = "LOAD_DATE" %}
{% set src_source = "RECORD_SOURCE" %}
```





Para criar a fk antes de rodar o modelo:
``` sql
ALTER TABLE dw.data_vault.sat_order_details 
ADD FOREIGN KEY(order_hk) 
REFERENCES dw.data_vault.hub_order 
MATCH FULL 
ON UPDATE NO ACTION 
ON DELETE NO ACTION
```