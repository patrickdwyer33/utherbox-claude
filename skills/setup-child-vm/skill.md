---
description: Provision a new VM in this project and connect to it
---

Use this skill when the user needs a separate VM (e.g. for a worker, database server, or isolated service).

## Steps

### 1. Check limits first
```
get_limits()
```
Confirm `vm_count < max_vms`. If at the limit, inform the user before proceeding.

### 2. Provision the VM
```
create_vm(
  name: "<descriptive-name>",
  instance_type: "g6-nanode-1",   # cheapest; adjust based on get_limits().allowed_instance_categories
  region: "<same-region-as-this-vm>",  # keep latency low
)
```

### 3. Poll until ready (status transitions: provisioning → ready)
```
get_vm(vm_id: "<id>")
```
Poll every 30 seconds. `provisioning` is normal for 2–4 minutes. `error` means provisioning failed — report to the user. Do not SSH until status is `ready`.

### 4. Get connection details
```
get_vm_connection(vm_id: "<id>")
```
Returns `host`, `port`, `user`, `instructions`.

### 5. Test SSH connectivity
```bash
ssh -o StrictHostKeyChecking=no claude@<ip> "hostname"
```
The project keypair is pre-installed — this should succeed without a password prompt. Allow up to 2 minutes after `ready` for cloud-init to finish.

### 6. Note the child VM in ~/CLAUDE.md
Append to `~/CLAUDE.md`:
```markdown
## Child VM: <name>
- VM ID: <uuid>
- IP: <public_ip>
- Status: ready
- Remote session: (check get_vm after setup completes)
```

## Error handling
- **SSH refuses connection after ready**: cloud-init may still be running. Wait 60s and retry.
- **Provisioning stuck for > 10 min**: call `get_vm` — if still `provisioning`, something is wrong. Report the VM ID to the user so they can contact support.
- **VM limit reached**: inform the user. They can delete an existing VM with `delete_vm` first.
