with source as (
    select * from {{ source('freddie', 'origination') }}
)

select
    loan_id,
    -- Loan IDs encode the origination year and quarter, e.g. F07Q1... is 2007 Q1.
    year(strptime(substr(loan_id, 2, 2), '%y')) as vintage_year,
    cast(substr(loan_id, 5, 1) as integer) as vintage_quarter,
    cast(strptime(first_payment_date, '%Y%m') as date) as first_payment_month,
    nullif(cast(credit_score as integer), 9999) as credit_score,
    nullif(cast(original_ltv as integer), 999) as original_ltv,
    nullif(cast(original_cltv as integer), 999) as original_cltv,
    nullif(cast(original_dti as integer), 999) as original_dti,
    cast(original_upb as decimal(12, 2)) as original_upb,
    cast(original_interest_rate as decimal(6, 3)) as original_interest_rate,
    cast(original_loan_term as integer) as original_loan_term,
    case loan_purpose
        when 'P' then 'purchase'
        when 'C' then 'cash-out refinance'
        when 'N' then 'no cash-out refinance'
        when 'R' then 'refinance, not specified'
    end as loan_purpose,
    case occupancy_status
        when 'P' then 'primary residence'
        when 'I' then 'investment property'
        when 'S' then 'second home'
    end as occupancy_status,
    case property_type
        when 'SF' then 'single-family'
        when 'PU' then 'planned unit development'
        when 'CO' then 'condo'
        when 'MH' then 'manufactured housing'
        when 'CP' then 'co-op'
    end as property_type,
    property_state,
    case first_time_homebuyer_flag
        when 'Y' then true
        when 'N' then false
    end as is_first_time_homebuyer,
    seller_name
from source
