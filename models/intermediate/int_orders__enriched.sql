with orders as (

    select * from {{ ref('stg_olist__orders') }}

),

customers as (

    select * from {{ ref('stg_olist__customers') }}

),

reviews as (

    select * from {{ ref('stg_olist__order_review') }}

),

order_aggregated as (

    select * from {{ ref('int_orders__aggregated') }}

),

enriched as (

    select
        -- chaves
        o.order_id,
        o.customer_id,
        c.customer_unique_id,

        -- status e timestamps
        o.order_status,
        o.purchased_at,
        o.approved_at,
        o.delivered_to_carrier_at,
        o.delivered_to_customer_at,
        o.estimated_delivery_at,

        -- geografia do cliente
        c.customer_city,
        c.customer_state,
        c.customer_zip_code_prefix,

        -- métricas de tempo (só calculadas pra pedidos delivered)
        date_diff(
            date(o.delivered_to_customer_at),
            date(o.purchased_at),
            day
        )                                               as days_to_deliver,

        date_diff(
            date(o.estimated_delivery_at),
            date(o.purchased_at),
            day
        )                                               as days_promised,

        date_diff(
            date(o.delivered_to_customer_at),
            date(o.estimated_delivery_at),
            day
        )                                               as delivery_delay_days,

        date_diff(
            date(o.approved_at),
            date(o.purchased_at),
            day
        )                                               as days_to_approve,

        date_diff(
            date(o.delivered_to_carrier_at),
            date(o.approved_at),
            day
        )                                               as days_to_ship,

        -- flags booleanas
        o.delivered_to_customer_at is not null
            and o.delivered_to_customer_at
                > o.estimated_delivery_at               as is_late,

        o.order_status = 'delivered'                    as is_delivered,
        o.order_status = 'canceled'                     as is_canceled,

        -- dimensões temporais de cohort
        date_trunc(date(o.purchased_at), month)         as purchase_month,
        extract(year from o.purchased_at)               as purchase_year,
        extract(month from o.purchased_at)              as purchase_month_num,
        extract(dayofweek from o.purchased_at)          as purchase_day_of_week,

        -- review
        r.review_score,
        r.review_created_at,
        r.review_answered_at,
        r.review_score >= 4                             as is_positive_review,
        r.review_score <= 2                             as is_negative_review,

        -- agregados de itens
        oa.items_count,
        oa.sellers_count,
        oa.categories_count,
        oa.order_revenue,
        oa.order_freight_value,
        oa.order_gross_value,
        oa.order_freight_ratio_pct,
        oa.order_total_weight_g,
        oa.avg_photos_qty,
        oa.avg_name_length,
        oa.avg_description_length

    from orders o

    left join customers c
        using (customer_id)

    left join reviews r
        using (order_id)

    left join order_aggregated oa
        using (order_id)

)

select * from enriched