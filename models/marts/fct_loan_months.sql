with loan_months as (
    select
        *,
        case
            when is_reo_acquisition then 'REO'
            when months_delinquent = 0 then 'current'
            when months_delinquent = 1 then '30-59 days'
            when months_delinquent = 2 then '60-89 days'
            when months_delinquent >= 3 then '90+ days'
        end as delinquency_status,
        -- A few loans skip months in Freddie Mac's reporting. Previous-month values are left null
        -- across a gap instead of comparing against an older month.
        date_diff('month', lag(reporting_month) over loan_history, reporting_month) = 1
            as follows_previous_month
    from {{ ref('stg_freddie__loan_months') }}
    window loan_history as (partition by loan_id order by reporting_month)
)

select
    loan_id,
    reporting_month,
    loan_age,
    current_upb,
    months_delinquent,
    delinquency_status,
    case when follows_previous_month then lag(current_upb) over loan_history end as previous_upb,
    case
        when follows_previous_month then lag(delinquency_status) over loan_history
    end as previous_delinquency_status
from loan_months
window loan_history as (partition by loan_id order by reporting_month)
