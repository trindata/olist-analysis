with order_items_enriched as (

    select * from {{ ref('int_order_items__enriched') }}

),

aggregated as (

    select
        order_id,

        -- contagens
        count(order_item_id)                            as items_count,
        count(distinct seller_id)                       as sellers_count,
        count(distinct product_category_name_en)        as categories_count,

        -- receita
        sum(item_price)                                 as order_revenue,
        sum(item_freight_value)                         as order_freight_value,
        sum(item_gross_value)                           as order_gross_value,

        -- logística
        round(
            sum(item_freight_value)
            / nullif(sum(item_price), 0) * 100
        , 2)                                            as order_freight_ratio_pct,
        sum(product_weight_g)                           as order_total_weight_g,

        -- qualidade do anúncio (médias dos itens do pedido)
        round(avg(product_photos_qty), 1)               as avg_photos_qty,
        round(avg(product_name_length), 1)              as avg_name_length,
        round(avg(product_description_length), 1)       as avg_description_length

    from order_items_enriched
    group by order_id

)

select * from aggregated