# External Fetch — Integration Protocol Interface Contract

Defines what a conformant integration protocol looks like. Grace uses whatever integration protocols are installed; this contract ensures they're consistent so orchestrators and agents can treat them interchangeably.

This is a framework primitive — not a runnable protocol, but the specification other integration protocols must conform to.

---

## Required Sections

Every integration protocol must include the following, in this order:

### 1. Title and one-line description

State what the protocol retrieves and from where in a single sentence.

### 2. Prerequisites

Document every external dependency before showing any code:
- Environment variables that must be set
- External CLI tools required (e.g., `jq`, `curl`)
- API access or permissions required

If the protocol has no external dependencies beyond the service itself, state that explicitly.

### 3. Usage

One or more runnable code blocks covering the primary fetch operation. Code must be copy-pasteable — no pseudocode, no unresolved placeholders in runnable sections.

### 4. Output Format

Describe what the protocol produces. Downstream agents depend on this being predictable. Define it even if the answer is "raw JSON from the API."

### 5. Error Handling

Cover at minimum: missing credentials, empty results, and API errors. Describe what failure looks like and what the caller should expect.

---

## Credential and Config Handling

All credentials must come from environment variables. Never hardcode tokens, API keys, or service-specific IDs.

Naming convention: `<SERVICE>_<CREDENTIAL_TYPE>` in uppercase (e.g., `GITHUB_TOKEN`, `JIRA_API_TOKEN`).

Optional configuration should also use environment variables with sensible defaults:
```bash
BASE_URL="${MYSERVICE_BASE_URL:-https://api.myservice.com}"
```

Never read credentials from files, prompt for them interactively, or embed workspace/project IDs as constants — these belong in environment variables or should be discovered dynamically.

---

## Expected Output Contract

Integration protocols are consumed by orchestrators and agents that need to act on the results:

1. **Deterministic in structure** — the same query always produces the same shape of output
2. **Minimal by default** — return only what downstream agents need; avoid raw API dumps unless specifically required
3. **Line-oriented for lists** — when returning multiple items, one item per line with a clear identifier so output can be parsed without additional tooling
4. **Structured for detail views** — when returning a single resource with multiple fields, use a consistent structured format

If a protocol supports both list and detail modes, document them separately.

---

## Conformance Checklist

Before publishing a new integration protocol:

- [ ] Title and one-line description present
- [ ] All required environment variables listed in Prerequisites
- [ ] At least one runnable code block in Usage
- [ ] Output Format section present and accurate
- [ ] Error Handling covers missing credentials and empty results
- [ ] No hardcoded tokens, IDs, or API keys
- [ ] Code is copy-pasteable without modification
