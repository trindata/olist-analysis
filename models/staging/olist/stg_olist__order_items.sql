with source as (

    select * from {{ source('olist_raw', 'order_items') }}

),

renamed as (

    select
        -- ids (chave primária composta: order_id + order_item_id)
        order_id,
        order_item_id,
        product_id,
        seller_id,

        -- datas
        cast(shipping_limit_date as timestamp) as shipping_limit_at,

        -- valores monetários
        cast(price         as numeric) as item_price,
        cast(freight_value as numeric) as item_freight_value

    from source

)

select * from renamed