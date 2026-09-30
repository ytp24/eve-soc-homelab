#!/bin/bash
# ==============================================================================
# EVE-NG Snapshot Lister
# ==============================================================================

HYPERVISOR_HOST="tp24"
VM_NAME="eve-ng"

echo "======================================================================"
echo " Available Snapshots for '${VM_NAME}' on Hypervisor (${HYPERVISOR_HOST})"
echo "======================================================================"

ssh "${HYPERVISOR_HOST}" "sudo virsh snapshot-list --domain '${VM_NAME}'"
