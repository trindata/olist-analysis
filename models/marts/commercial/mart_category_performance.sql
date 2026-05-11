with int_orders__enriched as (

    select * from {{ ref('int_orders__enriched') }}

),

final as (

    select
        -- chaves
        order_id,
        customer_id,
        customer_unique_id,

        -- status
        order_status,
        is_delivered,
        is_canceled,

        -- geografia
        customer_state,
        customer_city,
        customer_zip_code_prefix,

        -- timestamps
        purchased_at,
        approved_at,
        delivered_to_carrier_at,
        delivered_to_customer_at,
        estimated_delivery_at,

        -- dimensões temporais
        purchase_month,
        purchase_year,
        purchase_month_num,
        purchase_day_of_week,

        -- métricas de tempo
        days_to_deliver,
        days_promised,
        delivery_delay_days,
        days_to_approve,
        days_to_ship,
        is_late,

        -- review
        review_score,
        is_positive_review,
        is_negative_review,

        -- receita e itens
        items_count,
        sellers_count,
        order_revenue,
        order_freight_value,
        order_gross_value,
        order_freight_ratio_pct,
        order_total_weight_g

    from int_orders__enriched

)

select * from final