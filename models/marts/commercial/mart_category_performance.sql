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

joined as (

    select
        oi.product_category_name_en     as category,
        o.purchase_year,
        o.purchase_month,

        -- volume
        count(distinct o.order_id)      as total_orders,
        count(distinct oi.seller_id)    as active_sellers,

        -- receita
        round(sum(oi.item_price), 2)            as category_revenue,
        round(avg(oi.item_price), 2)            as avg_item_price,
        round(sum(oi.item_gross_value), 2)      as category_gross_value,

        -- logística
        round(avg(oi.item_freight_ratio_pct), 2)  as avg_freight_ratio_pct,
        round(avg(oi.product_weight_g), 1)         as avg_product_weight_g,

        -- satisfação
        round(avg(o.review_score), 2)           as avg_review_score,
        countif(o.review_score >= 4)            as positive_reviews,
        countif(o.review_score <= 2)            as negative_reviews,

        -- pontualidade
        countif(o.is_late)                      as late_orders

    from order_items oi
    inner join orders o
        using (order_id)

    where o.order_status = 'delivered'

    group by
        oi.product_category_name_en,
        o.purchase_year,
        o.purchase_month

)

select * from joined