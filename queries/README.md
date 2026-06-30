# queries/

Coleção de queries de exploração que materializam o raciocínio analítico por trás dos insights do README. Cada arquivo é autocontido: explica a pergunta de negócio, a hipótese inicial, a granularidade do resultado e como interpretar os números.

## Estrutura

- **`operational/`** — análise de entregas, atrasos e prazos. Foca no funil pós-compra.
- **`commercial/`** — receita, categorias, ticket médio, freight ratio. Foca no que vende.
- **`sellers/`** — performance, geografia e distribuição entre vendedores.
- **`customer/`** — cohort, recompra, satisfação por segmento de cliente.

## Como rodar

Todas as queries assumem que o pipeline dbt rodou e que os datasets `dbt_dev_staging`, `dbt_dev_intermediate` e `dbt_dev_marts` existem no projeto BigQuery configurado.

Pra rodar manualmente, copia o conteúdo do `.sql` no BigQuery Studio e executa. Os comentários no início de cada arquivo explicam o resultado esperado.

> Pra promover qualquer dessas queries a um mart permanente, basta copiar o corpo da query principal pra `models/marts/<dominio>/` e adicionar configuração de materialização.

## Por que SQL puro e não `analyses/` do dbt?

A pasta `analyses/` do dbt seria a opção "canônica" — ela permite usar `{{ ref() }}` e dá compile via `dbt compile`. Optei por SQL puro com nomes de tabela explícitos por dois motivos:

1. **Rodável direto no BigQuery Studio** — quem quiser explorar não precisa instalar dbt
2. **Snapshot temporal** — congela o estado do mart no momento da análise; se o mart evoluir, o resultado original continua reproduzível

A trade-off é não ter o lineage automático. Mitigação: cada arquivo declara explicitamente quais tabelas usa no header.

## Findings consolidados

Os insights validados a partir dessas queries estão no `README.md` principal, seção "Principais Insights". Cada insight aponta pra query que o originou.
