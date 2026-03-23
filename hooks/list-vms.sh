#!/usr/bin/env bash
# UserPromptSubmit hook — lists registered child VM names.

VM_DIR="$HOME/utherbox-vms"

if [ ! -d "$VM_DIR" ] || [ -z "$(ls -A "$VM_DIR" 2>/dev/null)" ]; then
  exit 0
fi

echo "<system-reminder>"
echo "Registered child VMs:"
ls "$VM_DIR" | sed 's/^/- /'
echo "</system-reminder>"
