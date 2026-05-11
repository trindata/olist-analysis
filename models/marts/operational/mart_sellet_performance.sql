with order_items as (

    select * from {{ ref('int_order_items__enriched') }}

),

orders as (

    select
        order_id,
        order_status,
        review_score,
        is_late,
        days_to_deliver,
        delivery_delay_days,
        purchased_at,
        purchase_month,
        purchase_year

    from {{ ref('int_orders__enriched') }}

),

joined as (

    select
        oi.seller_id,
        oi.seller_state,
        oi.seller_city,

        -- volume
        count(distinct o.order_id)          as total_orders,
        count(distinct oi.product_id)       as unique_products,
        count(distinct
            oi.product_category_name_en)    as unique_categories,

        -- receita
        round(sum(oi.item_price), 2)                as seller_revenue,
        round(avg(oi.item_price), 2)                as avg_item_price,
        round(sum(oi.item_gross_value), 2)          as seller_gross_value,

        -- logística
        round(avg(o.days_to_deliver), 1)            as avg_days_to_deliver,
        round(avg(o.delivery_delay_days), 1)        as avg_delay_days,
        countif(o.is_late)                          as late_orders,
        round(countif(o.is_late) * 100.0
            / count(distinct o.order_id), 2)        as pct_late_orders,

        -- satisfação
        round(avg(o.review_score), 2)               as avg_review_score,
        countif(o.review_score >= 4)                as positive_reviews,
        countif(o.review_score <= 2)                as negative_reviews,

        -- período de atividade
        min(date(o.purchased_at))                   as first_sale_date,
        max(date(o.purchased_at))                   as last_sale_date

    from order_items oi
    inner join orders o
        using (order_id)

    where o.order_status = 'delivered'

    group by
        oi.seller_id,
        oi.seller_state,
        oi.seller_city

)

select * from joined