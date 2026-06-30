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

seller_orders as (

    select
        oi.seller_id,
        o.order_id,

        o.order_status,
        o.review_score,
        o.is_late,
        o.days_to_deliver,
        o.delivery_delay_days,
        o.purchased_at,

        sum(oi.item_price)              as order_seller_revenue,
        sum(oi.item_gross_value)        as order_seller_gross_value,

        any_value(oi.seller_state)      as seller_state,
        any_value(oi.seller_city)       as seller_city

    from order_items oi
    inner join orders o
        using (order_id)

    where o.order_status = 'delivered'

    group by
        oi.seller_id,
        o.order_id,
        o.order_status,
        o.review_score,
        o.is_late,
        o.days_to_deliver,
        o.delivery_delay_days,
        o.purchased_at

),

seller_catalog as (

    select
        oi.seller_id,
        count(distinct oi.product_id)                   as unique_products,
        count(distinct oi.product_category_name_en)     as unique_categories,
        round(avg(oi.item_price), 2)                    as avg_item_price

    from order_items oi
    inner join orders o
        using (order_id)

    where o.order_status = 'delivered'

    group by oi.seller_id

),

joined as (

    select
        so.seller_id,
        so.seller_state,
        so.seller_city,

        count(*)                                    as total_orders,
        sc.unique_products,
        sc.unique_categories,

        round(sum(so.order_seller_revenue), 2)      as seller_revenue,
        sc.avg_item_price,
        round(sum(so.order_seller_gross_value), 2)  as seller_gross_value,

        round(avg(so.days_to_deliver), 1)           as avg_days_to_deliver,
        round(avg(so.delivery_delay_days), 1)       as avg_delay_days,
        countif(so.is_late)                         as late_orders,
        round(
            countif(so.is_late) * 100.0 / count(*)
        , 2)                                        as pct_late_orders,

        round(avg(so.review_score), 2)              as avg_review_score,
        countif(so.review_score >= 4)               as positive_reviews,
        countif(so.review_score <= 2)               as negative_reviews,

        min(date(so.purchased_at))                  as first_sale_date,
        max(date(so.purchased_at))                  as last_sale_date

    from seller_orders so
    left join seller_catalog sc
        using (seller_id)

    group by
        so.seller_id,
        so.seller_state,
        so.seller_city,
        sc.unique_products,
        sc.unique_categories,
        sc.avg_item_price

)

select * from joined
