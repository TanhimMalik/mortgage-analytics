-- Freddie Mac's reporting skips months for a small number of loans, so this warns instead of
-- failing. fct_loan_months already avoids comparing statuses across a gap.
{{ config(severity='warn') }}

select loan_id
from {{ ref('fct_loan_months') }}
group by loan_id
having count(*) != date_diff('month', min(reporting_month), max(reporting_month)) + 1
