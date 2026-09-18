# Autonomous Bug-Fixer Harness

An autonomous, multi-agent TDD (Test-Driven Development) harness powered by [Google Antigravity](https://github.com/danieleforberghi/bug-fixer-harness). It isolates bug fixes in disposable Git worktrees, enforces rigorous Red-Green-Refactor quality gates, and automatically submits pull requests upon 100% test verification.

---

## ⚡ Key Capabilities

- **Strict TDD Pipeline**: Guarantees code is driven by tests (**RED** reproduction ➔ **GREEN** implementation ➔ **REFACTOR** parametrization).
- **Zero Working-Tree Pollution**: All work occurs in an ephemeral, isolated Git worktree sandbox (`.worktrees/`).
- **Automated Quality Gate**: Runs `pytest` independently before creating commits or pushing branches.
- **Dual Execution Modes**:
  - **Dynamic Goals**: Quick one-liners that generate scoped goals on the fly.
  - **Curated Goal Specs**: Detailed, version-controlled Markdown specifications stored in `.agent/goals/`.
- **Flexible Execution Timing**: Run immediately or schedule autonomous execution in the background.
- **GitHub Integration**: Automatically opens PRs via `gh` with graceful fallback links.

---

## 🚀 Quickstart & Usage

### Prerequisites
- **Git** & **GitHub CLI (`gh`)** authenticated (`gh auth login`).
- **Python 3.10+** with `pytest`.
- **Google Antigravity CLI (`agy`)** in your `PATH`.

```bash
chmod +x doit.sh
```

---

### 1. Curated Goal Spec Mode (Recommended for Features & Complex Bugs)

Write a detailed markdown spec in `.agent/goals/` (e.g. `.agent/goals/vat-calculation.md`):

```markdown
# Goal: Add VAT calculation function with configurable rates

- **Target Path Scope**: `src/billing`

## Background & Specifications
- Implement `calculate_vat(gross_amount: float, vat_rate: float) -> float` in `src/billing/tax.py`.
- Formula: gross * (rate / (100 + rate)) rounded using ROUND_HALF_UP.
- Reject negative amounts or rates with ValueError.

## Pipeline Steps
1. RED: Failing unit tests in `src/billing/test_tax.py`.
2. GREEN: Implement in `src/billing/tax.py`.
3. REFACTOR: Parametrize rates with @pytest.mark.parametrize.
```

Run immediately:
```bash
./doit.sh .agent/goals/vat-calculation.md
```

Or schedule to run in the background after a delay:
```bash
# Runs autonomously after 5 minutes
./doit.sh .agent/goals/vat-calculation.md --schedule 5
```

---

### 2. Dynamic One-Liner Mode (Quick Fixes)

Generate and execute an autonomous TDD goal on the fly without writing a markdown spec first:

```bash
./doit.sh <target_directory> "<bug_description>"
```

#### Immediate Execution:
```bash
./doit.sh ./src/billing "Fix discount calculation rounding error"
```

#### Scheduled Background Execution:
```bash
# Schedules the job in the background to execute in 10 minutes
./doit.sh ./src/billing "Fix discount calculation rounding error" --schedule 10
```

When scheduled, `doit.sh`:
1. Spawns an autonomous background process detached from the current shell.
2. Streams all output into `.agent/goals/execution-<timestamp>.log`.
3. Displays the PID so you can detach or tail the log:
   ```bash
   tail -f .agent/goals/execution-*.log
   ```

---

## 🛠️ Pipeline Architecture (7-Step Lifecycle)

| Step | Action | Description |
|---|---|---|
| **[1/7]** | **Bootstrap** | Ensures agent personas (`red-agent`, `green-agent`, `refactor-agent`), skills, and `AGENTS.md` are initialized. |
| **[2/7]** | **Goal Resolution** | Loads curated spec from Markdown file or generates scoped dynamic goal file. |
| **[3/7]** | **Worktree Sandbox** | Creates an isolated branch & worktree (`.worktrees/fix/auto-tdd-<timestamp>`). |
| **[4/7]** | **Agent Orchestration** | Runs `agy` headless to execute the RED ➔ GREEN ➔ REFACTOR sequence. |
| **[5/7]** | **Quality Gate** | Executes `pytest` with `PYTHONPATH` set to the sandbox root. Aborts if not 100% green. |
| **[6/7]** | **Push & PR** | Commits changes, pushes branch to GitHub, and creates a Pull Request via `gh`. |
| **[7/7]** | **Cleanup** | Automatically tears down and prunes the worktree sandbox. |

---

## 📂 Repository Structure

```text
├── AGENTS.md                  # Project-wide TDD & import rules for all agents
├── doit.sh                    # Autonomous engine orchestration script
├── src/                       # Production and test source code
│   └── billing/
│       ├── discount.py
│       ├── tax.py
│       ├── test_discount.py
│       └── test_tax.py
├── .agent/
│   ├── agents/                # Agent definitions (red-agent, green-agent, refactor-agent)
│   ├── skills/                # Agent skills (tdd-refactor)
│   └── goals/                 # Curated goal specs (ephemeral logs & temporary goals ignored)
│       └── vat-calculation.md
└── .gitignore                 # Configured to track specs while ignoring run logs & worktrees
```

---

## 📜 License
MIT
