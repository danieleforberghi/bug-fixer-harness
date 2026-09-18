---
name: tdd-refactor
description: Executes a full RED-GREEN-REFACTOR loop on a specified directory.
---
1. RED: Write a failing unit test in the target module.
2. GREEN: Apply minimal fix in implementation code.
3. REFACTOR: Merge duplicate tests into `@pytest.mark.parametrize` matrices.
