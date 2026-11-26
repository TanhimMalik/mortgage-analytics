{{ config(location='exports/prepayment.csv') }}

-- Dollar totals are left out: in a month with a single payoff they would show that loan's balance.
select
    vintage_year,
    reporting_month,
    active_loans,
    smm,
    cpr
from {{ ref('prepayment_by_vintage') }}
where active_loans >= {{ var('min_cell_size') }}
