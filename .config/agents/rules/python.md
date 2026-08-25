---
description: Python coding conventions for .py files and pyproject.toml.
paths:
  - "**/*.py"
  - "**/pyproject.toml"
---

# Python

- CLIs take `typer`.
- Logging goes through `loguru`.
- Tests are `pytest` — plain asserts, fixtures over setup methods.
- Dataframes are `polars`.
- Linting, formatting and typing are the astral tools: `ruff`, `ty`; `uv` for envs and deps.

Where the project already uses or specifies an alternative, it wins.
