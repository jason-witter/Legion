# Scratch Path Resolution

`scratch/` resolves to the framework repo, never the product working directory. Before writing, resolve the absolute path from the framework repo's additionalDirectory registration, use absolute paths for every file operation, and create the output directory if missing. The product repo never gains a `scratch/` directory from agent output.

Good: `/Users/.../<framework-repo>/scratch/output/_<slug>/a.md`
Bad: `/Users/.../webapp/scratch/output/_<slug>/a.md`
