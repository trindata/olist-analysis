with order_items as (

    select * from {{ ref('int_order_items__enriched') }}

),

orders as (

    select
        order_id,
        order_status,
        review_score,
        is_late,
        purchase_month,
        purchase_year

    from {{ ref('int_orders__enriched') }}

),

-- ----------------------------------------------------------------------
-- 1 linha por (categoria, mês, pedido). Resolve o fan-out de items dentro
-- da mesma categoria: um pedido com 3 items na mesma categoria deve contar
-- como 1 pedido naquela categoria, não 3.
-- Métricas de pedido (review, atraso) ficam por pedido distinto.
-- Métricas de item (preço, frete, peso) somam/agregam os items do pedido
-- naquela categoria.
-- ----------------------------------------------------------------------
category_orders as (

    select
        oi.product_category_name_en             as category,
        o.purchase_year,
        o.purchase_month,
        o.order_id,

        -- atributos do pedido (constantes dentro do grupo)
        any_value(o.review_score)               as review_score,
        any_value(o.is_late)                    as is_late,

        -- agregados de item dentro da categoria pro pedido
        sum(oi.item_price)                      as order_category_revenue,
        sum(oi.item_gross_value)                as order_category_gross_value,
        count(oi.order_item_id)                 as items_in_category,
        any_value(oi.seller_id)                 as any_seller_id,

        -- médias por item dentro do pedido na categoria
        avg(oi.item_price)                      as avg_item_price_in_order,
        avg(oi.item_freight_ratio_pct)          as avg_freight_ratio_in_order,
        avg(oi.product_weight_g)                as avg_weight_in_order

    from order_items oi
    inner join orders o using (order_id)

    where o.order_status = 'delivered'

    group by
        oi.product_category_name_en,
        o.purchase_year,
        o.purchase_month,
        o.order_id

),

-- ----------------------------------------------------------------------
-- Sellers ativos por (categoria, mês). Calculado separado porque a CTE
-- acima já colapsou o seller_id (any_value), então um distinct lá perderia
-- sellers múltiplos do mesmo pedido na mesma categoria.
-- ----------------------------------------------------------------------
category_sellers as (

    select
        oi.product_category_name_en             as category,
        o.purchase_year,
        o.purchase_month,
        count(distinct oi.seller_id)            as active_sellers

    from order_items oi
    inner join orders o using (order_id)

    where o.order_status = 'delivered'

    group by
        oi.product_category_name_en,
        o.purchase_year,
        o.purchase_month

),

joined as (

    select
        co.category,
        co.purchase_year,
        co.purchase_month,

        -- volume
        count(*)                                        as total_orders,
        cs.active_sellers,

        -- receita
        round(sum(co.order_category_revenue), 2)        as category_revenue,
        round(avg(co.avg_item_price_in_order), 2)       as avg_item_price,
        round(sum(co.order_category_gross_value), 2)    as category_gross_value,

        -- logística (médias por pedido distinto na categoria)
        round(avg(co.avg_freight_ratio_in_order), 2)    as avg_freight_ratio_pct,
        round(avg(co.avg_weight_in_order), 1)           as avg_product_weight_g,

        -- satisfação (média por pedido distinto)
        round(avg(co.review_score), 2)                  as avg_review_score,
        countif(co.review_score >= 4)                   as positive_reviews,
        countif(co.review_score <= 2)                   as negative_reviews,

        -- pontualidade (por pedido distinto)
        countif(co.is_late)                             as late_orders

    from category_orders co
    left join category_sellers cs
        using (category, purchase_year, purchase_month)

    group by
        co.category,
        co.purchase_year,
        co.purchase_month,
        cs.active_sellers

)

select * from joined