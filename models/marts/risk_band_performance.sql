{% set window_months = 60 %}

with loans as (
    -- Only loans whose first 60 months are fully covered by the data, so every origination year
    -- is measured over the same window.
    select *
    from {{ ref('dim_loans') }}
    where first_payment_month + to_months({{ window_months }} - 1)
        <= (select max(reporting_month) from {{ ref('fct_loan_months') }})
),

seriously_delinquent_loans as (
    select distinct months.loan_id
    from {{ ref('fct_loan_months') }} as months
    inner join loans on months.loan_id = loans.loan_id
    where months.delinquency_status in ('90+ days', 'REO')
        and date_diff('month', loans.first_payment_month, months.reporting_month) < {{ window_months }}
)

select
    loans.vintage_year,
    loans.credit_score_band,
    loans.ltv_band,
    count(*) as loans,
    avg(case when delinquent.loan_id is not null then 1.0 else 0 end) as serious_delinquency_rate_5yr,
    avg(
        case
            when loans.outcome = 'defaulted'
                and date_diff('month', loans.first_payment_month, loans.outcome_month)
                    < {{ window_months }}
                then 1.0
            else 0
        end
    ) as default_rate_5yr
from loans
left join seriously_delinquent_loans as delinquent on loans.loan_id = delinquent.loan_id
group by loans.vintage_year, loans.credit_score_band, loans.ltv_band
