with source as (

    select * from {{ source('olist_raw', 'order_reviews') }}

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by order_id
            order by review_answer_timestamp desc
        ) as rn

    from source

),

renamed as (

    select
        -- ids
        review_id,
        order_id,

        -- avaliação
        cast(review_score as int64)         as review_score,
        review_comment_title,
        review_comment_message,

        -- timestamps
        cast(review_creation_date    as timestamp) as review_created_at,
        cast(review_answer_timestamp as timestamp) as review_answered_at

    from deduplicated
    where rn = 1

)

select * from renamed