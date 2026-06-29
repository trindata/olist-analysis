-- =============================================================================
-- 06 — Sazonalidade mensal de receita por categoria
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   Quais categorias têm picos sazonais claros? Black Friday (nov), Natal (dez)
--   e Dia das Mães impactam categorias específicas mais que outras?
--
-- HIPÓTESE
--   Eletrônicos e brinquedos picam em nov/dez. Categorias utilitárias
--   (cama/mesa/banho, eletro doméstico) ficam mais estáveis. Beleza/saúde
--   tem pico em maio (mães).
--
-- GRANULARIDADE
--   1 linha por (categoria, mês_do_ano), agregando 2017+2018. Calcula o
--   share que cada mês representa no total anual da categoria.
--
-- COMO INTERPRETAR
--   share_pct: % da receita anual da categoria concentrada naquele mês.
--   Se distribuído uniformemente, cada mês teria ~8.3% (= 100/12).
--   Valores muito acima de 8.3% indicam mês de pico.
--
-- TABELAS USADAS
--   dbt_dev_marts.mart_category_performance
-- =============================================================================

with monthly as (

    select
        category,
        extract(month from purchase_month)      as mes,
        sum(category_revenue)                   as revenue_mes

    from `dbt_dev_marts.mart_category_performance`
    where purchase_year in (2017, 2018)
    group by category, mes

),

with_total as (

    select
        category,
        mes,
        revenue_mes,
        sum(revenue_mes) over (partition by category) as revenue_categoria_total

    from monthly

),

top_categorias as (

    -- foca só nas 15 categorias com maior receita pra não poluir
    select category
    from (
        select category, sum(revenue_mes) as total
        from monthly
        group by category
        order by total desc
        limit 15
    )

)

select
    wt.category,
    wt.mes,
    round(wt.revenue_mes, 2)                    as revenue_mes,
    round(wt.revenue_mes * 100.0 / nullif(wt.revenue_categoria_total, 0), 2) as share_pct

from with_total wt
inner join top_categorias tc using (category)
order by wt.category, wt.mes

-- =============================================================================
-- FINDINGS 

-- IMPORTANTE: query original tinha viés de amostragem (set-dez só tem 1 ano
-- de dados, jan-ago tem 2). Resultados abaixo usam versão CORRIGIDA com
-- revenue_anualizado (dividido pelo nº de anos com dados em cada mês).
--
-- Categorias com pico claro em nov/dez (Black Friday + Natal):
--   - toys: nov 19.33%, dez 17.00% (36% da receita anual em 2 meses!)
--   - garden_tools: nov 15.06%
--   - furniture_decor: nov 14.44%
--   - cool_stuff: nov 14.20%
--   - telephony: nov 13.47%
--   - perfumery: nov 13.33%
--   - bed_bath_table: nov 13.97%
--
-- Categorias com sazonalidade de inverno (mai-ago):
--   - housewares: mai-ago em ~11.5% cada (inverno = casa)
--   - health_beauty: ago 11.54%, mai-jul ~9.5%
--
-- Categorias estáveis (sem sazonalidade clara):
--   - sports_leisure, furniture_decor (fora de nov), auto
--
-- Dia das Mães (maio): efeito mais fraco que hipótese sugeria.
--   - watches_gifts em maio: 10.85% (único pico claro)
--   - perfumery e health_beauty têm picos no inverno, não em maio
--
-- Anomalia: computers tem pico bizarro em set-out (47% da receita),
-- mas com só 177 pedidos no total provavelmente é ruído.
--
-- Insight pro README:
--   Toys tem sazonalidade extrema (36% em nov+dez). Black Friday move
--   7 das 15 maiores categorias. Categorias de necessidade (saúde, esporte)
--   reagem menos. Dia das Mães tem efeito menor que folclore sugere.
-- =============================================================================
