# Scratch Path Resolution

`scratch/` is a Legion directory. All scratch output resolves to the Legion repo, not the product working directory.

Before writing to any `scratch/` path, resolve the absolute path from the Legion additionalDirectory registration. The product repo (e.g., `webapp/`) must never contain a `scratch/` directory created by agent output.

## Examples

Good — resolved against Legion:

```
Write: /Users/.../Legion/scratch/output/2026-03-20/designs/feature.md
```

Bad — resolved against the product working directory:

```
Write: /Users/.../webapp/scratch/output/2026-03-20/designs/feature.md
```
