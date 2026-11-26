{{ config(location='exports/risk_bands.csv') }}

select *
from {{ ref('risk_band_performance') }}
where loans >= {{ var('min_cell_size') }}
