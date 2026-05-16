# Stage 2 — Trace consumers (transitive lineage traversal)

## What this stage does

Builds a complete dependency graph of the repo, then traverses it forward from the changed object to find every impacted consumer — direct AND transitive. The output is an impact tree showing the full propagation path for each affected file.

This is not a grep for the changed column name. It is a graph traversal. A file that never mentions the changed column may still be in the blast radius because it reads from a model that reads from a model that contains that column.

## Input
- The changed object (table/model name and column, if applicable) from Stage 1
- The repo root (default: cwd)

## Algorithm

### Phase 1 — Build the dependency graph

#### Step 1 — Repo size check

Run a single `find` to count candidate files (all `.sql`, `.py`, `.yml`, `.yaml`, `.ipynb`, `.ts`, `.tsx`, `.js`, `.jsx`, `.java`, `.kt`, `.go`, `.rb`, `.json`, `.toml` files, excluding `.git`, `node_modules`, `.venv`, `dist`, `build`, `__pycache__`):

```bash
find <repo_root> -type f \( -name "*.sql" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" \
  -o -name "*.ipynb" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
  -o -name "*.java" -o -name "*.kt" -o -name "*.go" -o -name "*.rb" \
  -o -name "*.json" -o -name "*.toml" \) \
  | grep -vE "(\.git|node_modules|\.venv|/dist/|/build/|__pycache__)" \
  | wc -l
```

Announce: `Repo contains N candidate files.`

- **N ≤ 300 → small-repo mode:** read every file upfront to build the full graph (see below), then go to Phase 2.
- **N > 300 → large-repo mode:** build the graph lazily via BFS-grep (see below), then go to Phase 2.

---

#### Extraction rules (used in both modes)

For each file read, extract the following using these rules per file type:

- **What it reads (inputs)**: every table, model, or data source it depends on
- **What it produces (output)**: the table, model, or view this file creates or represents
- **SELECT * flag**: whether it uses `SELECT *` or `SELECT alias.*` from an upstream source

**dbt models** (`*.sql` containing `{{ ref() }}` or `{{ source() }}`):
- Inputs: every `ref('model_name')` and `source('schema', 'table')`
- Output: filename without `.sql`
- SELECT * flag: true if file contains `select *` or `select [alias].*` from a ref/source

**Raw SQL** (`.sql` without dbt jinja, or `CREATE VIEW` / `CREATE TABLE`):
- Inputs: table names in `FROM <name>`, `JOIN <name>`, `INSERT INTO <name> SELECT ... FROM <other>`
- Output: name from `CREATE VIEW <name>` or `CREATE TABLE <name>` (if present)

**Python** (`.py`):
- Inputs: `spark.read.table(...)`, `pd.read_sql(...)`, `pd.read_sql_table(...)`, SQLAlchemy `Table(...)`, raw SQL strings, f-strings with SQL patterns
- Outputs: `df.write.saveAsTable(...)`, `df.to_sql(...)`, `spark.sql("INSERT INTO ...")`, `spark.sql("CREATE TABLE ...")`

**Notebooks** (`.ipynb`):
- Parse the `source` array of every `"cell_type": "code"` cell, concatenate to a string, apply Python rules

**Airflow / orchestration YAML and Python DAGs**:
- YAML: table names in `sql:`, `source_table:`, `target_table:`, `table:`, `dataset:`, `op_kwargs` keys
- Python DAGs (files with `from airflow`): `sql=`, `source_table=`, downstream table references
- **CRITICAL — callable-based tasks**: if a DAG task has `python_callable: some_fn`, the DAG is DOWNSTREAM of the callable file, not a sibling. Chain is `table → callable_file → dag_file`. Do NOT draw a direct edge from the table to the DAG.

**TypeScript / JavaScript** (`.ts`, `.tsx`, `.js`, `.jsx`):
- Inputs: SQL template literals, Knex `.from()`/`.table()`, Prisma `prisma.model.findMany()` (camelCase → snake_case), Sequelize `Model.findAll()`

**Java / Kotlin** (`.java`, `.kt`):
- Inputs: JDBC strings, Hibernate `@Table(name=...)`, `@Query(...)`, MyBatis `<select>` tags

**Go** (`.go`):
- Inputs: `db.Query(...)`, `db.Exec(...)`, GORM `db.Table(...)`, `db.Model(&Struct{})`

**Ruby** (`.rb`):
- Inputs: ActiveRecord `Model.from(...)`, `.joins(...)`, `connection.execute(...)`

**Config / manifest** (`.yml`, `.yaml`, `.json`, `.toml`):
- Keys: `table:`, `source_table:`, `target_table:`, `dataset:`, `table_name:`, `entity:`, `model:`

Build the graph as an adjacency list:

```
dependency_graph[output_name] = [
  { file: "path/to/consumer.ext", stack: "dbt|python|...", select_star: bool, output_name: "name_this_file_produces" }
]
```

---

#### Small-repo mode (N ≤ 300)

Read every candidate file. Extract inputs/outputs using the rules above. Build the complete `dependency_graph`. Announce when done: `Graph complete. N files read, M consumer edges found.`

---

#### Large-repo mode (N > 300) — BFS-grep

Build the graph lazily. Only read files that grep confirms reference a known node. Never silently skip — every unread file is explicitly accounted for.

**Initialize:**
```
frontier   = { seed_object_name }   # names to search for in this wave
visited    = { seed_object_name }   # all names ever added to frontier
files_read = {}                     # path → extracted metadata
```

**BFS loop — repeat until frontier is empty:**

1. Run one grep across all candidate files for every name in `frontier`:
   ```bash
   grep -rlE "<name1>|<name2>|..." <repo_root> \
     --include="*.sql" --include="*.py" --include="*.yml" --include="*.yaml" \
     --include="*.ipynb" --include="*.ts" --include="*.tsx" --include="*.js" \
     --include="*.json" --include="*.toml" \
     | grep -vE "(\.git|node_modules|\.venv|/dist/|/build/|__pycache__)"
   ```
   Announce: `Wave N: searching for [name1, name2, ...] — grep matched M files.`

2. For each matched file not already in `files_read`:
   - Read the file
   - Extract inputs, output, SELECT * flag using the rules above
   - Add edges to `dependency_graph`
   - Add to `files_read`

3. Collect every new output name discovered this wave that is not already in `visited`. Add them to `visited`. These become the next `frontier`.

4. If `frontier` is empty, stop.

**After the loop — transparency report:**

Run the same `find` from Step 1 to get the full candidate file list. Compute:
- `files_read`: files grep matched and were read
- `files_excluded`: candidate files not in `files_read`

Announce:
```
Graph complete.
  Files read:     N (matched at least one traversed node name)
  Files excluded: M (no string match for any node in the traversal)
  Dynamic SQL warning: files with runtime-constructed table names cannot be detected by static analysis — review manually if applicable.
```

A file in `files_excluded` contains no static string matching any model or table name discovered during traversal. It is not in the blast radius based on static analysis. The only undetectable case is dynamic SQL (e.g., `table = "dim_" + var`) — flag this in the Stage 2 artifact summary.

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
