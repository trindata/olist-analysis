with source as (

    select * from {{ source('olsit_raw', 'order_items')}}

),

renamed as (

    select
    -- ids
    order_id,
    order_item_id,
    product_id,
    seller_id,

    -- datas
    cast(shipping_limit_date as date)

    price,
    freight_value,

)

select * from rename