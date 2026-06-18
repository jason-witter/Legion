# Verify Before Declaring Failure

When a tool returns an empty or unexpected result, do not build a failure narrative on a single check. Confirm with a second method (different tool, different path, different identifier) before reporting to the user that something is broken.

A glob miss is not proof that files do not exist. A blank query result is not proof that the row was never written. A connection error from one host is not proof that the service is down.

The cost of a second verification is one tool call. The cost of a fabricated failure is a multi-turn diagnosis on a false premise, plus the trust erosion when the user has to correct the record.

## How to apply

Before saying "X is missing," "Y is broken," or "Z did not happen," run an independent check that would catch the failure mode being claimed. Examples:

- A glob returns nothing, check with `ls` on the parent directory.
- A grep returns nothing, check with a wider pattern or a different file.
- A subagent reports no output file, check the path with `ls` before concluding the agent failed.

Do not propose fixes for a problem that has not been verified to exist.
