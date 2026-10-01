# EVE-SOC Homelab: 10-Minute Technical Interview Walkthrough & Defense Script

This document provides a concise, structured 10-minute presentation guide for explaining the Enterprise SOC Detection & Perimeter Engineering Homelab to technical interviewers, senior architects, and hiring managers.

---

## 10-Minute Presentation Structure at a Glance

| Time Window | Section | Core Objective | Key Talking Points |
| :--- | :--- | :--- | :--- |
| **00:00 - 02:00** | **1. Elevator Pitch & Architecture** | Set the stage and business context | Multi-zone enterprise perimeter, Purdue Model ICS segmentation, Suricata 8.0.7 NIDS, EveBox SIEM. |
| **02:00 - 04:00** | **2. Real-World Engineering Dilemma** | Demonstrate deep troubleshooting & RCA | Cisco IOL SPAN ASIC limitation vs Linux bridge AF-PACKET promiscuous ring buffers. |
| **04:00 - 07:00** | **3. Live Attack Simulation** | Show offensive adversary emulation | MITRE ATT&CK for ICS: T0846 Recon, T0855 Actuator Trip (FC 05), T0836 Overpressure Setpoint Tampering (FC 06). |
| **07:00 - 09:00** | **4. SOC Detection Telemetry & SIEM** | Prove detection engineering mastery | Custom Suricata rules (SIDs 2026101–2026105), EVE JSON schema, EveBox SQLite indexing. |
| **09:00 - 10:00** | **5. Incident Response & Key Takeaway** | Show strategic defensive mindset | INC-2026-0941 incident lifecycle, root cause mitigation, Purdue IDMZ enforcement. |

---

## Section 1: The Elevator Pitch (00:00 – 02:00)

### What to Say:
> *"I designed and built an automated, production-grade SOC Detection & Perimeter Engineering Lab virtualized inside EVE-NG on Linux KVM.*
> 
> *The goal was to move beyond textbook theory and simulate realistic adversary attacks across IT and OT/SCADA environments, capturing full packet telemetry through an out-of-band detection pipeline.*
> 
> *The architecture segments three distinct security zones through an OPNsense 24.7 Next-Gen Firewall and Cisco Layer 2 core switching:*
> 1. *Corporate LAN (VLAN 10: 10.10.10.0/24)*
> 2. *DMZ Web Services (VLAN 20: 10.10.20.0/24)*
> 3. *Critical OT / ICS Enclave (VLAN 30: 10.10.30.0/24) hosting an active Linux SCADA PLC responding on Modbus TCP port 502.*
> 
> *For detection, I deployed Suricata 8.0.7 in multi-threaded AF-PACKET mode ingesting all inter-zone and OT traffic directly into EveBox SIEM for real-time alert triage."*

---

## Section 2: The Technical Challenge & Root Cause Analysis (02:00 – 04:00)

### What to Say:
> *"While deploying the OT detection pipeline, I encountered an interesting real-world virtualization challenge:*
> 
> *Initially, Suricata generated zero alerts when attempting to sniff mirrored switch traffic. During root cause analysis, I uncovered two technical bottlenecks:*
> 1. *Cisco IOL (IOS on Linux) emulation accepts SPAN configuration syntax, but lacks physical ASIC silicon to replicate Ethernet frames across virtual TAP interfaces at line rate.*
> 2. *Suricata was only listening on external WAN interfaces (pnet0/pnet1), completely blind to internal VLAN bridges.*
> 
> *To engineer a resilient, zero-packet-drop solution, I bypassed software switch emulation and bound Suricata's multi-threaded AF-PACKET capture engine directly to the Linux hypervisor bridge interfaces (vnet0_5 for OT VLAN 30, vnet0_4 for DMZ, vnet0_3 for Corp LAN). This leverages kernel-level PACKET_MMAP ring buffers, delivering high-throughput packet inspection regardless of switch firmware constraints."*

---

## Section 3: Live Attack Simulation (04:00 – 07:00)

### What to Demonstrate (or Run):
Execute the 1-click reproduction script:
```bash
./scripts/reproduce_all.sh
```

### What to Say:
> *"To validate my detection rules, I engineered a Python adversary exploit injector aligned with MITRE ATT&CK for ICS tactics:*
> 
> *1. Stage 1 (T0846 - Discovery): The adversary connects to TCP port 502 and issues Modbus Function Code 03 to poll holding registers, reading live industrial telemetry (Chamber Pressure=100 psi, Flow=500 gpm).*
> *2. Stage 2 (T0855 - Unauthorized Command Message): The adversary injects Function Code 05 (Write Single Coil) with payload 0xFF00, forcing emergency Coolant Pump A to trip.*
> *3. Stage 3 (T0836 - Modify Parameter): The adversary injects Function Code 06 (Write Single Register), tampering with Safety Register 0 and setting it to an overpressure limit of 9999 psi.*
> *4. Stage 4 (T0836 - Mass Parameter Overwrite): The adversary injects Function Code 16 (0x10) to overwrite multiple safety registers simultaneously.*
> 
> *The PLC acknowledges the modified state, and the network packets immediately hit the Suricata inspection engine."*

---

## Section 4: SOC Detection Telemetry & SIEM Triage (07:00 – 09:00)

### What to Show:
Point to `/var/log/suricata/fast.log` or open the EveBox Dashboard at `http://localhost:5636`:

```
SURICATA OT/ICS Modbus TCP Port Scan / Discovery (SID: 2026101) [Severity 2]
SURICATA OT/ICS Modbus TCP Unauthorized Read Holding Regs FC 03 (SID: 2026102) [Severity 1]
SURICATA OT/ICS Modbus TCP Critical Write Single Coil FC 05 (SID: 2026103) [Severity 1]
SURICATA OT/ICS Modbus TCP Setpoint Modification Write Reg FC 06 (SID: 2026104) [Severity 1]
SURICATA OT/ICS Modbus TCP Write Multiple Holding Regs FC 16 (SID: 2026105) [Severity 1]
```

### What to Say:
> *"I authored five custom detection rules using precise byte-offset pattern matching on the Modbus Application Protocol (MBAP) header.*
> 
> *Because Modbus is an unauthenticated protocol, simple port monitoring is insufficient. My signatures inspect offset 2 for the Modbus protocol ID (0x0000) and offset 7 for the specific Function Code.*
> 
> *Every event is converted into structured JSON telemetry inside `/var/log/suricata/eve.json` and indexed into the EveBox SQLite database in real time, allowing Tier 1 and Tier 2 analysts to filter by signature ID, source IP, flow ID, and raw payload bytes."*

---

## Section 5: Incident Response & Strategic Takeaway (09:00 – 10:00)

### What to Say:
> *"I consolidated this full attack lifecycle into formal SOC Incident Report INC-2026-0941, documenting the timeline, Indicators of Compromise, and containment strategy.*
> 
> *The key takeaway from this project is that securing industrial environments requires a layered defense:*
> 1. *Network Segmentation (Purdue Model): Modbus TCP must never be exposed across subnets without an intermediate Jump Host or IDMZ proxy.*
> 2. *Detection Fidelity: Deep Packet Inspection rules must inspect protocol function codes rather than relying solely on port-based firewall rules.*
> 3. *Automation & Resilience: The entire lab environment is 100% reproducible through automated bash and python scripts in under 30 seconds."*

---

## 1-Command Live Demonstration Reference

To execute and prove this entire talk live in an interview:
```bash
# Clone and run 1-click reproduction
cd /home/yahya/Documents/eve-ng
./scripts/reproduce_all.sh
```
