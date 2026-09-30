#!/bin/bash
# EVE-NG VM Management Utility
# Manages the KVM Virtual Machine on remote host tp24

show_help() {
    echo "Usage: $0 {start|stop|restart|status|console|snapshot|restore|list-snaps|ssh}"
    echo ""
    echo "Commands:"
    echo "  start       - Power ON the EVE-NG virtual machine"
    echo "  stop        - Gracefully shut down the EVE-NG VM"
    echo "  force-stop  - Immediately force stop (power off) the VM"
    echo "  restart     - Reboot the EVE-NG VM"
    echo "  status      - Display VM state, CPU, memory, and IP"
    echo "  console     - Open serial/VNC console on tp24"
    echo "  snapshot    - Create a snapshot of the VM (e.g.: $0 snapshot backup1)"
    echo "  restore     - Revert to a snapshot (e.g.: $0 restore backup1)"
    echo "  list-snaps  - List all existing snapshots"
    echo "  ssh         - Direct SSH into EVE-NG shell"
    echo "  fix-perms   - Fix EVE-NG permissions on addons"
    echo ""
}

ACTION="$1"

case "$ACTION" in
    start)
        echo "[*] Starting EVE-NG VM on tp24..."
        ssh tp24 "sudo virsh start eve-ng"
        ;;
    stop)
        echo "[*] Shutting down EVE-NG VM gracefully..."
        ssh tp24 "sudo virsh shutdown eve-ng"
        ;;
    force-stop)
        echo "[!] Force stopping EVE-NG VM..."
        ssh tp24 "sudo virsh destroy eve-ng"
        ;;
    restart|reboot)
        echo "[*] Rebooting EVE-NG VM..."
        ssh tp24 "sudo virsh reboot eve-ng"
        ;;
    status)
        echo "=== EVE-NG VM Status on tp24 ==="
        ssh tp24 "sudo virsh dominfo eve-ng && sudo virsh domifaddr eve-ng"
        echo ""
        /home/yahya/Documents/eve-ng/status.sh
        ;;
    console)
        echo "[*] Connecting to serial console (Press Ctrl+] to exit)..."
        ssh -t tp24 "sudo virsh console eve-ng"
        ;;
    snapshot)
        SNAP_NAME="${2:-snap_$(date +%Y%m%d_%H%M%S)}"
        echo "[*] Creating snapshot '$SNAP_NAME' for EVE-NG VM..."
        ssh tp24 "sudo virsh snapshot-create-as --domain eve-ng --name '$SNAP_NAME' --description 'Created via manage-eve.sh'"
        ;;
    restore)
        if [ -z "$2" ]; then
            echo "Error: Please specify the snapshot name to restore."
            echo "Usage: $0 restore <snapshot-name>"
            exit 1
        fi
        echo "[*] Reverting EVE-NG VM to snapshot '$2'..."
        ssh tp24 "sudo virsh snapshot-revert --domain eve-ng --snapshotname '$2'"
        ;;
    list-snaps)
        echo "=== Existing Snapshots for EVE-NG ==="
        ssh tp24 "sudo virsh snapshot-list eve-ng"
        ;;
    ssh)
        ssh eve
        ;;
    fix-perms)
        /home/yahya/Documents/eve-ng/fix-permissions.sh
        ;;
    *)
        show_help
        ;;
esac
