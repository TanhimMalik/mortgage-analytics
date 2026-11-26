with seriously_delinquent_loans as (
    select distinct loan_id
    from {{ ref('fct_loan_months') }}
    where delinquency_status in ('90+ days', 'REO')
)

select
    loans.vintage_year,
    loans.credit_score_band,
    loans.ltv_band,
    count(*) as loans,
    avg(case when delinquent.loan_id is not null then 1.0 else 0 end) as serious_delinquency_rate,
    avg(case when loans.outcome = 'defaulted' then 1.0 else 0 end) as default_rate
from {{ ref('dim_loans') }} as loans
left join seriously_delinquent_loans as delinquent on loans.loan_id = delinquent.loan_id
group by loans.vintage_year, loans.credit_score_band, loans.ltv_band
