---
description: Delete a child VM and clean up its DNS records
---

## Steps

### 1. Stop running services on the child VM (if reachable)
```bash
ssh claude@<ip> "sudo systemctl stop nginx caddy 2>/dev/null; sudo systemctl disable nginx caddy 2>/dev/null; true"
```
This is best-effort. If the VM is unreachable, skip to deletion.

### 2. Find and delete DNS records pointing to this VM's IP
```
list_dns_records()
```
For each record where `content` matches the VM's IP:
```
delete_dns_record(record_id: "<id>")
```

### 3. Delete the VM
```
delete_vm(vm_id: "<id>")
```
Returns immediately. Deletion is async.

### 4. Confirm deletion
```
get_vm(vm_id: "<id>")
```
Wait for `status: "deleted"`. If `status: "error"` after 5 minutes, note it — the Linode instance may have already been cleaned up.

### 5. Update ~/CLAUDE.md
Remove the child VM entry that was added by `setup-child-vm`.
