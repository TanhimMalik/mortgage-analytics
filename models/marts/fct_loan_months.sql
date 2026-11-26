with loan_months as (
    select
        *,
        case
            when is_reo_acquisition then 'REO'
            when months_delinquent = 0 then 'current'
            when months_delinquent = 1 then '30-59 days'
            when months_delinquent = 2 then '60-89 days'
            when months_delinquent >= 3 then '90+ days'
        end as delinquency_status
    from {{ ref('stg_freddie__loan_months') }}
)

select
    loan_id,
    reporting_month,
    loan_age,
    current_upb,
    months_delinquent,
    delinquency_status,
    -- A few loans skip months in Freddie Mac's reporting. Leave the previous status null across
    -- a gap instead of comparing against an older month.
    case
        when date_diff('month', lag(reporting_month) over loan_history, reporting_month) = 1
            then lag(delinquency_status) over loan_history
    end as previous_delinquency_status
from loan_months
window loan_history as (partition by loan_id order by reporting_month)
