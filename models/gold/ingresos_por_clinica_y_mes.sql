select
    clinic_id,
    date_trunc('month', date_id) as month,
    sum(total_amount) as total_revenue
from {{ ref('fact_billing') }}
group by 1,2