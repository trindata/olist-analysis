-- =============================================================================
-- 10 — Recompra por cohort mensal (retenção do Olist)
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   Qual é a taxa de recompra do Olist? Clientes que compraram em 2017 voltam?
--   Existe melhora/piora de retenção ao longo dos cohorts de aquisição?
--
-- HIPÓTESE
--   Marketplace tem retenção naturalmente baixa (cliente compra por preço,
--   não por marca). Espero que <10% dos clientes voltem. Mas alguns cohorts
--   podem ter retenção melhor se foram captados por campanhas específicas.
--
-- GRANULARIDADE
--   1 linha por cohort (mês da primeira compra do cliente). Calcula quantos
--   dos clientes adquiridos naquele mês voltaram a comprar em algum momento.
--
-- COMO INTERPRETAR
--   cohort_month: mês em que o cliente fez sua PRIMEIRA compra (definido por
--   customer_unique_id, não customer_id, que é por-pedido).
--   pct_recompra: % de clientes do cohort que voltaram pelo menos uma vez.
--
-- TABELAS USADAS
--   dbt_dev_marts.fct_orders
-- =============================================================================

with first_purchase as (

    -- 1 linha por cliente, com o mês da primeira compra
    select
        customer_unique_id,
        min(purchase_month)                     as cohort_month,
        count(distinct order_id)                as total_orders

    from `dbt_dev_marts.fct_orders`
    where order_status = 'delivered'
    group by customer_unique_id

),

cohorts as (

    select
        cohort_month,
        count(*)                                as cohort_size,
        countif(total_orders >= 2)              as recompradores,
        round(countif(total_orders >= 2) * 100.0 / count(*), 2) as pct_recompra

    from first_purchase
    group by cohort_month

)

select
    cohort_month,
    cohort_size,
    recompradores,
    pct_recompra

from cohorts
where cohort_month is not null
order by cohort_month

-- =============================================================================
-- FINDINGS
--
-- Taxa de recompra média (cohorts com >= 6 meses de janela): ~4-5%
-- Cohort com maior recompra: jan/2017 (7.25%) — pode ser cohort early-adopter
-- Cohort com menor recompra (controlado por tempo): nov/2017 e dez/2017 (3.16% e 2.60%)
--
-- ATENÇÃO METODOLÓGICA: cohorts de 2018 têm janela curta pra recomprar.
-- Ago/2018 tem só 0.55% mas teve só 2 meses de janela. Não é insight válido
-- como "queda de retenção", precisa controlar pela janela fixa (90 dias).
--
-- Volume de aquisição vs retenção:
--   Cohort BF (nov/2017): 7.060 clientes, 3.16% recompra (BAIXA)
--   Cohort orgânico (jun/2017): 3.037 clientes, 5.30% recompra (alta)
--   Black Friday traz mais gente mas pior cliente em LTV.
--
-- Insight pro README:
--   Olist é negócio de aquisição, não retenção. Recompra ~3-5% (vs 15-25%
--   de marketplaces maduros). Black Friday inflaciona volume mas captura
--   turistas de oferta — cohort BF retém pior que cohorts orgânicos.
-- =============================================================================
