# 📸 SQL Query Result Exports

This folder contains the **executed output of every SQL statement** in the parent directory.

Because the queries are written for **MySQL 8**, they were executed here against a SQLite copy of
`data/marketing_campaign_cleaned.csv` (identical schema and values). Every statement was first
syntax-validated with a MySQL parser, so the `.sql` files are safe to run unchanged against MySQL.

## Files

| Prefix | Source | Contents |
|--------|--------|----------|
| `01_database_setup__*` | `01_database_setup.sql` | Row counts, sample rows and schema verification |
| `02_data_cleaning__Q01..Q12` | `02_data_cleaning.sql` | The 12 data-quality audit queries — all return **0 offending rows** on the cleaned dataset |
| `03_business_queries__Q01..Q30` | `03_business_queries.sql` | The 30 business queries with their full result sets |

Each file contains the query, its purpose comment, the number of rows returned and the result table.

## Notes

* Statements that are MySQL-only DDL (`CREATE DATABASE`, `USE`, `CREATE INDEX`,
  `CREATE OR REPLACE VIEW`, `information_schema` queries) are syntax-checked but not executed here.
* A handful of rows in the raw extract are shown by the cleaning queries; on the **cleaned** dataset
  every audit query returns zero rows, which is the acceptance criterion.

## Reproducing

```bash
mysql -u root -p campaign_pulse_db < ../03_business_queries.sql
```
