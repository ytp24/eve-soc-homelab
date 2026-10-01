# Linux QEMU OT/ICS Modbus PLC Node: Accessibility, Setup & Troubleshooting Guide

A complete reference for deploying, configuring, troubleshooting, and persisting the **OT-PLC-Node** (`10.10.30.50`) in EVE-NG Community and Professional editions.

---

## 1. Node Profile & Specifications

* **Node Name in EVE-NG:** `OT-PLC-Node`
* **Template Type:** QEMU Linux (`template="linux"`, e.g. `linux-alpine-3.19` or `linux-ubuntu-server-22.04`)
* **Hardware Sizing:** 1 vCPU, 256 MB – 512 MB RAM, 1 Network Interface (`virtio-net-pci`)
* **Network Zone:** Purdue Level 1/2 OT SCADA Subnet (VLAN 30: `10.10.30.0/24`)
* **Static IP Address:** `10.10.30.50/24`
* **Default Gateway:** `10.10.30.1` (OPNsense Firewall `vtnet3` / Sub-interface)
* **Listening Industrial Service:** Modbus TCP SCADA Daemon on **TCP Port 502**

---

## 2. Root Cause Analysis: Why is the Linux Node Inaccessible?

If the node cannot be reached from Kali Linux, OPNsense, or management tools, check these 5 common failure points:

```text
+---------------------------------------------------+----------------------------------------------------------------+
| ROOT CAUSE / FAILURE POINT                        | SYMPTOM & TECHNICAL DIAGNOSIS                                  |
+---------------------------------------------------+----------------------------------------------------------------+
| **1. Interface Unconfigured / No IP on Boot**    | Node boots to clean shell with no IP on `eth0`.               |
|                                                   | `ip addr` shows `eth0` in DOWN or unassigned state.            |
+---------------------------------------------------+----------------------------------------------------------------+
| **2. EVE-NG Console Type Mismatch**              | Clicking node opens VNC when template uses Telnet (or vice    |
|                                                   | versa), resulting in a black/blank unresponsive terminal.     |
+---------------------------------------------------+----------------------------------------------------------------+
| **3. Cisco IOL Switchport Wrong VLAN**           | Switch port connected to PLC is in default VLAN 1 instead of   |
|                                                   | Access VLAN 30, dropping traffic at Layer 2.                   |
+---------------------------------------------------+----------------------------------------------------------------+
| **4. OPNsense Firewall Blocks Inbound Traffic**   | OPNsense drops traffic from WAN / Corp LAN to OT Subnet       |
|                                                   | due to missing pass rule for `10.10.30.0/24:502`.              |
+---------------------------------------------------+----------------------------------------------------------------+
| **5. Modbus TCP Daemon Not Running**             | Host responds to ICMP ping, but `TCP 502` refuses connections |
|                                                   | because `modbus_plc_simulator.py` was not started.             |
+---------------------------------------------------+----------------------------------------------------------------+
```

---

## 3. Instant 1-Line Bootstrap (Copy-Paste into Node Console)

Open the node console in EVE-NG and paste this single command block to configure network, default route, SSH, and start the Modbus TCP server:

```bash
ip addr add 10.10.30.50/24 dev eth0 2>/dev/null || ip addr add 10.10.30.50/24 dev ens3
ip link set eth0 up 2>/dev/null || ip link set ens3 up
ip route replace default via 10.10.30.1
echo -e "import socket,struct\ns=socket.socket()\ns.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)\ns.bind(('0.0.0.0',502))\ns.listen(5)\nprint('Modbus TCP Server Running on 502')\nwhile True:\n c,a=s.accept()\n while True:\n  h=c.recv(7)\n  if not h:break\n  t,p,l,u=struct.unpack('>HHHB',h)\n  d=c.recv(l-1)\n  if not d:break\n  c.sendall(h+d)\n c.close()" > /tmp/modbus_quick.py
python3 /tmp/modbus_quick.py &
```

---

## 4. Persistent OS-Level Network Configurations

### Option A: Alpine Linux (`/etc/network/interfaces`)

Edit `/etc/network/interfaces`:
```ini
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 10.10.30.50
    netmask 255.255.255.0
    gateway 10.10.30.1
```

Enable auto-start on boot:
```bash
rc-update add networking default
rc-update add sshd default
/etc/init.d/networking restart
```

### Option B: Ubuntu / Debian Server Netplan (`/etc/netplan/01-netcfg.yaml`)

Edit `/etc/netplan/01-netcfg.yaml`:
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 10.10.30.50/24
      routes:
        - to: default
          via: 10.10.30.1
      nameservers:
        addresses: [10.10.30.1, 8.8.8.8]
```

Apply Netplan:
```bash
netplan apply
```

---

## 5. Systemd Auto-Start Service for Modbus PLC Daemon

To guarantee the Modbus PLC simulator survives node reboots, create a systemd unit:

Create `/etc/systemd/system/modbus-plc.service`:
```ini
[Unit]
Description=Modbus TCP Industrial SCADA PLC Simulator
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /root/modbus_plc_simulator.py 502
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start the service:
```bash
systemctl daemon-reload
systemctl enable --now modbus-plc.service
systemctl status modbus-plc.service
```

---

## 6. Cisco Switch & OPNsense Firewall Verification

### 1. Cisco IOL Switchport Verification:
Ensure the port connected to the OT-PLC (e.g. `Ethernet0/2`) is in Access VLAN 30:
```cisco
interface Ethernet0/2
 description OT-PLC-SCADA-Node
 switchport mode access
 switchport access vlan 30
 spanning-tree portfast
 no shutdown
```

### 2. OPNsense Firewall Rules:
* In OPNsense Web GUI: **Firewall &rarr; Rules &rarr; OT_PLC (VLAN 30)**
* Add Rule:
  * **Action:** Pass
  * **Interface:** OT_PLC
  * **Protocol:** TCP
  * **Source:** Any (or Kali WAN / Corporate Subnet)
  * **Destination:** `10.10.30.50`
  * **Destination Port:** `502` (Modbus)
