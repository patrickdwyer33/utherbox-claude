---
description: Start a new project — optionally on a child VM — with a working directory, git repo, and standard docs
---

## Step 1: Determine where the project lives

Ask the user:
> "Where do you want to set this up — here on the project VM, or on a fresh child VM?"

| Answer | Action |
|--------|--------|
| Here / project VM | continue to Step 2 in `~/projects/{name}/` |
| Child VM / new VM | run `setup-child-vm` skill first, then SSH in and continue Step 2 there |
| Unsure | suggest a child VM if the project needs root, a web server, or its own network identity; otherwise here is fine |

## Step 2: Get project details

Ask for anything not already provided:

| # | What | Notes |
|---|------|-------|
| 1 | **Project name** | used as directory name |
| 2 | **What it is** | one sentence — used to seed README and CLAUDE.md |
| 3 | **Language / stack** | optional — skip boilerplate if not provided |

## Step 3: Scaffold

```bash
mkdir -p ~/projects/{name}
cd ~/projects/{name}
git init
```

Create the following files:

**`README.md`**
```markdown
# {name}

{one-line description}
```

**`CLAUDE.md`**
```markdown
# {name}

{one-line description}

## Stack
{stack if provided, otherwise omit section}

## Notes
<!-- add context here as the project evolves -->
```

**`TASKS.md`**
```markdown
# Tasks

<!-- tasks go here -->

---

# Completed
```

**`TODO.md`** — empty file for scratchpad notes

## Step 4: Initial commit

```bash
git add .
git commit -m "chore: initial project scaffold"
```

## Step 5: Capture follow-up work

If the user mentioned anything else alongside the project creation request, add it as a task in `TASKS.md` rather than doing it now. Only create a task if there's enough to write a meaningful goal. Skip vague items and note them to the user.

## Step 6: Confirm and offer next step

> Project `{name}` is ready at `~/projects/{name}`.
>
> Would you like to start on a task, or is there something specific you want to set up first?

## Notes

- Do not scaffold language-specific boilerplate unless the user asks — just the docs
- If on a child VM, update `~/utherbox-vms/{vm-name}/state.md` on the project VM with a note about what's deployed there
- Never push to a remote unless the user asks
