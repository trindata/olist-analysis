-- =============================================================================
-- 04 — Top categorias por receita vs satisfação
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   As categorias que mais geram receita são também as que mais agradam? Há
--   categorias "boas de receita, ruins de review" que viram risco reputacional?
--   E categorias "queridinhas, mas pequenas" que valeria escalar?
--
-- HIPÓTESE
--   Categorias caras (informática, móveis) lideram receita mas têm review
--   mais baixo por expectativa elevada / problemas de entrega. Categorias
--   pequenas e nicho têm review alto mas pouco volume.
--
-- GRANULARIDADE
--   1 linha por categoria. Agregação direta do mart de categoria/mês.
--
-- COMO INTERPRETAR
--   Quadrante "alto revenue + alto review" = vacas leiteiras a proteger.
--   Quadrante "alto revenue + baixo review" = risco — investir em qualidade.
--   Quadrante "baixo revenue + alto review" = potencial — investir em volume.
--   Quadrante "baixo revenue + baixo review" = candidatas a descontinuar.
--
-- TABELAS USADAS
--   dbt_dev_marts.mart_category_performance
-- =============================================================================

with by_category as (

    select
        category,
        sum(category_revenue)                   as total_revenue,
        sum(total_orders)                       as total_orders,
        round(sum(category_revenue) / nullif(sum(total_orders), 0), 2) as avg_ticket,
        -- review_score ponderado por pedidos (cada mês pesa pelo volume)
        round(sum(avg_review_score * total_orders) / nullif(sum(total_orders), 0), 2) as weighted_review_score,
        sum(late_orders)                        as total_late,
        round(sum(late_orders) * 100.0 / nullif(sum(total_orders), 0), 2) as pct_late

    from `dbt_dev_marts.mart_category_performance`
    group by category

),

ranked as (

    select
        *,
        ntile(4) over (order by total_revenue)          as revenue_quartile,
        ntile(4) over (order by weighted_review_score)  as review_quartile

    from by_category
    where total_orders >= 100   -- corta cauda longa

)

select
    category,
    total_orders,
    total_revenue,
    avg_ticket,
    weighted_review_score,
    pct_late,
    revenue_quartile,
    review_quartile,
    case
        when revenue_quartile = 4 and review_quartile = 4 then 'vaca_leiteira'
        when revenue_quartile = 4 and review_quartile = 1 then 'risco_reputacional'
        when revenue_quartile = 1 and review_quartile = 4 then 'potencial'
        when revenue_quartile = 1 and review_quartile = 1 then 'candidata_descontinuar'
        else 'intermediaria'
    end as classificacao

from ranked
order by total_revenue desc

-- =============================================================================
-- FINDINGS

-- Categorias em "risco_reputacional" (após correção do mart):
--   1. bed_bath_table  — R$ 1.023k, review 4.00, 8.75% atraso
--   2. furniture_decor — R$ 712k, review 4.06, 8.48% atraso
--   Total: R$ 1.7M
--
-- Categorias em "potencial":
--   1. books_technical — review 4.43 (maior do quadrante), 256 pedidos
--   2. food_drink      — review 4.44, 221 pedidos
--   3. food            — review 4.33, 441 pedidos
--   4. fashion_shoes   — review 4.27, 235 pedidos
--   5. drinks          — review 4.24, 287 pedidos
--   6. costruction_tools_garden — review 4.25, 190 pedidos
--
-- Vacas leiteiras: toys (R$ 471k, 4.24) e perfumery (R$ 390k, 4.26)
-- Candidatas descontinuar: fashion_male_clothing (3.78), fashion_underwear_beach (4.00, mas 12.82% atraso)
--
-- Receita top 3 / total: 24% (concentração razoável)
--
-- IMPORTANTE: comparação antes vs depois do fix do mart:
--   - computers_accessories SAIU de risco_reputacional (review subiu de 3.99 → 4.08)
--   - pct_late caiu ~11% em todas as categorias (bug inflava late_orders)
--   - avg_review subiu 0.05-0.10 pontos (bug inflava negativos mais que positivos)
--
-- Insight pro README:
--   bed_bath_table e furniture_decor concentram risco reputacional (R$ 1.7M).
--   6 categorias têm potencial (alto review, baixo volume).
--   Volume não correlaciona com satisfação: só 2 vacas leiteiras reais.
-- =============================================================================
