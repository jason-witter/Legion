# Test Quality

Every test answers a real failure mode. Name it in one sentence.

Tests that mock the layer under test and assert the mock's response are tautological. They verify that a mock returns what the test told it to return. Coverage rises; signal does not.

## Categories

- **Feature-exercising** — runs the production code path with realistic inputs and asserts an observable outcome (DB row state, returned exception class, side-effect call shape, log content, metric incremented). Prefer.
- **Contract-shape** — asserts a structural property (SQL substring, call arguments). Acceptable when no integration test exists, but catches refactor drift in the asserted surface only.
- **Tautology** — mocks the layer under test and asserts the mock's response. Refuse.
- **Branching-only** — asserts a branch is reached without asserting its consequence. Refuse.
- **Library-semantics** — asserts Python or library behavior (`len()` returns the right number, `bool(True)` is `True`, an `Enum` member equals itself). Refuse.
- **Restated-literals** — asserts a function returns the literal the test reads from the same source. Refuse.

## Examples

Good, exercises the real code path and asserts an observable outcome:

```python
def test_reset_inactive_no_ops_when_worker_id_changed():
    job = _start_job(worker_id='worker-1')
    _claim_row_as_reaper(job.id)  # sets worker_id to NULL
    matched = _reset_to_inactive_if_owned(job.id, 'worker-1')
    assert matched is False
    assert WorkflowJob.get_one(job.id).status == WorkflowStatus.INACTIVE
```

Bad, mocks the layer under test and asserts mock-passthrough:

```python
def test_returns_false_when_no_row_matched(mocker):
    mock_db = mocker.patch('app.lib.flask_postgres.billing_database.execute')
    mock_db.return_value.rowcount = 0
    assert _reset_to_inactive_if_owned(1, 'w') is False
```

The bad test sets `rowcount=0`, then asserts the function returns the rowcount-derived value. It passes under any change that preserves the mock contract, including a refactor that drops `WHERE worker_id = :worker_id` from the SQL.

## SQL-shape-sensitive features

SQL substring assertions catch a renamed function. They do not catch a refactor that drops a critical WHERE clause while preserving the substring. Prefer a real-DB integration test or surface the gap explicitly.
