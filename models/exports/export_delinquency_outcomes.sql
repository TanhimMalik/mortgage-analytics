{{ config(location='exports/delinquency_outcomes.csv') }}

select *
from {{ ref('delinquency_outcomes') }}
where episodes >= {{ var('min_cell_size') }}
