select
    loan_id,
    reporting_month
from {{ ref('stg_freddie__loan_months') }}
group by loan_id, reporting_month
having count(*) > 1
