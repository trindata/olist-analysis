-- =============================================================================
-- 07 — Sellers SP vs outros estados (satisfação e operação)
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   Sellers de São Paulo realmente entregam experiência superior? Em quê
--   especificamente: prazo, % de atraso, review? Ou só em volume?
--
-- HIPÓTESE
--   SP concentra hubs logísticos, malha rodoviária densa e maior parte
--   do mercado consumidor — então sellers de SP têm vantagem operacional
--   estrutural, refletida em prazo menor e melhor review.
--
-- GRANULARIDADE
--   1 linha por região (SP vs Outros). Pondera todas as métricas pelo
--   volume de pedidos por seller pra não inflar peso de sellers pequenos.
--
-- COMO INTERPRETAR
--   weighted_review_score: média do review por seller, ponderada pelo
--   total_orders dele. Reflete a experiência média dos clientes.
--   weighted_days_to_deliver: idem pro prazo.
--
-- TABELAS USADAS
--   dbt_dev_marts.mart_seller_performance
-- =============================================================================

with classified as (

    select
        case when seller_state = 'SP' then 'SP' else 'Outros' end as regiao,
        total_orders,
        avg_days_to_deliver,
        avg_delay_days,
        pct_late_orders,
        avg_review_score

    from `dbt_dev_marts.mart_seller_performance`
    where total_orders >= 10   -- exclui sellers de cauda longa

)

select
    regiao,
    count(*)                                    as qtd_sellers,
    sum(total_orders)                           as total_pedidos,

    -- médias ponderadas pelo volume de cada seller
    round(sum(avg_review_score    * total_orders) / sum(total_orders), 2) as weighted_review_score,
    round(sum(avg_days_to_deliver * total_orders) / sum(total_orders), 1) as weighted_days_to_deliver,
    round(sum(avg_delay_days      * total_orders) / sum(total_orders), 1) as weighted_delay_days,
    round(sum(pct_late_orders     * total_orders) / sum(total_orders), 2) as weighted_pct_late

from classified
group by regiao
order by regiao

-- =============================================================================
-- FINDINGS 

-- Delta de review score (SP - Outros): -0.09 (SP é PIOR)
-- Delta de prazo médio (SP - Outros): -0.7 dias (SP entrega só um pouco mais rápido)
-- Delta de % atraso (SP - Outros): +2.16 pp (SP atrasa MAIS)
--
-- Volumes:
--   SP: 763 sellers, 65.842 pedidos (71% do total)
--   Outros: 475 sellers, 26.023 pedidos (29%)
--
-- O insight original do README ("Sellers SP têm review score 0.4 pontos maior")
-- ESTÁ FURADO E INVERTIDO. Sellers SP são marginalmente PIORES em review.
--
-- Interpretação consistente com estudo #3 (rotas): SP concentra os sellers
-- que atendem todo o país, incluindo as rotas críticas pro Nordeste.
-- Sellers locais (de outras UFs) atendem clientes mais próximos, com
-- rotas curtas e melhor SLA.
--
-- Insight pro README:
--   Inverso do senso comum: sellers SP entregam pior. Review 4.11 vs 4.20,
--   atraso 8.6% vs 6.4%. Causa: SP atende todo o país (e rotas interestaduais
--   longas), enquanto sellers regionais atendem clientes locais.
-- =============================================================================
