with source as (

    select * from {{ source('olist_raw', 'geolocation') }}

),

renamed as (

    select
        cast(geolocation_zip_code_prefix as string) as zip_code_prefix,
        geolocation_lat                             as lat,
        geolocation_lng                             as lng,
        lower(trim(geolocation_city))               as city,
        upper(trim(geolocation_state))              as state
    from source

),

aggregated as (

    select
        zip_code_prefix,
        avg(lat)        as lat,
        avg(lng)        as lng,
        any_value(city) as city,
        any_value(state) as state

    from renamed
    group by zip_code_prefix

)

select * from aggregated