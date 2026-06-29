-- =============================================================================
-- 01 — Taxa de atraso por categoria de produto
-- =============================================================================
--
-- PERGUNTA DE NEGÓCIO
--   Quais categorias têm a maior taxa de atraso na entrega? Existe relação
--   entre o tipo de produto e a probabilidade de chegar fora do prazo?
--
-- HIPÓTESE
--   Categorias "pesadas" (móveis, eletrodomésticos grandes, equipamentos)
--   atrasam mais que categorias leves. Volume e dimensão impactam frete e
--   logística, então o gargalo operacional não é uniforme entre categorias.
--
-- GRANULARIDADE
--   1 linha por categoria. Apenas pedidos com status 'delivered' entram —
--   pedidos cancelados ou não entregues distorceriam a taxa.
--
-- COMO INTERPRETAR
--   pct_late: % de pedidos delivered que chegaram depois da estimated_delivery.
--   avg_weight_g: peso médio dos itens. Usado pra ranquear "leveza" da categoria.
--   total_orders: pra ignorar categorias com poucos pedidos (ruído estatístico).
--
-- TABELAS USADAS
--   dbt_dev_intermediate.int_order_items__enriched
--   dbt_dev_intermediate.int_orders__enriched
-- =============================================================================

with order_items as (

    select * from `dbt_dev_intermediate.int_order_items__enriched`

),

orders as (

    select * from `dbt_dev_intermediate.int_orders__enriched`
    where order_status = 'delivered'

),

-- 1 linha por (categoria, pedido) — evita inflar contagens pelo fan-out de items
category_orders as (

    select distinct
        oi.product_category_name_en as category,
        o.order_id,
        o.is_late,
        oi.product_weight_g

    from order_items oi
    inner join orders o using (order_id)

),

agg as (

    select
        category,
        count(distinct order_id)                as total_orders,
        countif(is_late)                        as late_orders,
        round(countif(is_late) * 100.0 / count(distinct order_id), 2) as pct_late,
        round(avg(product_weight_g), 0)         as avg_weight_g

    from category_orders
    group by category

)

select *
from agg
-- corta categorias com volume baixo demais pra serem estatisticamente confiáveis
where total_orders >= 100
order by pct_late desc
limit 20

-- =============================================================================
-- FINDINGS 

-- Categorias com maior pct_late:
--   1. audio (12.93%, volume 348)
--   2. fashion_underwear_beach (12.82%, volume 117)
--   3. books_technical (10.94%, volume 256)
--   Top 3 são de baixo volume → atenção a ruído estatístico
--
-- Correlação peso × atraso:
--   NÃO SE CONFIRMA. office_furniture (peso médio 11kg) tem 9.25% atraso,
--   audio (1.2kg) tem 12.93%. As categorias mais pesadas (móveis em geral)
--   ficam DENTRO da média (~8%), não acima.
--
-- Média geral de atraso: 8.11% (96.478 pedidos delivered, 7.826 atrasados)
--
-- Insight pro README:
--   Atraso é problema sistêmico, não de categoria. Nenhuma categoria de
--   volume relevante (≥2000 pedidos) passa de 10%. Hipótese "peso causa
--   atraso" derrubada. Investigar fatores logísticos (rota, seller).
-- =============================================================================
