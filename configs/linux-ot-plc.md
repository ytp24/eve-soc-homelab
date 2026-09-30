# Linux QEMU OT/ICS Modbus PLC Node Configuration

## Overview
- **EVE-NG Node Name:** `OT-PLC-Node`
- **Node Type:** QEMU Linux (`template="linux"`, e.g. `linux-alpine` or `linux-ubuntu-server`)
- **Compatibility:** Fully compatible with **EVE-NG Community Edition & Professional** (No Docker license required).
- **RAM:** 256 MB – 512 MB
- **Subnet / Zone:** Critical OT / ICS Enclave (VLAN 30: `10.10.30.0/24`)
- **Assigned IP:** `10.10.30.50/24`
- **Default Gateway:** `10.10.30.1` (OPNsense Firewall `vtnet3`)
- **Listening Service:** Modbus TCP Industrial SCADA Daemon (`TCP/502`)

---

## 1. Network Configuration (`/etc/network/interfaces` on Alpine Linux)

```ini
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.10.30.50
    netmask 255.255.255.0
    gateway 10.10.30.1
```

Apply interface configuration:
```bash
ifup eth0
# or: ip addr add 10.10.30.50/24 dev eth0 && ip route add default via 10.10.30.1
```

---

## 2. Deploy & Run Modbus TCP SCADA PLC Simulator

Copy `scripts/modbus_plc_simulator.py` to `/root/modbus_plc_simulator.py` and run:

```bash
# Start Modbus TCP SCADA Daemon in background
python3 /root/modbus_plc_simulator.py 502 &
```

Verify listening socket on port 502:
```bash
netstat -tulpn | grep 502
# Output: tcp 0 0 0.0.0.0:502 0.0.0.0:* LISTEN
```

---

## 3. Industrial Telemetry & Register Map

| Register / Coil | Address | Data Type | Description | Nominal Value |
| :--- | :--- | :--- | :--- | :--- |
| **Coil 0** | `0x0000` | Boolean (Bit) | Primary Coolant Pump A (State) | `True` (RUNNING) |
| **Coil 1** | `0x0001` | Boolean (Bit) | Backup Coolant Pump B (State) | `False` (STANDBY) |
| **Coil 2** | `0x0002` | Boolean (Bit) | Emergency Depressurization Valve 1 | `True` (ARMED) |
| **Register 0** | `0x0000` | 16-bit Unsigned | Main Chamber Pressure (psi) | `100` |
| **Register 1** | `0x0001` | 16-bit Unsigned | Flow Rate (gpm) | `450` |
| **Register 2** | `0x0002` | 16-bit Unsigned | Operating Temperature (°C) | `75` |
| **Register 3** | `0x0003` | 16-bit Unsigned | Generator Turbine RPM | `1200` |
