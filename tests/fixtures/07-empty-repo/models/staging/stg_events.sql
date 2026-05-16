select
    event_id,
    user_id,
    event_type,
    event_timestamp,
    event_properties
from {{ source('raw', 'events') }}
