with order_items as (

    select * from {{ ref('stg_olist__order_items') }}

),

products as (

    select * from {{ ref('stg_olist__products') }}

),

category_translation as (

    select * from {{ ref('stg_olist__category_translation') }}

),

sellers as (

    select * from {{ ref('stg_olist__sellers') }}

),

enriched as (

    select
        -- chaves
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,

        -- atributos do item
        oi.shipping_limit_at,
        oi.item_price,
        oi.item_freight_value,
        oi.item_price + oi.item_freight_value          as item_gross_value,
        oi.item_freight_value
            / NULLIF(oi.item_price, 0) * 100           as item_freight_ratio_pct,

        -- produto
        p.product_category_name_pt,
        COALESCE(ct.category_name_en, 'uncategorized') as product_category_name_en,
        p.product_weight_g,
        p.product_volume_cm3,
        p.product_photos_qty,
        p.product_name_length,
        p.product_description_length,

        -- seller
        s.seller_city,
        s.seller_state,
        s.seller_zip_code_prefix

    from order_items oi

    left join products p
        using (product_id)

    left join category_translation ct
        on p.product_category_name_pt = ct.category_name_pt

    left join sellers s
        using (seller_id)

)

select * from enriched