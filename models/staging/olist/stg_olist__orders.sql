with source as (

    select * from {{ source('olist_raw', 'orders') }}

),

renamed as (

    select
        -- ids
        order_id,
        customer_id,

        -- status do pedido
        lower(trim(order_status)) as order_status,

        -- timestamps do ciclo de vida do pedido
        cast(order_purchase_timestamp      as timestamp) as purchased_at,
        cast(order_approved_at             as timestamp) as approved_at,
        cast(order_delivered_carrier_date  as timestamp) as delivered_to_carrier_at,
        cast(order_delivered_customer_date as timestamp) as delivered_to_customer_at,
        cast(order_estimated_delivery_date as timestamp) as estimated_delivery_at

    from source

)

select * from renamed