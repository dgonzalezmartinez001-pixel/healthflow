{{ config(materialized='table') }}

with date_spine as (
    select distinct scheduled_date as date_id
    from {{ ref('int_appointments') }}
)

select
    date_id,
    extract(year from date_id) as year,
    extract(month from date_id) as month,
    extract(day from date_id) as day,
    extract(dayofweek from date_id) as day_of_week,
    case when extract(dayofweek from date_id) in (0, 6) then true else false end as is_weekend
from date_spine
order by date_id