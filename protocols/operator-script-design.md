# Operator Script Design

Design requirements for scripts an operator runs by hand over a large population: how a pass reports its progress, and, where it both acts on users and notifies them, how it is sequenced.

## Usage

Read when designing, building, or reviewing an operator-run batch, remediation, backfill or migration script. Babbage specifies both requirements in the design and Lovelace builds them, the same as any other interface requirement; Oppenheimer and Friedman check them, and Fagan checks them on an external PR (`pr-review.md` step 4). The orchestrator writing or editing such a script inline, with no pipeline behind it, owns both requirements itself and reads this first. Neither section applies to request-path code.

## Progress reporting

A script an operator runs by hand over a large population, and that takes minutes to hours per pass, reports its progress at a coarse interval and does not narrate every row. The operator watching it needs to know how far along it is and roughly how long is left, and per-row output defeats both: it scrolls the one number they want off the screen and reads as the only sign of life, so its absence during the setup phase reads as a hang.

This binds at design time. Babbage specifies it and Lovelace builds it, the same as any other interface requirement, rather than the operator patching it onto a running pod because they cannot tell a slow pass from a stuck one. It was learned the hard way on a tax-overcharge refund remediation (`refund_overcharged_orders.py`), where a dry pass ran silently through two unpaced bulk reads and then emitted one log line per row across ~200,000 rows, and the operator could not answer "how far along am I" at any point.

### What the script does

- **A progress line at a coarse interval**, every N rows or every few seconds, carrying the counter that tracks real work against the total. Where a pre-filter means the loop walks more rows than it acts on, print both the walked count and the acted count, because their divergence is the pre-filter working and is itself the reassurance.
- **A line when a long silent phase starts**, so the setup reads (bulk queries, population load) that precede the loop are not mistaken for a hang. "Loading 200k records" before a 6-minute query is one print.
- **Per-row detail at debug level, not info**, or to a sink the operator is not watching. The row-by-row record is worth keeping; it is not worth being the foreground.
- **Results in aggregate.** The terminal gets counts grouped by outcome, not one line per item. Nobody reads 50,000 individual results, and printing them buries the summary that the operator actually acts on under a scrollback they cannot search. Per-item results stay in the returned value and in the log sink, where a script or a later query can reach them; the identifiers behind a bucket belong to whoever filters that returned value, not to the screen.
- **A final summary regardless**, which most already have.

### The script owns its foreground, including what its dependencies print

Quieting the script's own logging is not enough. A library called once per item logs once per item, and to the operator that is indistinguishable from the script doing it. Observed on the same remediation: the email step deliberately carries no per-user log line, and the pass still produced a wall of output because the mail sender logs every message it renders, once per user, on a dry pass.

So the check at design time is what the terminal shows for the whole loop body, not what the script's own statements emit. Where a dependency is chatty in a loop, raise its logger's level for the duration of the pass.

### What decides the interval

The interval is a property of the pass's own pace, not a fixed number. Tie it to whichever of wall-clock or row-count gives the operator a read every few seconds at the pass's real throughput, so a fast pass does not flood and a slow one does not go quiet for minutes.

### Scope

Operator-run batch, remediation, backfill and migration scripts over a population large enough that a pass is not instant. Not request-path code, not tasks whose only reader is a log aggregator, not scripts that finish in seconds. The discriminator is whether a human sits watching it run and has to decide, from what it prints, whether it is progressing or wedged.

## Per-user sequencing

When a remediation both acts on a user and notifies them, structure it so each user reaches their end state, the action and the notice, as soon as that user can, rather than running the action for the whole population first and the notice for the whole population after. Phase-batching makes the earliest-acted user wait for the slowest part of a prior whole-population phase before hearing anything, and that silent gap between "we changed something for you" and "we told you" is where a user emails support to ask what happened. The inbound is the cost, and it is avoidable.

Observed on a refund remediation: refunds ran across the whole population as one phase, so the run took about a day, and users refunded in the first hour had no notice until step 2 while they could already see the money move. They proactively emailed in. Ordering by user rather than by phase would have let each notice follow that user's own refund.

### The principle, and its real bound

The notice can only be as prompt as the thing it depends on. A refund the notice speaks for has to settle before the figure is honest, and settlement latency is set by the gateway, not by the run, so this is not a promise of instant notification. It is that the run must not *add* delay on top of that floor by making every user wait out a population-wide phase. Complete the user when the user is completable.

Where a genuine per-user loop is too expensive (a bulk enqueue is far cheaper per item than a serial walk), the fallback is a small batch carried end to end: refund a batch, notify that batch once it settles, then the next, so the notice trails the action by a settle window rather than by the whole population.

### What this shapes at design time

Babbage specifies the ordering and Lovelace builds it. The choice is whether the top-level loop is over phases (`for user: refund; then for user: notify`) or over users (`for user: refund, then notify once settled`), and for a user-visible remediation it is the latter unless a named cost rules it out. A script that only acts, with no user-facing notice, is out of scope; this is about the pairing of an action and the telling.

Independent of ordering, keep the notify step re-runnable and idempotent per user, so a user completed on an early batch is not notified again when a later batch runs, and a user whose action settles late still gets their notice on a later pass.

### Scope

Operator-run remediations, backfills and migrations that both change something for a user and tell them about it. Not internal-only corrections with no user-facing message, and not request-path work.
