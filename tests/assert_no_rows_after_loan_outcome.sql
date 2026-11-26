select
    months.loan_id,
    months.reporting_month
from {{ ref('fct_loan_months') }} as months
inner join {{ ref('dim_loans') }} as loans on months.loan_id = loans.loan_id
where months.reporting_month > loans.outcome_month
