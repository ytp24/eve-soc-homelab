# Enterprise SOC Detection & Perimeter Engineering Home Lab
### EVE-NG • OPNsense 24.7 • Cisco IOS/IOL • Suricata 8.0.7 • EveBox SIEM • Kali Linux

A production-grade, automated Security Operations Center (SOC) Detection & Perimeter Engineering Home Lab virtualized inside EVE-NG on Linux KVM. Built for realistic adversary simulations, deep packet inspection (DPI), stateful firewalling, L2 switching security, and real-time SIEM alert triage.

[![Platform](https://img.shields.io/badge/Platform-EVE--NG%20Community%20%2F%20Pro-blue.svg)](https://www.eve-ng.net/)
[![Hypervisor](https://img.shields.io/badge/Hypervisor-KVM%20%2F%20QEMU%20(Nested)-orange.svg)](https://www.linux-kvm.org/)
[![Firewall](https://img.shields.io/badge/Firewall-OPNsense%2024.7-red.svg)](https://opnsense.org/)
[![IDS](https://img.shields.io/badge/IDS%2FIPS-Suricata%208.0.7-brightgreen.svg)](https://suricata.io/)
[![SIEM](https://img.shields.io/badge/SIEM-EveBox%200.18.2-purple.svg)](https://evebox.org/)
[![Automation](https://img.shields.io/badge/Automation-Ansible%20Playbook-critical.svg)](https://www.ansible.com/)

---

## Live Lab Topology & Zone Architecture

![EVE-NG SOC Lab Topology](docs/images/eve-ng-soc-topology.png)

---

## Quick Navigation

- [Full Step-by-Step Live Deployment Tutorial](docs/TUTORIAL.md)
- [Adversary Simulation & Attack Catalog](docs/ATTACK_CATALOG.md)
- [SOC & Networking Core Study Notes (Plain .txt)](study/)
- [Node Configuration Files](configs/)
- [Ansible Automated Provisioning Playbooks](ansible/)
- [Lab Topologies & UNL Definitions](topologies/)
- [Snapshot & Disaster Recovery Scripts](snapshots/)
- [Client Integration & Access Guide](ACCESS_GUIDE.md)

---

## Architecture & Network Segmentation

The lab models a realistic enterprise perimeter with an isolated external threat actor attacking through the public Internet, a next-generation perimeter firewall, enterprise core switching, segmented internal enclaves, and an out-of-band SOC detection pipeline.

```mermaid
flowchart TD
    subgraph External["External Threat Environment (Untrusted WAN)"]
        KALI["Kali Linux Red Team\n(172.31.255.100)\n* Isolated External Attacker\n* Public Internet Reachability"]
        INET["Internet Gateway\n(172.31.255.1 - pnet1)"]
    end

    subgraph Perimeter["Perimeter Defense & Routing"]
        OPN["OPNsense 24.7 NGFW\nWAN: 172.31.255.50\nLAN: 10.10.10.1 (VLAN 10)\nDMZ: 10.10.20.1 (VLAN 20)\nOT:  10.10.30.1 (VLAN 30)"]
        R1["Cisco 7200 Core Router\n(fa0/0: WAN transit)"]
    end

    subgraph Core["Core Switching & Segmentation"]
        SW1["Cisco IOL L2 Switch\n* 802.1Q VLAN Trunks\n* Port Security\n* SPAN Mirroring (e0/3)"]
    end

    subgraph Zones["Segmented Internal Enclaves"]
        DMZ["DMZ Web Server\n(10.10.20.10:80)"]
        CORP["Corporate Client PC\n(10.10.10.50)"]
        OT["OT / ICS SCADA Node\n(10.10.30.100:502)"]
    end

    subgraph Detection["SOC Telemetry & Detection Pipeline"]
        SPAN["SPAN / Mirror Port\n(Promiscuous Sniffing)"]
        SURICATA["Suricata 8.0.7 IDS\n(Multi-Threaded AF_PACKET)"]
        EVE["/var/log/suricata/eve.json"]
        SIEM["EveBox SIEM Dashboard\n(:5636)"]
    end

    KALI --- INET
    INET --- OPN
    INET --- R1
    OPN ===|802.1Q Trunk| SW1
    SW1 --- DMZ
    SW1 --- CORP
    SW1 --- OT
    SW1 -.->|Port Mirror| SPAN
    OPN -.->|In-line / DPI| SURICATA
    SPAN --> SURICATA
    SURICATA --> EVE
    EVE --> SIEM
```

---

## Subnet & Addressing Plan

| Zone / Network | Subnet / CIDR | Gateway | Description |
| :--- | :--- | :--- | :--- |
| **External WAN** | `172.31.255.0/24` | `172.31.255.1` | Isolated untrusted network connecting Kali (`.100`) and Firewall WAN (`.50`) to the Internet |
| **Corporate LAN (VLAN 10)** | `10.10.10.0/24` | `10.10.10.1` | Internal corporate workstations and domain assets (`10.10.10.50`) |
| **DMZ Web (VLAN 20)** | `10.10.20.0/24` | `10.10.20.1` | Publicly exposed DMZ web servers & reverse proxies (`10.10.20.10:80`) |
| **OT / ICS (VLAN 30)** | `10.10.30.0/24` | `10.10.30.1` | Critical Industrial Control Systems & Modbus PLCs (`10.10.30.100:502`) |
| **Management (VLAN 99)** | `10.10.99.0/24` | `10.10.99.1` | Out-of-band management and SPAN port mirror destination |

---

## Core Switching & VLAN Segmentation

The Cisco Core Switch segments internal enterprise domains and provides SPAN port mirroring out to the Suricata inspection engine:

![Cisco Core Switch VLAN & 802.1Q Trunk Configuration](docs/images/cisco-switch-vlan-and-interfaces-config.png)

---

## Adversary Attack Simulation & Live Detection

Adversary emulation is executed from the isolated Kali Red Team node (`172.31.255.100`) across the WAN perimeter:

![Kali Linux Web SQL Injection Attack Simulation](docs/images/kali-linux-web-sql-attack.png)

### Real-Time Suricata IDS Alert Log Stream (`eve.json`):

![Suricata Live Attack Alert Logs](docs/images/suricata-attack-logs.png)

---

## Real-Time SIEM Event Triage (EveBox)

Suricata 8.0.7 forwards all telemetry to the **EveBox SIEM Dashboard** (`:5636`) for threat hunting and incident triage:

![EveBox SIEM Dashboard](docs/images/evebox-siem-dashboard.png)

### Alert Deep Dive (Layer 7 SQL Injection Payload Inspection):

![EveBox Alert Deep Dive](docs/images/evebox-alert-web-sql-injection.png)

---

## Deep Packet Inspection (Wireshark)

Deep packet inspection (DPI) verifies protocol compliance, TCP handshake lifecycles, and byte-level payload signatures on the wire:

![Wireshark Live TCP Handshake & Packet Inspection](docs/images/wireshark-tcp-handshake-analysis.png)

---

## Core Study Notes (`study/`)

Direct, plain-text reference notes covering foundational concepts:
- [`study/networking_fundamentals.txt`](study/networking_fundamentals.txt) - OSI model, IPv4 subnetting, RFC 1918, ARP, 802.1Q VLANs.
- [`study/tcp_ip_packet_analysis.txt`](study/tcp_ip_packet_analysis.txt) - 3-way handshake, TCP flags (SYN/ACK/PSH/FIN/RST), 4-way teardown, Wireshark filters.
- [`study/cisco_routing_switching.txt`](study/cisco_routing_switching.txt) - CAM table operation, Rapid-PVST, PortFast, BPDU Guard, OSPF Area 0.
- [`study/span_port_mirroring.txt`](study/span_port_mirroring.txt) - Local SPAN, RSPAN, ERSPAN, Promiscuous taps vs switch SPAN.
- [`study/opnsense_firewall_concepts.txt`](study/opnsense_firewall_concepts.txt) - Stateful packet inspection, state tables, NAT/PAT, `pfctl` commands.
- [`study/suricata_ids_detection.txt`](study/suricata_ids_detection.txt) - Multi-threading architecture, AF_PACKET, ET Open rule anatomy, `eve.json` structure.
- [`study/soc_telemetry_siem.txt`](study/soc_telemetry_siem.txt) - SOC Analyst Tier 1/2 triage lifecycle, EveBox alert triage, false positive tuning.
- [`study/adversary_attack_techniques.txt`](study/adversary_attack_techniques.txt) - MITRE ATT&CK mapping for Nmap, Hydra, SQLi, and C2.
- [`study/wireshark_attack_analysis.txt`](study/wireshark_attack_analysis.txt) - Wireshark display filters for detecting SYN scans, SQLi, Shellshock, brute-force, and tshark CLI analysis.

---

## Quick Start

### 1. Check Lab & Hypervisor Status
```bash
./status.sh
```

### 2. Manage EVE-NG VM (Start / Stop / Status)
```bash
./manage-eve.sh status
./manage-eve.sh start
```

### 3. Access Web Dashboards
- **EveBox SIEM Dashboard**: `http://<HYPERVISOR_IP>:5636`
- **EVE-NG Topology Web GUI**: `http://<HYPERVISOR_IP>` (Admin / `eve`)
- **OPNsense Firewall Web GUI**: `https://<HYPERVISOR_IP>:8443` (root / `opnsense`)

### 4. Run Automated Adversary Attack Simulation
```bash
# Connect to Kali node via telnet
telnet <HYPERVISOR_IP> 32772

# Execute attack script against the perimeter
./configs/kali-redteam-attack.sh 172.31.255.1
```

### 5. Automated Snapshots & Disaster Recovery
```bash
./snapshots/create-snapshot.sh baseline-clean "Clean initial state with all nodes configured"
./snapshots/list-snapshots.sh
./snapshots/restore-snapshot.sh baseline-clean
```

---

## License & Masked Infrastructure Notice
All configuration templates and playbooks in this repository use RFC 1918 placeholder addresses (`192.168.1.X`, `172.31.255.X`, `10.10.X.X`) to safeguard production credentials while ensuring 100% reproducible deployment.
