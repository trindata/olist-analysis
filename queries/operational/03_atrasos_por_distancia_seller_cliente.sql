-- =============================================================================
-- 03 — Atrasos por rota (estado do seller × estado do cliente)
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   Onde estão os piores corredores logísticos do Olist? Rotas dentro do
--   mesmo estado entregam melhor que rotas interestaduais? Existe estado
--   que é "ralo de atrasos" tanto como origem quanto como destino?
--
-- HIPÓTESE
--   Rotas intraestaduais (seller_state = customer_state) têm taxa de atraso
--   muito menor. Norte/Nordeste como destino aumentam atraso mesmo quando o
--   seller é de SP (centro de gravidade logístico do país).
--
-- GRANULARIDADE
--   1 linha por par (seller_state, customer_state). Filtrado por volume
--   mínimo pra evitar combinações raras com ruído.
--
-- COMO INTERPRETAR
--   intrastate_flag: 1 se seller e cliente no mesmo estado, 0 caso contrário.
--   pct_late: taxa de atraso da rota.
--   avg_days_to_deliver: tempo médio real de entrega da rota.
--
-- TABELAS USADAS
--   dbt_dev_intermediate.int_order_items__enriched
--   dbt_dev_marts.fct_orders
-- =============================================================================

with seller_per_order as (

    -- 1 linha por (order_id, seller_state). Pedido multi-seller aparece N vezes.
    select distinct
        order_id,
        seller_state

    from `dbt_dev_intermediate.int_order_items__enriched`

),

orders as (

    select
        order_id,
        customer_state,
        is_late,
        days_to_deliver

    from `dbt_dev_marts.fct_orders`
    where order_status = 'delivered'

),

routes as (

    select
        sp.seller_state,
        o.customer_state,
        case when sp.seller_state = o.customer_state then 1 else 0 end as intrastate,
        o.order_id,
        o.is_late,
        o.days_to_deliver

    from seller_per_order sp
    inner join orders o using (order_id)

)

select
    seller_state,
    customer_state,
    intrastate,
    count(distinct order_id)                    as total_orders,
    countif(is_late)                            as late_orders,
    round(countif(is_late) * 100.0 / count(distinct order_id), 2) as pct_late,
    round(avg(days_to_deliver), 1)              as avg_days_to_deliver

from routes
group by seller_state, customer_state, intrastate
having total_orders >= 100
order by pct_late desc
limit 30

-- =============================================================================
-- FINDINGS
--
-- Top 5 piores rotas:
--   1. SP→AL: 26,17% (256 pedidos, 25 dias médio)
--   2. MA→SP: 25,00% (124 pedidos, 16 dias — provável problema de previsão)
--   3. SP→MA: 21,30% (493 pedidos)
--   4. SP→PI: 18,24% (329 pedidos)
--   5. PR→BA: 16,67% (144 pedidos)
--
-- TODAS as 30 piores rotas são intrastate=0 (interestaduais). Zero rotas
-- intraestaduais no top 30.
--
-- Rota de maior impacto absoluto: SP→RJ (1.264 atrasos em 8.188 pedidos)
--
-- Padrão geográfico: destino nordestino é fator de risco recorrente.
-- AL, MA, PI, BA, CE, SE, PB, PE, RN todos aparecem como destinos críticos.
--
-- Insight pro README:
--   Distância geográfica é o principal driver de atraso. Nordeste como
--   destino é o gargalo logístico. Rota SP→RJ tem maior volume absoluto
--   de atrasos do sistema.

-- =============================================================================
