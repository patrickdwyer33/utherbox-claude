---
description: Handle tasks requiring root or sudo by offering to migrate work to a child VM
---

You have no sudo access on this VM. When a task requires root or sudo:

## When This Applies

Any task needing `sudo`, root access, system package installation, binding ports below 1024,
writing to system paths, or modifying kernel/system configuration.

## What To Do

1. **Stop** — do not attempt the root-requiring action

2. **Ask the user** — explain specifically what needs root and why, then ask:
   > "This requires root access, which I don't have on this VM. I can spin up a child VM
   > and continue working from there. Should I do that, or would you prefer a different approach?"

3. **If the user declines** — drop the approach requiring root entirely and discuss alternatives.
   Do not provision a VM.

4. **If the user confirms:**
   - Provision a child VM using the `create_vm` tool (vm-networking MCP server)
   - SSH into the child VM
   - Reconstruct the working context: clone any relevant repos, copy in-progress files
   - Continue all subsequent work from the child VM
   - Treat the child VM as the new working base for this task and everything that follows,
     unless the user explicitly says to return to the main VM

5. **Record the migration** — append to `~/CLAUDE.md` on this (main) VM so future Claude
   sessions know where work has moved:

   ```markdown
   ## Active work moved to child VM
   - VM: <name> (<ip>)
   - Moved: <YYYY-MM-DD>
   - Reason: <what specifically needed root>
   - Resume: SSH into the child VM and continue from ~/
   ```
