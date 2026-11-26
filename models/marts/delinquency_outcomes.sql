select
    loans.vintage_year,
    episodes.worst_delinquency_status,
    episodes.outcome,
    count(*) as episodes,
    count(*) / sum(count(*)) over (
        partition by loans.vintage_year, episodes.worst_delinquency_status
    ) as share_of_episodes,
    median(episodes.months_to_outcome) as median_months_to_outcome
from {{ ref('fct_delinquency_episodes') }} as episodes
inner join {{ ref('dim_loans') }} as loans on episodes.loan_id = loans.loan_id
group by loans.vintage_year, episodes.worst_delinquency_status, episodes.outcome
