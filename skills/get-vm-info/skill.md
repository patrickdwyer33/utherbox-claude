---
description: Load context for a named child VM by reading its registry directory
---

Read `~/utherbox-vms/{name}/state.md` to get the VM's current state.

```bash
cat ~/utherbox-vms/{name}/state.md
```

Use the contents as context for subsequent work on that VM. If the file doesn't exist, tell the user the VM isn't registered and suggest running `setup-child-vm`.
