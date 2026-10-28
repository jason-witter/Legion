# Test Quality

Every test answers a real failure mode. Name it in one sentence.

Coverage is a separate question from validity: one valid test covers one realization of a risk, not the class. See `protocols/finding-disposition.md`, clearing discipline 4.

Tests that mock the layer under test and assert the mock's response are tautological. They verify that a mock returns what the test told it to return. Coverage rises; signal does not.

## Categories

- **Feature-exercising** — runs the production code path with realistic inputs and asserts an observable outcome (DB row state, returned exception class, side-effect call shape, log content, metric incremented). Prefer.
- **Contract-shape** — asserts a structural property (SQL substring, call arguments). Acceptable when no integration test exists, but catches refactor drift in the asserted surface only.
- **Tautology** — mocks the layer under test and asserts the mock's response. Refuse.
- **Branching-only** — asserts a branch is reached without asserting its consequence. Refuse.
- **Library-semantics** — asserts Python or library behavior (`len()` returns the right number, `bool(True)` is `True`, an `Enum` member equals itself). Refuse.
- **Restated-literals** — asserts a function returns the literal the test reads from the same source. Refuse.

## The removal check

For each new or changed test: if the behavior this test names were removed from the production code, would this test fail?

Answer against the test as written and the code as written, and name what fails: the assertion that breaks, or the observable outcome that changes. "It looks like it would" is not an answer.

The check is orthogonal to the categories. Feature-exercising and contract-shape describe what a test was built to do, and neither survives the production call moving out from under the assertion, so a test can hold its category and still fail this check. Three mechanisms it finds:

- A patch target that still resolves and no longer intercepts. Patching `<consumer_module>.<name>` succeeds whether or not the consumer still calls through its own reference; once the call resolves through the defining module instead, the patch is live, the assertion on it is not, and nothing raises.
- A value the test asserts that a fixture, factory, or default now supplies, so the assertion holds whatever the code under test does.
- A subject that was moved, renamed, or inlined, leaving the assertion pointed at a surface no production path reaches.

A test that fails the check asserts nothing about the behavior it is named for. Its consequence and its tier are owned by `protocols/finding-disposition.md`, which also tiers the case one step earlier: a change that installs one of these mechanisms while every test on it still fails correctly.

Authors run the check before writing the test, by naming what would make it fail. Reviewers run it per test, and the consuming review protocol sets the surface.

## Clusters

Three or more refused-category tests in the same file or against the same surface is a cluster.

A cluster is a signal distinct from its members, and it stands even when each test in it is technically correct: a suite built from shallow tests is nominally green and substantively less informative than the count suggests. Name the pattern, not only the individual tests composing it.

Each consuming station maps a cluster to its own consequence. Review stations map it to severity; the validation station records it as a quality concern.

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
