with loans as (
    select * from {{ ref('stg_freddie__loans') }}
),

terminations as (
    select
        loan_id,
        zero_balance_code,
        -- Effective dates can land a month either side of the reporting period, so use the
        -- reporting month to stay aligned with fct_loan_months.
        reporting_month as outcome_month
    from {{ ref('stg_freddie__loan_months') }}
    where zero_balance_code is not null
)

select
    loans.*,
    case
        when credit_score is null then 'not available'
        when credit_score < 620 then '300-619'
        when credit_score < 680 then '620-679'
        when credit_score < 720 then '680-719'
        when credit_score < 760 then '720-759'
        else '760-850'
    end as credit_score_band,
    case
        when original_ltv is null then 'not available'
        when original_ltv <= 60 then '0-60'
        when original_ltv <= 80 then '61-80'
        when original_ltv <= 90 then '81-90'
        when original_ltv <= 95 then '91-95'
        else '96+'
    end as ltv_band,
    case
        when terminations.zero_balance_code is null then 'active'
        when terminations.zero_balance_code = '01' then 'paid off'
        -- Third-party sale, short sale or charge-off, and REO disposition.
        when terminations.zero_balance_code in ('02', '03', '09') then 'defaulted'
        else 'sold or repurchased'
    end as outcome,
    terminations.outcome_month
from loans
left join terminations using (loan_id)
