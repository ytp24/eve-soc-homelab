#!/bin/bash
# ==============================================================================
# EVE-NG Snapshot Revert / Restore Utility
# ==============================================================================

set -e

SNAPSHOT_NAME="$1"
HYPERVISOR_HOST="tp24"
VM_NAME="eve-ng"

if [ -z "${SNAPSHOT_NAME}" ]; then
    echo "Usage: $0 <snapshot_name>"
    echo ""
    echo "Available snapshots:"
    ssh "${HYPERVISOR_HOST}" "sudo virsh snapshot-list --domain '${VM_NAME}'"
    exit 1
fi

echo "======================================================================"
echo " Restoring Snapshot '${SNAPSHOT_NAME}' for VM '${VM_NAME}' on ${HYPERVISOR_HOST}"
echo " WARNING: Any uncommitted changes since snapshot will be lost."
echo "======================================================================"

read -p "Are you sure you want to revert to '${SNAPSHOT_NAME}'? (y/N): " -r CONFIRM
if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
    echo "Snapshot revert cancelled."
    exit 0
fi

ssh "${HYPERVISOR_HOST}" "sudo virsh snapshot-revert --domain '${VM_NAME}' --snapshotname '${SNAPSHOT_NAME}' --running"

echo "[✓] VM '${VM_NAME}' reverted to snapshot '${SNAPSHOT_NAME}' and resumed!"
