# Branch Create Protocol

Create feature branches for mob programming work.

## Branch Naming Convention

Branch naming is established between Friday and the user. If no convention has been set, Friday will ask on first use. Common patterns:

- `feature/description` — generic feature branches
- `initials/description` — personal attribution (e.g. `abc/api-rate-limiting`)
- `type/description` — conventional commits style (e.g. `fix/`, `chore/`)

Use whatever convention the user has established. The examples below use `<prefix>/` as a placeholder.

## Creating a Branch

Two paths exist depending on whether code-producing agents use the main working tree or worktree isolation. The deployment-specific rule determines which path applies.

**Main-tree path** — branch is checked out in the main working tree:

```bash
# Ensure you're on latest main
git checkout main
git pull origin main

# Create feature branch
git checkout -b "<prefix>/your-descriptive-name"
```

**Worktree path** — branch is created in an isolated worktree; main working tree is not disturbed:

```bash
# Fetch all refs
git fetch origin

# Create worktree on a new branch from remote main
git worktree add -b "<prefix>/your-descriptive-name" <worktree-path> origin/main
```

The worktree path must be an absolute path outside the main repo directory (e.g., a sibling directory).

## Branch Name from Task Name

Convert a task name to branch-safe format:
```bash
# Example: "Implement Unique Ratio Alert for Vertex"
# Becomes: "<prefix>/implement-unique-ratio-alert"

TASK_NAME="Your Task Name"
BRANCH_NAME=$(echo "$TASK_NAME" | \
  tr '[:upper:]' '[:lower:]' | \
  sed 's/[^a-z0-9]/-/g' | \
  sed 's/--*/-/g' | \
  sed 's/^-//;s/-$//' | \
  cut -c1-50)

git checkout -b "<prefix>/$BRANCH_NAME"
```

## Push to Remote

Push requires user approval per `rules/git-integration-gates.md`.

```bash
# Push and set upstream
git push -u origin "<prefix>/your-descriptive-name"
```

## Typical Workflow

**Main-tree path:**

```bash
# 1. Start from clean main
git checkout main
git pull origin main

# 2. Create feature branch
git checkout -b "<prefix>/feature-name"

# 3. Do work (mob implements in main working tree)
# ... code changes ...

# 4. Commit work (stage specific files, not git add .)
git add path/to/changed/file.py path/to/other/file.py
git commit -m "Implement feature"

# 5. Push to remote (requires user approval per git-integration-gates)
git push -u origin "<prefix>/feature-name"
```

**Worktree path:**

```bash
# 1. Fetch all refs
git fetch origin

# 2. Create worktree on new branch from remote main
git worktree add -b "<prefix>/feature-name" <worktree-path> origin/main

# 3. Do work (mob implements in worktree)
# ... code changes committed inside worktree ...

# 4. Squash commits in worktree, then remove worktree
#    (inside worktree) git reset origin/main && git commit -m "Implement feature"
git worktree remove <worktree-path>

# 5. Push to remote (requires user approval per git-integration-gates)
git push -u origin "<prefix>/feature-name"
```

## Branch Cleanup (After Merge)

```bash
# Delete local branch
git branch -d "<prefix>/feature-name"

# Delete remote branch
git push origin --delete "<prefix>/feature-name"
```

## Notes

- Always create from latest main (main-tree: `git pull`; worktree: `git fetch origin` then create from `origin/main`)
- Use descriptive names (what the branch does, not the task ID)
- Keep branch names under 50 characters
- Push when ready (gated — requires user approval)
- Branches are ephemeral — delete after merge
- Worktree paths must be outside the main repo directory
