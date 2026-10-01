#!/bin/bash
# ==============================================================================
# OT/ICS Modbus TCP PLC Node Bootstrap & Auto-Start Script for EVE-NG
# Ensures immediate network accessibility, static IP, SSH, and Modbus Daemon.
# Compatible with Alpine Linux, Ubuntu Server, Debian, and Rocky/RHEL QEMU Nodes.
# ==============================================================================

set -e

IP_ADDR="10.10.30.50"
NETMASK="255.255.255.0"
PREFIX="24"
GATEWAY="10.10.30.1"
MODBUS_PORT="502"

echo "============================================================"
echo " [*] Initializing OT/ICS Modbus PLC Node in EVE-NG"
echo "============================================================"

# 1. Detect Network Interface (typically eth0 or ens3)
IFACE=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}')
if [ -z "$IFACE" ]; then
    IFACE="eth0"
fi
echo "[+] Detected Network Interface: $IFACE"

# 2. Configure Static IP and Default Gateway
echo "[+] Assigning Static IP $IP_ADDR/$PREFIX to $IFACE..."
ip addr flush dev "$IFACE" || true
ip addr add "$IP_ADDR/$PREFIX" dev "$IFACE"
ip link set "$IFACE" up

echo "[+] Setting Default Gateway to $GATEWAY..."
ip route replace default via "$GATEWAY" dev "$IFACE" || true

# 3. Enable SSH Access for Remote Management
echo "[+] Ensuring SSH Service is Active..."
if command -v rc-service >/dev/null 2>&1; then
    # Alpine Linux OpenRC
    rc-update add sshd default 2>/dev/null || true
    rc-service sshd start 2>/dev/null || /usr/sbin/sshd || true
elif command -v systemctl >/dev/null 2>&1; then
    # Systemd (Ubuntu / Debian / RHEL)
    systemctl enable --now ssh 2>/dev/null || systemctl enable --now sshd 2>/dev/null || true
fi

# 4. Check Python 3 Availability
if ! command -v python3 >/dev/null 2>&1; then
    echo "[-] Python3 not found. Attempting package install..."
    if command -v apk >/dev/null 2>&1; then
        apk add --no-cache python3
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y python3
    fi
fi

# 5. Launch Modbus TCP SCADA PLC Simulator
echo "[+] Launching Modbus TCP SCADA Daemon on port $MODBUS_PORT..."
pkill -f "modbus_plc_simulator.py" || true

SCRIPT_PATH="/root/modbus_plc_simulator.py"
if [ ! -f "$SCRIPT_PATH" ]; then
    # Fallback search
    SCRIPT_PATH=$(find / -name "modbus_plc_simulator.py" 2>/dev/null | head -n 1 || echo "")
fi

if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
    nohup python3 "$SCRIPT_PATH" "$MODBUS_PORT" > /var/log/modbus_plc.log 2>&1 &
    echo "[✓] Modbus PLC Daemon started with PID $! (Log: /var/log/modbus_plc.log)"
else
    echo "[-] Warning: modbus_plc_simulator.py not found on local disk."
fi

echo ""
echo "============================================================"
echo " [✓] OT-PLC Node Ready and Accessible!"
echo "     IP Address      : $IP_ADDR"
echo "     Default Gateway : $GATEWAY"
echo "     Listening Port  : TCP $MODBUS_PORT"
echo "============================================================"
