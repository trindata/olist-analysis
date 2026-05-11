with source as (

    select * from {{ source('olist_raw', 'customers') }}

),

renamed as (

    select
        -- ids
        customer_id,
        customer_unique_id,

        -- localização
        cast(customer_zip_code_prefix as string)  as customer_zip_code_prefix,
        initcap(trim(customer_city))              as customer_city,
        upper(trim(customer_state))               as customer_state

    from source

)

select * from renamed