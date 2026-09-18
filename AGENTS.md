# AGENTS.md
## Core TDD Guidelines
- **RED**: Write failing tests before modifying implementation code.
- **GREEN**: Make minimal edits to pass the test.
- **REFACTOR**: Consolidate stacked tests into parameterized tables (@pytest.mark.parametrize) per DRY principles.
- **IMPORTS**: Always import modules assuming repository root is on PYTHONPATH (e.g., `from src.billing.discount import ...`).
