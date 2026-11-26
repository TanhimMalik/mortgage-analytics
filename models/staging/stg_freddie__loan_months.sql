with source as (
    select * from {{ source('freddie', 'performance') }}
)

select
    loan_id,
    cast(strptime(period, '%Y%m') as date) as reporting_month,
    cast(loan_age as integer) as loan_age,
    cast(current_upb as decimal(12, 2)) as current_upb,
    -- 'RA' marks a property acquired through foreclosure (REO), which has no delinquency count.
    case
        when delinquency_status = 'RA' then null
        else cast(delinquency_status as integer)
    end as months_delinquent,
    delinquency_status = 'RA' as is_reo_acquisition,
    zero_balance_code
from source
