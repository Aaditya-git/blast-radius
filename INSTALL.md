# Installation

## Requirements

- Claude Code CLI (any version)
- A git repo containing dbt, SQL, Python, notebook, or Airflow YAML files

## Install via Claude Code (recommended)

```bash
claude plugins install github:Aaditya-git/blast-radius
```

That's it. No npm install, no config file, no cloud integration.

## Manual install (alternative)

```bash
git clone https://github.com/Aaditya-git/blast-radius
cd blast-radius

# Symlink (picks up updates automatically)
ln -s "$(pwd)/skills" ~/.claude/skills/blast-radius
```

Restart Claude Code after installing.

## Invoke the skill

Open Claude Code in your repo and describe what you want to change:

```
> Use the blast-radius skill. I want to rename column customer_age to customer_age_years in stg_customers.
```

Or trigger it implicitly — the skill activates on phrases like:
- "what depends on this model?"
- "blast radius of dropping orders_v1"
- "what will break if I change the grain of dim_customers?"

## What happens

Claude confirms the change details, then runs five stages. After each stage it pauses and asks "continue?" You can stop at any point, edit the artifact, or rerun a stage.

Artifacts are written to:
```
docs/data-changes/<YYYY-MM-DD>-<change-slug>/
├── 01-change-classification.md
├── 02-consumer-inventory.md
├── 03-risk-assessment.md
├── 04-migration-plan.md
└── 05-stakeholder-comms.md
```

Commit this folder — it shows up in your PR and forms a permanent audit trail.

## Dry run mode

Add "dry run" to your request and Claude will print the artifacts to the session instead of writing them to disk:

```
> Use the blast-radius skill, dry run. I want to drop model orders_v1.
```

## Single-stage mode

You can invoke a single stage:

```
> Use the blast-radius skill, Stage 2 only. What depends on stg_customers?
```

## Uninstall

```bash
# If installed via claude plugins
claude plugins uninstall blast-radius

# If installed manually
rm -rf ~/.claude/skills/blast-radius
```
