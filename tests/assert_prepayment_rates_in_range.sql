select *
from {{ ref('prepayment_by_vintage') }}
where smm not between 0 and 1
