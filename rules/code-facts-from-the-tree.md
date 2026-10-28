# Code Facts Come From the Tree

The codebase is the only authority on what the codebase does. A document's assertion of a code fact is a pointer: follow it before acting on the claim or repeating it. This holds for every document, including a current, authoritative spec.

## The split inside a spec

- **Directives bind.** Implement this interface. This finding is Blocking. This approach was rejected.
- **Code claims are pointers.** "`refund_payment` takes no `amount` parameter." "The flag is checked at `pricing.py:873`." Read the cited location before relying on it.

What decides it is what the sentence is about, not its tone: a directive is about the work, a code claim is about the tree.

## Authoring

Carry `path:line` on every code claim. Report an uncited code claim as unverified, not as established.

## When a document and the tree disagree

The tree wins. Surface the disagreement rather than routing around it.
