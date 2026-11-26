with loan_months as (
    select
        loan_id,
        reporting_month,
        months_delinquent,
        delinquency_status,
        -- Each current month bumps this count, so consecutive delinquent months share a value and
        -- form one episode. An episode continues across a reporting gap if the loan was delinquent
        -- on both sides.
        count(*) filter (where delinquency_status = 'current') over loan_history
            as current_months_so_far,
        lead(reporting_month) over loan_history as next_reporting_month
    from {{ ref('fct_loan_months') }}
    window loan_history as (partition by loan_id order by reporting_month)
),

episodes as (
    select
        loan_id,
        min(reporting_month) as start_month,
        max(reporting_month) as end_month,
        -- The month reported right after the episode, null if the episode runs to the loan's last
        -- reported month.
        case
            when bool_and(next_reporting_month is not null) then max(next_reporting_month)
        end as next_month,
        case
            when bool_or(delinquency_status = 'REO') then 'REO'
            when max(months_delinquent) >= 3 then '90+ days'
            when max(months_delinquent) = 2 then '60-89 days'
            else '30-59 days'
        end as worst_delinquency_status
    from loan_months
    where delinquency_status != 'current'
    group by loan_id, current_months_so_far
),

resolved as (
    select
        episodes.*,
        case
            when episodes.next_month is null and loans.outcome = 'active' then 'ongoing'
            -- A loan that pays off while delinquent is reported as current in its final month, so
            -- a termination in the month right after the episode is the outcome, not a cure.
            when loans.outcome_month <= coalesce(episodes.next_month, episodes.end_month)
                then loans.outcome
            else 'cured'
        end as outcome,
        case
            when episodes.next_month is null and loans.outcome = 'active' then null
            when loans.outcome_month <= coalesce(episodes.next_month, episodes.end_month)
                then loans.outcome_month
            else episodes.next_month
        end as outcome_month
    from episodes
    inner join {{ ref('dim_loans') }} as loans on episodes.loan_id = loans.loan_id
)

select
    loan_id,
    row_number() over (partition by loan_id order by start_month) as episode_number,
    start_month,
    end_month,
    worst_delinquency_status,
    outcome,
    outcome_month,
    date_diff('month', start_month, outcome_month) as months_to_outcome
from resolved
