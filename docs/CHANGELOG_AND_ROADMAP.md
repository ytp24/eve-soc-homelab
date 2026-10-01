# EVE-SOC Homelab: Changes Made and Engineering Roadmap

This document provides a comprehensive log of architectural and configuration changes implemented in the EVE-NG SOC Detection and Perimeter Engineering Homelab, along with the engineering roadmap for upcoming tasks.

---

## 1. Summary of Changes Made

### A. OT-PLC Linux Node Provisioning & Accessibility
- **Issue Identified:** Node 7 (`OT-PLC-Node`) was initially assigned a VPCS simulator runtime in the `.unl` topology file, which lacked TCP stack flexibility and daemon execution capability. Additionally, modern Linux kernel predictable network interface naming mapped the virtual NIC to `ens3` rather than `eth0`.
- **Changes Applied:**
  1. Updated lab topology definition (`SOC-Detection-Perimeter-Lab.unl`) to instantiate Node 7 with the Linux QEMU image (`template="linux" image="linux-alpine"` symlinked to the Ubuntu/Kali minimal image).
  2. Wiped and restarted Node 7 via `unl_wrapper` on telnet console port `32775`.
  3. Configured network interface `ens3` with static IP `10.10.30.50/24`, default gateway `10.10.30.1`, and hostname `OT-PLC-01`.
  4. Assigned host gateway IP `10.10.30.1/24` to Linux bridge `vnet0_5` (connecting switch port `vunl0_2_32` and PLC interface `vunl0_7_0`) on the EVE-NG host OS.
  5. Created automated configuration script [`scripts/configure_plc_node.py`](../scripts/configure_plc_node.py) to manage telnet provisioning and networking setup.

### B. Industrial SCADA / Modbus TCP Service Deployment
- **Changes Applied:**
  1. Deployed a multithreaded Python Modbus TCP daemon on Node 7 listening on `0.0.0.0:502`.
  2. Implemented Modbus Application Protocol (MBAP) handling for:
     - Read Coils / Discrete Inputs (Function Codes 01 / 02)
     - Read Holding / Input Registers (Function Codes 03 / 04: nominal pressure=100 psi, flow=500 gpm)
     - Write Single Coil (Function Code 05: forced actuator trip)
     - Write Single Register (Function Code 06: setpoint overwrite to 9999 psi)
     - Write Multiple Registers (Function Code 16 / 0x10: mass parameter override)

### C. Suricata 8.0.7 Multi-Interface AF-PACKET NIDS
- **Issue Identified:** Suricata was initially configured only for `pnet0` and `pnet1`, missing internal inter-VLAN and OT enclave traffic. Furthermore, Cisco IOL L2 software switches do not support line-rate ASIC SPAN replication to virtual TAP interfaces.
- **Changes Applied:**
  1. Reconfigured `/etc/suricata/suricata.yaml` with multi-interface `af-packet` listeners:
     - `vnet0_5` (VLAN 30 OT/ICS Enclave) - Cluster ID 97
     - `vnet0_4` (VLAN 20 DMZ Web) - Cluster ID 96
     - `vnet0_3` (VLAN 10 Corporate LAN) - Cluster ID 95
     - `pnet0` / `pnet1` (External WAN / Cloud Transit) - Cluster IDs 98 / 99
  2. Removed conflicting fanout cluster modes on virtual bridge interfaces to ensure stable zero-drop capture buffers across all 20 worker threads.
  3. Loaded 5 custom OT/ICS detection signatures in `/var/lib/suricata/rules/suricata.rules`:
     - `SID 2026101`: Modbus TCP Port Scan / Discovery to PLC Subnet
     - `SID 2026102`: Modbus TCP Unauthorized Read Holding Registers Request (FC 03)
     - `SID 2026103`: Modbus TCP Critical Write Single Coil Command (FC 05)
     - `SID 2026104`: Modbus TCP Setpoint Modification Write Register (FC 06)
     - `SID 2026105`: Modbus TCP Write Multiple Holding Registers (FC 16)

### D. Adversary Attack Simulation & Forensic Telemetry
- **Changes Applied:**
  1. Developed automated attack injection suite [`scripts/modbus_exploit_injector.py`](../scripts/modbus_exploit_injector.py) simulating MITRE ATT&CK for ICS techniques (T0846 Discovery, T0855 Unauthorized Command Message, T0836 Modify Parameter).
  2. Executed end-to-end attack simulation against `10.10.30.50:502`.
  3. Verified real-time alert generation in `/var/log/suricata/eve.json` and `/var/log/suricata/fast.log`.
  4. Verified alert ingestion and indexing in EveBox SIEM SQLite database (`/var/lib/evebox/events.sqlite`).
  5. Documented all metrics, hex payloads, and forensic logs in [`docs/ot-attack-simulation-metrics-and-logs.md`](ot-attack-simulation-metrics-and-logs.md).

---

## 2. Completed Milestones Checklist

- [x] Node 7 (`OT-PLC-Node`) instantiated as Linux QEMU node with predictable network naming (`ens3`).
- [x] Static IP `10.10.30.50/24` and gateway `10.10.30.1` reachable with 0% packet loss.
- [x] Modbus TCP server daemon active on port 502 with full MBAP protocol support.
- [x] Suricata 8.0.7 multithreaded AF-PACKET engine capturing live traffic on `vnet0_5`.
- [x] All 5 custom OT detection rules validated and firing with high-fidelity alert categorization.
- [x] EveBox SIEM dashboard actively indexing OT alert events.
- [x] Attack simulation suite automated and committed to Git (`cf013e2`).

---

## 3. Engineering Roadmap: What Needs To Be Done

### Phase 1: OT Node Persistence & Hardening
- [ ] **Systemd Unit File for Modbus Server:** Create `/etc/systemd/system/modbus-plc.service` on Node 7 with `Restart=always` so the PLC daemon persists across lab reboots and wipes.
- [ ] **Static Netplan Configuration:** Configure `/etc/netplan/01-netcfg.yaml` inside the base QEMU disk image to persist `10.10.30.50/24` IP assignment permanently.

### Phase 2: Perimeter Firewall & Inter-VLAN Policy Enforcement
- [ ] **OPNsense Firewall Rule Strict Isolation:** Configure strict OPNsense firewall rules blocking all direct inbound traffic from External WAN (`pnet1`) and DMZ (`VLAN 20`) to OT VLAN 30, permitting Modbus TCP (port 502) exclusively from designated Engineering Workstations (`10.10.10.50`).
- [ ] **Firewall Log Forwarding (Syslog):** Configure OPNsense syslog forwarding to the SOC telemetry pipeline (port 514/UDP) for cross-correlation with Suricata IDS alerts.

### Phase 3: Host-Level Security & Endpoint Detection (EDR/SIEM)
- [ ] **Wazuh Agent Integration:** Install Wazuh / OSSEC agent on the Linux OT-PLC node to monitor file integrity (`/root/plc_daemon.py`), process execution anomalies, and audit log generation.
- [ ] **Zeek (Bro) Protocol Parsing:** Deploy Zeek on the SPAN/mirror tap to generate specialized `modbus.log` protocol transaction logs detailing register addresses and function code metadata alongside Suricata alert data.

### Phase 4: Incident Response Documentation
- [ ] **Formal Incident Report Write-Up:** Author SOC Incident Report `INC-2026-0941` detailing the unauthorized Modbus setpoint manipulation attack, timeline, containment steps, and firewall remediation rules.
