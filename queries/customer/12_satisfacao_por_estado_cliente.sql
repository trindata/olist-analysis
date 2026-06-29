-- =============================================================================
-- 12 — Satisfação do cliente por estado (mapa de NPS-like)
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   Onde os clientes estão mais (in)satisfeitos? Existe um "estado-problema"
--   onde a Olist consistentemente entrega pior experiência?
--
-- HIPÓTESE
--   Estados do Norte/Nordeste teriam review pior porque sofrem mais com
--   prazos longos e atrasos (proxy de operação ruim). Sul/Sudeste teriam
--   review melhor. Mas existem confundidores — mix de categorias compradas
--   varia por região.
--
-- GRANULARIDADE
--   1 linha por customer_state. Pondera pelo volume de pedidos.
--
-- COMO INTERPRETAR
--   avg_review_score: média simples dos reviews dos pedidos daquele estado.
--   pct_positive (≥4) e pct_negative (≤2): equivalente a "promotores" e
--   "detratores" de NPS clássico.
--   net_score: pct_positive - pct_negative. Simulacro de NPS.
--
-- TABELAS USADAS
--   dbt_dev_marts.fct_orders
-- =============================================================================

with by_state as (

    select
        customer_state,
        count(*)                                as total_orders,
        round(avg(review_score), 2)             as avg_review_score,
        countif(review_score >= 4)              as positive,
        countif(review_score <= 2)              as negative,
        round(countif(review_score >= 4) * 100.0 / count(*), 2) as pct_positive,
        round(countif(review_score <= 2) * 100.0 / count(*), 2) as pct_negative,
        round(avg(days_to_deliver), 1)          as avg_days_to_deliver,
        round(countif(is_late) * 100.0 / count(*), 2) as pct_late

    from `dbt_dev_marts.fct_orders`
    where order_status = 'delivered'
      and review_score is not null

    group by customer_state

)

select
    customer_state,
    total_orders,
    avg_review_score,
    pct_positive,
    pct_negative,
    pct_positive - pct_negative                 as net_score,
    avg_days_to_deliver,
    pct_late

from by_state
where total_orders >= 100   -- corta UF de baixíssimo volume
order by net_score desc

-- =============================================================================
-- FINDINGS
--
-- 5 melhores estados (maior net_score):
--   1. SP (40k pedidos): 70.7 net_score, 8.7 dias, 5.83% atraso
--   2. PR (4.9k): 70.67, 11.9 dias, 4.92% atraso
--   3. AM (144): 69.45, 26.3 dias (!!), 4.17% atraso — paradoxo
--   4. MG (11.2k): 68.14, 11.9 dias, 5.51% atraso
--   5. RS (5.3k): 67.90, 15.2 dias, 7.10% atraso
--
-- 5 piores estados (menor net_score):
--   1. AL (394): 50.25, 24.4 dias, 23.35% atraso (!!)
--   2. MA (712): 50.28, 21.4 dias, 19.24% atraso
--   3. SE (334): 53.60, 21.4 dias, 14.97% atraso
--   4. PA (933): 54.34, 23.6 dias, 11.90% atraso
--   5. RJ (12.2k): 55.10, 15.2 dias, 13.29% atraso (surpresa!)
--
-- Correlação net_score × pct_late: forte e negativa nos extremos. Mas
-- não é linear: AM e RO têm pct_late baixo (4.17%, 2.89%) e ainda
-- assim net_score só intermediário, por expectativa amortecida.
--
-- Hipótese Norte/Nordeste pior: CONFIRMADA PARCIALMENTE.
--   - Nordeste claramente pior (AL, MA, SE, PA, BA, CE no fundo da tabela)
--   - Norte tem padrão dúbio: AM e RO bons (expectativa baixa);
--     PA ruim
-- Surpresa: RJ entre os piores (top 5), apesar de proximidade física com SP.
-- Hipótese: cliente carioca tem expectativa de prazo curto e penaliza
-- qualquer atraso, mesmo absoluto pequeno.
--
-- Insight pro README:
--   Norte/Nordeste como destino concentram atrasos (AL 23.35%, MA 19.24%).
--   SP no topo é privilégio geográfico (estoque próximo), não mérito
--   operacional. RJ é problema escondido: prazo OK mas atraso 13.29%.
--   AM tem paradoxo da expectativa: 26 dias de prazo, mas só 4% atrasa
--   porque cliente já espera demora.
-- =============================================================================
