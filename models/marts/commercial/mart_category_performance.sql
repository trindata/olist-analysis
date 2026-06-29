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

category_orders as (

    select
        oi.product_category_name_en             as category,
        o.purchase_year,
        o.purchase_month,
        o.order_id,

        any_value(o.review_score)               as review_score,
        any_value(o.is_late)                    as is_late,

        sum(oi.item_price)                      as order_category_revenue,
        sum(oi.item_gross_value)                as order_category_gross_value,
        count(oi.order_item_id)                 as items_in_category,
        any_value(oi.seller_id)                 as any_seller_id,

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

        count(*)                                        as total_orders,
        cs.active_sellers,

        round(sum(co.order_category_revenue), 2)        as category_revenue,
        round(avg(co.avg_item_price_in_order), 2)       as avg_item_price,
        round(sum(co.order_category_gross_value), 2)    as category_gross_value,

        round(avg(co.avg_freight_ratio_in_order), 2)    as avg_freight_ratio_pct,
        round(avg(co.avg_weight_in_order), 1)           as avg_product_weight_g,

        round(avg(co.review_score), 2)                  as avg_review_score,
        countif(co.review_score >= 4)                   as positive_reviews,
        countif(co.review_score <= 2)                   as negative_reviews,

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
