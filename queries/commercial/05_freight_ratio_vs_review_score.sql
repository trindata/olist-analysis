-- =============================================================================
-- 05 — Freight ratio vs review score (cliente penaliza frete caro?)
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   Frete proporcionalmente alto ao valor do produto correlaciona com nota
--   ruim de review? Existe ponto de virada (cutoff) onde a satisfação cai?
--
-- HIPÓTESE
--   Cliente que paga frete > 20% do valor do produto se sente lesado e
--   penaliza no review, mesmo que a entrega seja no prazo e o produto OK.
--   A relação não é linear — tem um cliff em torno de algum threshold.
--
-- GRANULARIDADE
--   1 linha por bucket de freight_ratio. Cada pedido entregue cai em um bucket.
--
-- COMO INTERPRETAR
--   freight_ratio_bucket: faixa de % do frete sobre o preço do pedido.
--   avg_review_score: média das notas dos pedidos naquele bucket.
--   pct_negative: % de pedidos com review_score ≤ 2.
--
-- TABELAS USADAS
--   dbt_dev_marts.fct_orders
-- =============================================================================

with bucketed as (

    select
        order_id,
        order_freight_ratio_pct,
        review_score,
        case
            when order_freight_ratio_pct <  5  then '0-5%'
            when order_freight_ratio_pct < 10  then '5-10%'
            when order_freight_ratio_pct < 15  then '10-15%'
            when order_freight_ratio_pct < 20  then '15-20%'
            when order_freight_ratio_pct < 30  then '20-30%'
            when order_freight_ratio_pct < 50  then '30-50%'
            else '50%+'
        end as freight_ratio_bucket

    from `dbt_dev_marts.fct_orders`
    where order_status = 'delivered'
      and review_score is not null
      and order_freight_ratio_pct is not null

)

select
    freight_ratio_bucket,
    count(*)                                    as total_orders,
    round(avg(review_score), 2)                 as avg_review_score,
    countif(review_score <= 2)                  as negative_reviews,
    round(countif(review_score <= 2) * 100.0 / count(*), 2) as pct_negative,
    countif(review_score >= 4)                  as positive_reviews,
    round(countif(review_score >= 4) * 100.0 / count(*), 2) as pct_positive

from bucketed
group by freight_ratio_bucket
order by
    case freight_ratio_bucket
        when '0-5%'   then 1
        when '5-10%'  then 2
        when '10-15%' then 3
        when '15-20%' then 4
        when '20-30%' then 5
        when '30-50%' then 6
        else 7
    end

-- =============================================================================
-- FINDINGS

-- avg_review_score por bucket:
--   0-5%:   4.20
--   5-10%:  4.21
--   10-15%: 4.19
--   15-20%: 4.17
--   20-30%: 4.16
--   30-50%: 4.12
--   50%+:   4.11
--
-- Bucket de virada: NÃO HÁ cliff em 20% como hipótese sugeria.
-- Tendência é gradual. Pequeno step-up de pct_negative em 30%+.
--
-- Delta total (0-5% vs 50%+): 0.09 pontos de review, 0.57pp de pct_negative
--
-- Anomalia: bucket 0-5% tem pct_negative MAIOR (13.04%) que buckets 5-30%
-- (12.17-12.49%). Possível: produtos muito baratos têm qualidade pior.
--
-- Insight pro README:
--   Frete impacta pouco satisfação. Hipótese de "cliente penaliza frete
--   caro" tem efeito real mas modesto (0.1 ponto de review, 0.6pp de
--   pct_negative). Não há cliff em 20% — tendência é gradual.
-- =============================================================================
