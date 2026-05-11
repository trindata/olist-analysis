with source as (

    select * from {{ source('olist_raw', 'order_payments') }}

),

renamed as (

    select
        -- ids (chave primária composta: order_id + payment_sequential)
        order_id,
        payment_sequential,

        -- atributos
        lower(trim(payment_type))           as payment_type,
        cast(payment_installments as int64) as payment_installments,
        cast(payment_value as numeric)      as payment_value

    from source

)

select * from renamed