# EVE-NG Community Lab Environment Access Guide

## Quick Access Overview

| Service | Access URL / Command | Default Credentials | Description |
| :--- | :--- | :--- | :--- |
| **EVE-NG Web GUI** | **[http://192.168.1.35](http://192.168.1.35)** | `admin` / `eve` | Primary EVE-NG Web Interface (Select **HTML5** or **Native** console) |
| **OPNsense Firewall Node** | Via VNC / Web GUI / Console | `root` / `opnsense` | OPNsense 24.7 Firewall Login |
| **Direct SSH to EVE-NG** | `ssh eve` *(or `ssh -p 2222 root@192.168.1.35`)* | `root` / `eve` *(Keys Installed)* | EVE-NG VM Shell & Management |
| **FileZilla SFTP** | `sftp://192.168.1.35:2222` | `root` / `eve` | Upload lab images (QEMU, IOU, Dynamips) |
| **EveBox Web GUI** | **[http://localhost:5636](http://localhost:5636)** | *(Local)* | Suricata IDS Alert & Telemetry Dashboard |


---

## 1. Deployed SOC Lab Topology (`SOC-Detection-Perimeter-Lab`)

When you log into **[http://192.168.1.35](http://192.168.1.35)**, you will see the pre-built **`SOC-Detection-Perimeter-Lab`** containing:

1. **OPNsense-FW (Firewall Node)**:
   - Template: `opnsense-24.7` (FreeBSD-based Next-Gen Firewall, 10 GB disk, 2 vCPUs, 2 GB RAM).
   - `vtnet0` -> Connected to **Internet Cloud (`pnet1`)**
   - `vtnet1` -> Connected to **Corporate LAN (VLAN 10)**
   - `vtnet2` -> Connected to **DMZ (VLAN 20)**
   - `vtnet3` -> Connected to **OT / ICS Zone (VLAN 30)**
2. **Internet Cloud (`pnet1`)**:
   - Subnet: `172.31.255.0/24` with automated DHCP server (`172.31.255.50 - .200`).
   - Outbound NAT Masquerade enables any connected node to access the real Internet.
3. **Local Cloud (`pnet0` / `pnet2`)**:
   - Bridged to your local LAN and host server for out-of-band management and direct routing.
4. **Endpoints**:
   - `Corp-Client-PC` (VLAN 10)
   - `DMZ-Web-Server` (VLAN 20)
   - `OT-PLC-Node` (VLAN 30)
   - `Kali-Attacker` (External / WAN)

---

## 2. Client Integration (Wireshark, VNC, Telnet)

The official **`eve-ng-integration`** client pack is installed on your Linux desktop. When using **Native Console** mode in the EVE-NG Web UI:

- **Live Wireshark Captures (`capture://`)**:
  - Right-click any link or interface in EVE-NG and select **Capture**.
  - Wireshark will open locally on your screen, streaming live packets from the virtual link in real-time.
- **Node Consoles (`telnet://`)**:
  - Clicking on router, switch, or VPCS nodes automatically launches your local terminal or Telnet client.
- **VNC Consoles (`vnc://`)**:
  - Clicking on GUI nodes (e.g. OPNsense, Windows, Kali) automatically opens TigerVNC / Vinagre.
- **HTML5 Web Consoles**:
  - Supported directly inside your browser tab without any client-side plugins.

---

## 3. FileZilla SFTP Configuration (Adding Images)

To upload additional appliance images:

1. Open **FileZilla** (`FileZilla` in Application Launcher or run `/home/yahya/Documents/eve-ng/launch-filezilla.sh`).
2. Connection Settings:
   - **Protocol:** `SFTP - SSH File Transfer Protocol`
   - **Host:** `192.168.1.35`
   - **Port:** `2222`
   - **Logon Type:** `Normal`
   - **User:** `root`
   - **Password:** `eve`
3. Target directories:
   - **QEMU Images:** `/opt/unetlab/addons/qemu/<template-name>-<version>/virtioa.qcow2`
   - **Cisco IOU / IOL:** `/opt/unetlab/addons/iol/bin/` *(license `iourc` is already generated!)*
   - **Dynamips:** `/opt/unetlab/addons/dynamips/`

### Fix Permissions After Uploading
```bash
/home/yahya/Documents/eve-ng/fix-permissions.sh
```

---

## 4. Helper Scripts

- **`status.sh`**: Health check script verifying VM state, Web GUI HTTP response, and connectivity.
- **`connect-eve-ssh.sh`**: One-click SSH into EVE-NG shell (`ssh eve`).
- **`fix-permissions.sh`**: Triggers EVE-NG unl_wrapper permissions repair.
- **`launch-filezilla.sh`**: Opens FileZilla pre-pointed to EVE-NG addons directory.
