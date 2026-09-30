# EVE-NG VM & Lab Snapshot Management

This directory provides automated tooling to take, list, and restore hypervisor-level KVM snapshots and internal EVE-NG lab node export states.

## Architecture

1. **Hypervisor KVM VM Snapshot (Virsh / QEMU-KVM)**:
   - Captures the exact disk and memory state of the `eve-ng` virtual machine on hypervisor `tp24`.
   - Enables instant rollback before running destructive red team exploits, major kernel updates, or OS package upgrades.
2. **EVE-NG Lab Config State**:
   - Lab configs are stored in `/opt/unetlab/labs/`.
   - Node configurations (Cisco NVRAM, OPNsense XML configs) are stored in `/opt/unetlab/tmp/<lab_tenant>/<node_id>/`.

---

## Snapshot CLI Utilities

### 1. Create a Snapshot
```bash
./create-snapshot.sh [snapshot_name] [description]
```
*Example:*
```bash
./create-snapshot.sh pre-attack-baseline "Clean state before launching Kali hydra & nmap attacks"
```

### 2. List Existing Snapshots
```bash
./list-snapshots.sh
```

### 3. Revert / Restore a Snapshot
```bash
./restore-snapshot.sh [snapshot_name]
```
*Example:*
```bash
./restore-snapshot.sh pre-attack-baseline
```

---

## Storage & Backup Locations

- **Hypervisor VM Image**: `/var/lib/libvirt/images/eve-ng.qcow2` on `tp24`
- **Topologies**: `topologies/SOC-Detection-Perimeter-Lab.unl`
- **Suricata Rules & Threat Signatures**: `/etc/suricata/rules/`
- **EveBox Database**: `/var/lib/evebox/`
