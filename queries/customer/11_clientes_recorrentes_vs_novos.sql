-- =============================================================================
-- 11 — Recorrentes vs novos — comportamento e ticket
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   Clientes que voltam compram diferente? Ticket maior, frete proporcional
--   menor, review mais alto? Vale a pena investir em retenção?
--
-- HIPÓTESE
--   Clientes recorrentes têm ticket maior (já confiam na plataforma),
--   review mais alto (sabem o que esperar), e talvez % de atraso menor
--   (algum efeito de seleção: voltam quem teve boa experiência).
--
-- GRANULARIDADE
--   1 linha por segmento (recorrente vs novo). "Recorrente" = cliente com
--   2+ pedidos no período total.
--
-- COMO INTERPRETAR
--   avg_ticket: ticket médio por pedido do segmento.
--   avg_review_score: review médio dos pedidos do segmento.
--   pct_late: % de pedidos atrasados no segmento.
--
-- TABELAS USADAS
--   dbt_dev_marts.fct_orders
-- =============================================================================

with customer_summary as (

    select
        customer_unique_id,
        count(distinct order_id)                as qtd_pedidos

    from `dbt_dev_marts.fct_orders`
    where order_status = 'delivered'
    group by customer_unique_id

),

orders_classified as (

    select
        o.order_id,
        o.customer_unique_id,
        o.order_revenue,
        o.order_freight_value,
        o.review_score,
        o.is_late,
        case when cs.qtd_pedidos >= 2 then 'recorrente' else 'novo' end as segmento

    from `dbt_dev_marts.fct_orders` o
    inner join customer_summary cs using (customer_unique_id)
    where o.order_status = 'delivered'

)

select
    segmento,
    count(distinct customer_unique_id)          as qtd_clientes,
    count(*)                                    as qtd_pedidos,
    round(avg(order_revenue), 2)                as avg_ticket,
    round(avg(order_freight_value), 2)          as avg_freight,
    round(avg(review_score), 2)                 as avg_review_score,
    round(countif(is_late) * 100.0 / count(*), 2) as pct_late

from orders_classified
group by segmento
order by segmento

-- =============================================================================
-- FINDINGS 
--
-- Delta ticket (recorrente - novo): R$ -14,94 (recorrentes gastam MENOS)
-- Delta review (recorrente - novo): +0,07 pontos
-- Delta pct_late (recorrente - novo): -1,21 pp
--
-- HIPÓTESE INICIAL FALHOU: esperava-se ticket maior em recorrentes (confiança).
-- Realidade inversa: clientes recorrentes têm ticket 10.8% MENOR.
-- Provável explicação: primeira compra é "teste" com valor médio-alto.
-- Compras subsequentes são utilitárias (produtos repetíveis e baratos).
--
-- Recorrentes valem investimento de retenção? DEPENDE.
--   Argumento contra (estado atual): só 6% dos pedidos e 5.5% da receita.
--     Ignorar recorrentes não move o ponteiro hoje.
--   Argumento a favor (LTV futuro): se Olist conseguir reter mais e
--     aumentar a frequência, o impacto cresce. Mas ROI requer paciência.
--
-- IMPORTANTE: o melhor review/SLA dos recorrentes é viés de seleção
-- (quem teve experiência ruim na primeira vez não volta), NÃO efeito causal.
--
-- Insight pro README:
--   Recorrentes têm ticket 10.8% MENOR que novos (R$ 123 vs R$ 138).
--   Padrão "primeira compra de teste, depois compras utilitárias".
--   Retenção é selection bias: quem teve experiência boa volta.
--   Em volume, recorrentes são marginais (5.5% da receita).
-- =============================================================================
