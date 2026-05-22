# Scratch Path Resolution

`scratch/` is a framework-repo directory. All scratch output resolves to the framework repo, not the product working directory.

Before writing to any `scratch/` path, resolve the absolute path from the framework repo's additionalDirectory registration. The product repo (e.g., `webapp/`) must never contain a `scratch/` directory created by agent output.

## Examples

Good — resolved against the framework repo:

```
Write: /Users/.../<framework-repo>/scratch/output/2026-03-20/designs/feature.md
```

Bad — resolved against the product working directory:

```
Write: /Users/.../webapp/scratch/output/2026-03-20/designs/feature.md
```
