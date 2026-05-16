# Stage 2 — Trace consumers (transitive lineage traversal)

## What this stage does

Builds a complete dependency graph of the repo, then traverses it forward from the changed object to find every impacted consumer — direct AND transitive. The output is an impact tree showing the full propagation path for each affected file.

This is not a grep for the changed column name. It is a graph traversal. A file that never mentions the changed column may still be in the blast radius because it reads from a model that reads from a model that contains that column.

## Input
- The changed object (table/model name and column, if applicable) from Stage 1
- The repo root (default: cwd)

## Algorithm

### Phase 1 — Build the full dependency graph

Scan every non-trivial file in the repo. Exclude: `.git`, `node_modules`, `.venv`, `dist`, `build`, `__pycache__`, `*.lock`, `*.log`.

For each file, extract:
- **What it reads (inputs)**: every table, model, or data source it depends on
- **What it produces (outputs)**: the table, model, or view this file creates or represents
- **SELECT * flag**: whether it uses `SELECT *` or `SELECT alias.*` from an upstream source

Use these extraction rules per file type:

#### dbt models (`*.sql` containing `{{ ref() }}` or `{{ source() }}`)
- **Inputs**: every `ref('model_name')` → the model name; every `source('schema', 'table')` → the table name
- **Output**: the filename without `.sql` — this becomes the referenceable model name downstream
- **SELECT * flag**: true if file contains `select *` or `select [alias].*` from a ref/source

#### Raw SQL (`.sql` without dbt jinja, or files with `CREATE VIEW` / `CREATE TABLE`)
- **Inputs**: every table name in `FROM <name>`, `JOIN <name ON`, `INSERT INTO <name> SELECT ... FROM <other>`
- **Output**: name from `CREATE VIEW <name>` or `CREATE TABLE <name>` (if present)

#### Python (`.py`)
- **Inputs**: extract table/model names from:
  - `spark.read.table("db.table")` or `spark.read.table("table")`
  - `pd.read_sql("... FROM table ...", engine)` — parse the SQL string for table names
  - `pd.read_sql_table("table", engine)`
  - SQLAlchemy `Table("table", metadata)` or `session.query(ModelClass)` — map class name to snake_case table name
  - Raw SQL strings assigned to variables: `sql = "SELECT ... FROM table"`
  - f-strings and template strings with SQL patterns
- **Outputs**: extract table/model names from:
  - `df.write.saveAsTable("table")`
  - `df.to_sql("table", engine)`
  - `spark.sql("INSERT INTO table ...")` or `spark.sql("CREATE TABLE table AS ...")`

#### Notebooks (`.ipynb`)
- Parse the `source` array of every cell with `"cell_type": "code"`, concatenate to a string
- Apply the same Python extraction rules to the result
- Inputs and outputs: same as Python rules above

#### Airflow / orchestration YAML and Python DAGs
- **YAML**: look for table names in `sql:` fields, `source_table:`, `target_table:`, `table:`, `dataset:`, `op_kwargs` keys
- **Python DAGs** (`.py` with `from airflow`): look for `sql=`, `source_table=`, `provide_context=True` with downstream table references
- **Task dependencies**: if a task triggers a callable that reads/writes a table, inherit those I/O relationships
- **CRITICAL — graph position for callable-based tasks**: if a DAG task references a `python_callable` (e.g., `python_callable: extract_age_features`), the DAG is DOWNSTREAM of that callable file in the dependency graph — not a sibling. Do NOT treat the DAG's `source_table` or `op_kwargs` table references as a direct edge from the table to the DAG. The correct chain is: `table → callable_file → dag_file`. The DAG's output in the graph is whatever the callable writes. If the callable is also in the repo, add the edge `callable_output → dag_file`. If the callable is not in the repo (external), treat the DAG's table references as direct inputs.

#### TypeScript / JavaScript (`.ts`, `.tsx`, `.js`, `.jsx`)
- **Inputs**: table names in:
  - Template literals containing SQL: `` `SELECT ... FROM tablename` ``
  - Knex: `.from('table')`, `.table('table')`, `.join('table', ...)`
  - Prisma: `prisma.modelName.findMany()` — map camelCase model name to snake_case table
  - Raw SQL strings: `'SELECT ... FROM table'`
  - Sequelize: `Model.findAll()` — map model class to table

#### Java (`.java`, `.kt`)
- **Inputs**: table names in:
  - JDBC strings: `"SELECT ... FROM table"`
  - Hibernate/JPA `@Table(name = "table")` or `@Entity` with class name mapped to table
  - `@Query("SELECT ... FROM table")` annotations
  - MyBatis XML mapper `<select>` tags with table names

#### Go (`.go`)
- **Inputs**: table names in:
  - `db.Query("SELECT ... FROM table")`, `db.Exec("INSERT INTO table ...")`
  - GORM: `db.Table("table")`, `db.Model(&StructName{})` — map struct to snake_case table

#### Ruby (`.rb`)
- **Inputs**: table names in:
  - ActiveRecord: `Model.from("table")`, `joins("JOIN table ON")` — map class name to snake_case table
  - `ActiveRecord::Base.connection.execute("SELECT ... FROM table")`
  - `where("table.column = ?", ...)`

#### Config and manifest files (`.yml`, `.yaml`, `.json`, `.toml`)
- Look for keys that reference table names: `table:`, `source_table:`, `target_table:`, `dataset:`, `table_name:`, `entity:`, `model:`

Build the graph as an adjacency list:

```
dependency_graph[output_name] = [
  { file: "path/to/consumer.ext", stack: "dbt|python|notebook|...", select_star: bool, output_name: "name_this_file_produces" }
]
```

Announce before starting: `Building dependency graph across all file types in <repo_root>...`
Print a running count as you go: `Graph: N objects mapped, M consumer edges found`

### Phase 2 — Seed the blast radius

- **Column rename/drop**: seed = the model/table that contains the changed column
- **Model/table rename/drop**: seed = the model/table name
- **Semantic change (grain, logic)**: seed = the model/table name

Add the seed to the impact set at depth 0.

### Phase 3 — BFS traversal forward through the graph

```
queue = [seed]
impact_set = {
  seed: { depth: 0, path: [seed], via: null, select_star: false }
}

while queue is not empty:
  current_output = queue.pop()
  consumers = dependency_graph[current_output] or []

  for each consumer in consumers:
    if consumer.file not in impact_set:
      depth = impact_set[current_output].depth + 1
      path = impact_set[current_output].path + [consumer.file]
      impact_set[consumer.file] = {
        depth: depth,
        path: path,
        via: current_output,
        select_star: consumer.select_star
      }
      if consumer.output_name exists:
        queue.push(consumer.output_name)  # continue traversal downstream
```

Continue until the queue is empty. If a cycle is detected (output already in path), skip and log as "circular dependency detected."

### Phase 4 — Classify impact for each node

For each file in the impact set:

**Impact type:**
- `DIRECT` — depth 1, file directly reads the changed object
- `TRANSITIVE` — depth 2+, file reads something that reads the changed object (and so on)

**Break classification:**
- `WILL-BREAK` — direct reference to the changed column in SELECT, WHERE, or JOIN (explicit name)
- `SILENT-PROPAGATION` — uses `SELECT *` from an affected upstream; inherits the change invisibly
- `TRANSITIVE-RISK` — depends on a will-break or silent-propagation node; affected if upstream is not migrated first
- `WILL-GO-STALE` — documentation only (schema.yml column entries, comments)

**Column-level check (for column renames/drops only):**
For DIRECT consumers, check whether the file explicitly references the changed column name:
- Explicit reference → `WILL-BREAK`
- No explicit reference but `SELECT *` from affected model → `SILENT-PROPAGATION`
- No explicit reference, no `SELECT *`, but reads affected model → still `TRANSITIVE-RISK` (output table contains the column)

## Output

Write artifact to `docs/data-changes/<slug>/02-consumer-inventory.md`.

### Impact tree

```markdown
## Impact tree

<changed_object>.<column> (CHANGED)
├── <direct_consumer> [<stack>] — DIRECT — <break_classification>
│   ├── <transitive_consumer> [<stack>] — TRANSITIVE depth 2 — <break_classification>
│   │   └── <deeper_consumer> [<stack>] — TRANSITIVE depth 3 — <break_classification>
│   └── <another_transitive> [<stack>] — TRANSITIVE depth 2 — <break_classification>
└── <another_direct> [<stack>] — DIRECT — <break_classification>
```

### Consumer details

For each node in the impact tree:

```markdown
### <filename> (<stack>)
- **Path:** <file path>:<line if applicable>
- **Stack:** <dbt | raw SQL | Python | notebook | orchestration | TypeScript | Java | Go | Ruby | config>
- **Impact:** DIRECT | TRANSITIVE (depth N, via <intermediate model(s)>)
- **Break classification:** WILL-BREAK | SILENT-PROPAGATION | TRANSITIVE-RISK | WILL-GO-STALE
- **Usage:** <SELECT | WHERE | JOIN | SELECT * | DOCUMENTATION | CONFIG>
- **Snippet:** `<most relevant line>`
- **Column explicitly referenced:** Yes | No
```

### Summary

```markdown
## Summary
- Total impacted: <N> files across <N> stacks
- Direct consumers: <N>
- Transitive consumers: <N> (would be missed by simple grep)
- Silent propagation (SELECT *): <N>
- Stacks affected: <list>
- Max impact tree depth: <N>
- Cross-repo consumers: not visible in this search — verify separately
```

## Failure modes

- **Zero consumers found** — state prominently at top: "No consumers found in scope. This does NOT imply safety — cross-repo consumers, BI tools, and external pipelines are outside this search."
- **File parse failure** — log as "parse failed — manual review required" and continue; do not skip silently
- **Circular dependency** — log and break the cycle; note in summary
- **Ambiguous table name** — if a name like `users` or `events` appears across unrelated stacks, flag matches as "may be coincidental — verify manually"
- **Cross-repo consumers** — state in summary: "This search covers the local repo only. Consumers in external repos, BI tools (Tableau, Looker, Metabase), ML platforms, and external APIs are not visible here."
