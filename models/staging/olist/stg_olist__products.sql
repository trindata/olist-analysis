with source as (

    select * from {{ source('olist_raw', 'products') }}

),

renamed as (

    select
        -- ids
        product_id,

        -- categoria (em pt-BR; tradução vem via join na intermediate)
        product_category_name as product_category_name_pt,

        -- atributos do anúncio (typos 'lenght' corrigidos)
        product_name_lenght        as product_name_length,
        product_description_lenght as product_description_length,
        product_photos_qty,

        -- dimensões físicas
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,

        -- coluna calculada: volume em cm3
        product_length_cm * product_height_cm * product_width_cm as product_volume_cm3

    from source

)

select * from renamed