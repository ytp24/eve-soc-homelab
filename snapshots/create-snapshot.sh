#!/bin/bash
# ==============================================================================
# EVE-NG Snapshot Creator (Hypervisor-level QEMU/KVM snapshot)
# ==============================================================================

set -e

SNAPSHOT_NAME="${1:-snap-$(date +%Y%m%d-%H%M%S)}"
DESCRIPTION="${2:-Automated Home Lab snapshot taken on $(date)}"
HYPERVISOR_HOST="tp24"
VM_NAME="eve-ng"

echo "======================================================================"
echo " Creating Snapshot for '${VM_NAME}' on Hypervisor (${HYPERVISOR_HOST})"
echo " Snapshot Name: ${SNAPSHOT_NAME}"
echo " Description  : ${DESCRIPTION}"
echo "======================================================================"

ssh "${HYPERVISOR_HOST}" "sudo virsh snapshot-create-as --domain '${VM_NAME}' --name '${SNAPSHOT_NAME}' --description '${DESCRIPTION}' --atomic"

echo "[✓] Snapshot '${SNAPSHOT_NAME}' created successfully!"
