# Stage 1 — Clarifying Question Required

## Ambiguity detected

The change description "I want to change the customers table" does not specify what is changing. Without knowing the specific change, Stage 1 cannot classify severity or surface, and Stage 2 cannot know what to search for.

## Question

**What specifically about the `customers` table are you changing?**

Options:
- **A column name or type** (e.g., renaming `email` to `email_address`, changing `age` from INT to FLOAT)
- **The table/model itself** (e.g., renaming `customers` to `dim_customers`, dropping the table)
- **The grain** (e.g., changing from one-row-per-customer to one-row-per-household)
- **The business logic** (e.g., changing how `lifetime_value` is calculated)
- **The data source or location** (e.g., moving from `raw.customers` to `curated.customers`)

Please specify the change and this skill will proceed with classification.
