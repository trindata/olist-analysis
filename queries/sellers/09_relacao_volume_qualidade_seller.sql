-- =============================================================================
-- 09 — Volume × qualidade do seller (escalar bem ou só escalar?)
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   Quem vende mais entrega melhor, ou só vende mais? Sellers de alto volume
--   mantêm review score alto e prazo curto, ou degradam com a escala?
--
-- HIPÓTESE
--   Existe um sweet spot: sellers pequenos têm alto review (atendimento
--   personalizado mas pouco volume), médios têm o melhor equilíbrio,
--   grandes degradam (atendimento massificado, problemas de SLA).
--
-- GRANULARIDADE
--   1 linha por faixa de volume (quintil). Pondera métricas pelo total_orders
--   pra refletir experiência média do cliente, não do seller.
--
-- COMO INTERPRETAR
--   volume_bucket: 5 faixas iguais por número de pedidos (quintis).
--   weighted_review_score, weighted_pct_late: refletem o que cliente típico vive.
--
-- TABELAS USADAS
--   dbt_dev_marts.mart_seller_performance
-- =============================================================================

with bucketed as (

    select
        seller_id,
        total_orders,
        avg_review_score,
        avg_days_to_deliver,
        pct_late_orders,
        ntile(5) over (order by total_orders) as volume_bucket

    from `dbt_dev_marts.mart_seller_performance`

)

select
    volume_bucket,
    count(*)                                    as qtd_sellers,
    min(total_orders)                           as min_orders,
    max(total_orders)                           as max_orders,
    round(avg(total_orders), 0)                 as avg_orders,
    sum(total_orders)                           as total_orders_faixa,

    -- ponderadas pelo volume — o que o cliente médio vivencia
    round(sum(avg_review_score    * total_orders) / sum(total_orders), 2) as weighted_review,
    round(sum(avg_days_to_deliver * total_orders) / sum(total_orders), 1) as weighted_days,
    round(sum(pct_late_orders     * total_orders) / sum(total_orders), 2) as weighted_pct_late

from bucketed
group by volume_bucket
order by volume_bucket

-- =============================================================================
-- FINDINGS
--
-- weighted_review por bucket:
--   bucket 1 (1-2 pedidos):    4.26  -- mais alto, mas só 653 pedidos
--   bucket 2 (2-4):            4.15
--   bucket 3 (4-10):           4.21
--   bucket 4 (10-31):          4.18  -- menor pct_late (7.98%)
--   bucket 5 (32-1819):        4.13  -- pior review, maior atraso, 88% dos pedidos
--
-- Padrão observado: SEM PADRÃO CLARO. Curva é praticamente plana.
--   [x] sem padrão claro (variação dentro de 0.13 pontos)
--   [ ] linear positivo, linear negativo, U invertido — nenhum bate
--
-- Distribuição de pedidos por bucket:
--   bucket 1-4: 17.175 pedidos (17%)
--   bucket 5:   80.644 pedidos (83%)
--
-- IMPORTANTE: cliente médio do Olist compra do bucket 5, que é o de
-- pior performance. A experiência boa dos sellers menores é
-- estatisticamente irrelevante por baixíssimo volume.
--
-- Insight pro README:
--   Volume de seller não é proxy de qualidade no Olist. Variação de review
--   entre tiers de volume é < 0.13 ponto. 88% dos pedidos vêm de sellers
--   grandes (bucket 5), que têm a pior performance — embora marginal.
-- =============================================================================
