# Project instructions for Claude Code

## Stack
- Backend: Django (mssql-django + pyodbc)
- Database: SQL Server, managed via SSMS. Chris (the user) is the DBA — schema
  changes originate in SSMS/schema.sql, not Django migrations.
- Django models for existing SQL Server tables should always be created with
  `managed = False` in their Meta class.

## Changelog rule (always follow this)
Every time you make a change to this project — new file, edited file, schema
change, dependency added, bug fix, config change — append an entry to
`CHANGELOG.md` at the project root, under an `## Unreleased` heading, newest
entry at the top of that section. Format:

```
- YYYY-MM-DD HH:MM - <one-line summary of what changed and why>
```

Do this as part of the same turn you make the change, not as a separate
follow-up step. If `CHANGELOG.md` doesn't exist yet, create it with this
structure first.

## Git workflow
- Ask before running `git push` unless the user explicitly says to push.
- Use descriptive commit messages that match the CHANGELOG.md entry for that
  change.

## Schema changes
- If a task requires a new table or column, write the DDL as a new .sql file
  (don't silently rely on Django to create tables) and tell the user to run it
  in SSMS. Then update the corresponding Django model with `managed = False`
  once it exists.
