# Verify Before Failing or Clearing

Declaring a failure requires an independent second check. When a tool returns an empty or unexpected result, confirm with a second method (different tool, different path, different identifier) before reporting that something is broken. A glob miss is not proof files do not exist; a blank query result is not proof the row was never written; a connection error from one host is not proof the service is down; a subagent reporting no output file is checked with `ls` before concluding the agent failed. Do not propose fixes for a problem that has not been verified to exist.

Clearing or downgrading a finding requires an independently re-derived basis. The disciplines live in `protocols/finding-disposition.md`; read it before clearing one.
