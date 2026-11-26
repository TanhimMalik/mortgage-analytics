with loan_months as (
    select
        loans.vintage_year,
        months.reporting_month,
        months.previous_upb,
        loans.outcome = 'paid off' and loans.outcome_month = months.reporting_month
            as paid_off_this_month
    from {{ ref('fct_loan_months') }} as months
    inner join {{ ref('dim_loans') }} as loans on months.loan_id = loans.loan_id
    -- Rows without a starting balance (a loan's first month, or right after a reporting gap)
    -- can't be part of the month's starting pool.
    where months.previous_upb is not null
),

monthly as (
    select
        vintage_year,
        reporting_month,
        count(*) as active_loans,
        count(*) filter (where paid_off_this_month) as paid_off_loans,
        sum(previous_upb) as starting_upb,
        coalesce(sum(previous_upb) filter (where paid_off_this_month), 0) as paid_off_upb
    from loan_months
    group by vintage_year, reporting_month
)

select
    *,
    paid_off_upb / starting_upb as smm,
    1 - power(1 - paid_off_upb / starting_upb, 12) as cpr
from monthly
