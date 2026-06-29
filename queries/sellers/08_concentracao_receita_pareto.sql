-- =============================================================================
-- 08 — Concentração de receita entre sellers (curva de Pareto)
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   Vale a regra 80/20 no Olist? Que % dos sellers concentra que % da receita?
--   E como fica a cauda longa de sellers de baixíssimo volume?
--
-- HIPÓTESE
--   Marketplaces sempre têm distribuição de receita altamente desigual.
--   Espero que ~5-10% dos sellers concentrem 50%+ da receita, e que metade
--   inferior dos sellers represente <5%.
--
-- GRANULARIDADE
--   1 linha por seller, com receita acumulada e percentil. Permite plotar
--   curva de Lorenz / calcular Gini se quiser.
--
-- COMO INTERPRETAR
--   revenue_pct_cumulative: % cumulativo da receita até aquele seller (ranqueando
--   do maior pro menor). Quando chega a 80%, o quantos_sellers_pct indica
--   que fração dos sellers foi suficiente pra cobrir 80% da receita.
--
-- TABELAS USADAS
--   dbt_dev_marts.mart_seller_performance
-- =============================================================================

with ranked as (

    select
        seller_id,
        seller_state,
        seller_revenue,
        total_orders,
        row_number() over (order by seller_revenue desc) as rank_revenue,
        count(*)        over ()                          as total_sellers,
        sum(seller_revenue) over ()                      as total_revenue

    from `dbt_dev_marts.mart_seller_performance`

),

cumulative as (

    select
        seller_id,
        seller_state,
        seller_revenue,
        total_orders,
        rank_revenue,
        total_sellers,
        round(rank_revenue * 100.0 / total_sellers, 2) as seller_pct,
        round(
            sum(seller_revenue) over (order by rank_revenue) * 100.0 / total_revenue
        , 2) as revenue_pct_cumulative

    from ranked

)

-- pontos de corte clássicos: top 1%, 5%, 10%, 20%, 50%
select
    'top 1%'  as faixa, max(revenue_pct_cumulative) as receita_acumulada_pct,
    count(*) as qtd_sellers
from cumulative where seller_pct <= 1

union all
select 'top 5%',  max(revenue_pct_cumulative), count(*) from cumulative where seller_pct <= 5
union all
select 'top 10%', max(revenue_pct_cumulative), count(*) from cumulative where seller_pct <= 10
union all
select 'top 20%', max(revenue_pct_cumulative), count(*) from cumulative where seller_pct <= 20
union all
select 'top 50%', max(revenue_pct_cumulative), count(*) from cumulative where seller_pct <= 50
union all
select 'top 100%', max(revenue_pct_cumulative), count(*) from cumulative

order by qtd_sellers

-- =============================================================================
-- FINDINGS
--
-- Top 1% (29 sellers) concentra 25,51% da receita
-- Top 5% (148 sellers) concentra 52,94% — passa metade
-- Top 10% (297 sellers) concentra 67,11% — 2/3
-- Top 20% (594 sellers) concentra 82,29% — Pareto 80/20 confirmado
-- Top 50% (1.485 sellers) concentra 96,69%
-- Metade inferior (1.485 sellers) = 3,31% da receita
--
-- A regra 80/20 se confirma? SIM, com precisão quase cirúrgica.
--
-- Insight pro README:
--   Concentração de Pareto quase exata: top 20% dos sellers = 82% da receita.
--   29 sellers do top 1% (25% da receita) movem mais dinheiro que os 1.485
--   da metade inferior. Olist tem assinatura clássica de marketplace.
-- =============================================================================
