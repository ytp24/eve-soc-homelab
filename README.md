# SOC Detection & Perimeter Engineering Home Lab (EVE-NG + OPNsense + Cisco + Kali + Suricata)

A production-grade, automated **Security Operations Center (SOC) Detection & Perimeter Engineering Home Lab** virtualized inside EVE-NG on a Linux KVM Hypervisor.

[![Platform](https://img.shields.io/badge/Platform-EVE--NG%20Community%20%2F%20Pro-blue.svg)](https://www.eve-ng.net/)
[![Hypervisor](https://img.shields.io/badge/Hypervisor-KVM%20%2F%20QEMU%20(Nested)-orange.svg)](https://www.linux-kvm.org/)
[![Firewall](https://img.shields.io/badge/Firewall-OPNsense%2024.7-red.svg)](https://opnsense.org/)
[![IDS](https://img.shields.io/badge/IDS%2FIPS-Suricata%208.0.7-brightgreen.svg)](https://suricata.io/)
[![Automation](https://img.shields.io/badge/Automation-Ansible%20Playbook-critical.svg)](https://www.ansible.com/)

---

## 🚀 Quick Navigation

- 📖 **[Full Step-by-Step Live Deployment Tutorial](docs/TUTORIAL.md)**
- ⚡ **[Ansible Automated Provisioning Playbooks](ansible/)**
- 🛡️ **[Lab Topologies & UNL Definitions](topologies/)**
- 📸 **[Snapshot & Disaster Recovery Scripts](snapshots/)**
- 🔑 **[Client Integration & Access Guide](ACCESS_GUIDE.md)**

---

## 🎯 Lab Architecture

- **Perimeter Firewall**: OPNsense 24.7 (Dual-homed WAN/LAN with Stateful Inspection, Snort/Suricata rules, NAT masquerade)
- **Core Routing**: Cisco 7200 Enterprise Router (Dynamips image `c7200-adventerprisek9-mz.124-24.T5`)
- **Core Switching**: Cisco IOL L2 Switch (`i86bi-linux-l2-adventerprise-15.1b`)
- **Red Team / Attack Node**: Kali Linux Minimal QEMU Appliance (`nmap`, `hydra`, `scapy`, `tcpdump`)
- **Dual Cloud Integration**:
  - `Internet-Cloud (pnet1)`: Outbound WAN NAT with dynamic DHCP (`172.31.255.0/24`)
  - `Local-Cloud (pnet0)`: Direct L2 bridge to Hypervisor / Host LAN
- **SOC Telemetry & Detection Pipeline**:
  - Suricata 8.0.7 monitoring mirrored SPAN port traffic
  - Real-time `eve.json` alerts parsed by **EveBox Web UI** (`http://<hypervisor_ip>:5636`)

---

## 🛠️ Quick Start

### 1. Check Lab & Hypervisor Status
```bash
./status.sh
```

### 2. Manage EVE-NG VM (Start / Stop / Restart / Console)
```bash
./manage-eve.sh status
./manage-eve.sh start
```

### 3. Deploy via Ansible
```bash
cd ansible
cp inventory.example.ini inventory.ini
cp group_vars/all.yml.example group_vars/all.yml
# Edit inventory.ini with your target hypervisor IP
ansible-playbook -i inventory.ini site.yml
```

### 4. Snapshots & Disaster Recovery
```bash
./snapshots/create-snapshot.sh baseline-clean "Clean initial state"
./snapshots/list-snapshots.sh
./snapshots/restore-snapshot.sh baseline-clean
```

---

## 📄 License & Sensitive Data Masking
All public playbooks and topology definitions in this repository use RFC 1918 placeholder addresses (`192.168.1.X`, `172.31.255.X`, `10.10.X.X`) to protect internal infrastructure while providing 100% reproducible configurations.
