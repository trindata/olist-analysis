with source as (

    select * from {{ source('olist_raw', 'sellers') }}

),

renamed as (

    select
        -- ids
        seller_id,

        -- localização
        cast(seller_zip_code_prefix as string)  as seller_zip_code_prefix,
        initcap(trim(seller_city))              as seller_city,
        upper(trim(seller_state))               as seller_state

    from source

)

select * from renamed