# Verify Before Failing or Clearing

Two directions of one rule: a single check, trusted past its reach. Declaring a failure requires an independent second check; clearing a finding requires an independently re-derived basis.

## Declaring failure

When a tool returns an empty or unexpected result, do not build a failure narrative on a single check. Confirm with a second method (different tool, different path, different identifier) before reporting that something is broken. A glob miss is not proof files do not exist; a blank query result is not proof the row was never written; a connection error from one host is not proof the service is down; a subagent reporting no output file is checked with `ls` before concluding the agent failed. Do not propose fixes for a problem that has not been verified to exist.

## Clearing or downgrading

Re-derive the basis of a clearance independently. A finding is cleared or downgraded on the strength of what the reviewer verifies directly, not on a correctness it inherits from somewhere else: a reference pattern's correctness, a pre-change invariant's altitude, or a control's stated purpose.

### The four disciplines

**1. Audit the reference, not just the change.** When a finding is cleared because the fix mirrors an existing pattern, the reference pattern is in scope. Audit it for the same defect class the finding raised. Consistency with existing code establishes that the change matches the reference; it does not establish that the reference is correct. Mirroring a defective reference propagates the defect under the banner of "follows the existing pattern."

**2. Re-derive the invariant at the altitude the change introduces.** When a change adds fan-out, concurrency, or multiplicity, the invariant must hold at the new altitude, not the old one. Verify the aggregate property the multiplicity creates: counter and total accuracy, ordering, mutual exclusion, idempotency under retry. Per-unit correctness, verified one instance at a time, does not establish aggregate correctness across all instances running together.

**3. Trace the control through the real execution model.** When a finding is downgraded because a compensating control exists, follow that control through the execution model the code actually runs under, including concurrent and interleaved paths. "A control exists" is a claim about the code's surface. "The control holds under this execution model" is the claim the downgrade depends on, and only tracing establishes it.

**4. Enumerate the realizations of a risk class; one test does not discharge the class.** A single valid, feature-exercising test covers one realization of a named risk, not the class. List the distinct ways the risk manifests and confirm each is covered. (Coverage is distinct from validity; `protocols/test-quality.md` governs validity.)

## Example

Good, the reference is audited before the clearance stands:

```
Finding: new writer omits the dedup guard.
Author: matches the existing writer in ingest.py, which also omits it.
Reviewer: pulled ingest.py. The existing writer omits the guard too and double-writes
under retry; the reference is defective. Finding stands for both sites.
```

Bad, the reference's correctness is inherited:

```
Finding: new writer omits the dedup guard.
Author: matches the existing writer in ingest.py.
Reviewer: confirmed it matches the existing pattern. Cleared.
```

The bad example clears on a basis the reviewer never derived. The defect ships wearing the clearance.
