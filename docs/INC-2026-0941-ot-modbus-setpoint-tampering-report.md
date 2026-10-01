# SECURITY INCIDENT REPORT: INC-2026-0941
**Title:** Unauthorized Modbus TCP Command Injection and Industrial Setpoint Tampering  
**Severity:** CRITICAL (P1) | **Status:** RESOLVED & CLOSED | **Date:** 2026-10-01T00:51:26Z  
**Lead Incident Response Analyst:** Yahya (SOC Detection & Incident Response Lead)  
**Target Asset:** `OT-PLC-Node` (IP: `10.10.30.50`, Zone: Purdue Level 1 Industrial SCADA Enclave)  

---

## 1. Executive Summary

On October 1, 2026, at approximately 00:51:26 UTC, the SOC detection engine (Suricata 8.0.7 NIDS on interface `vnet0_5`) triggered five concurrent high-priority alerts detecting unauthorized Modbus TCP function code injections directed against the primary Programmable Logic Controller (PLC-01, `10.10.30.50:502`).

An adversary executing reconnaissance probed port 502, forced an unauthorized actuator emergency trip via Modbus Function Code 05 (Write Single Coil), and altered critical safety parameters via Function Code 06 (Preset Single Register) and Function Code 16 (Write Multiple Registers), driving chamber pressure setpoints from nominal `100 psi` to a catastrophic overpressure threshold of `9999 psi`.

The SOC Detection & IR team contained the session in under two minutes, restored baseline PLC registers, verified telemetry integrity, and implemented network layer isolation controls. Zero physical damage or environmental release occurred.

---

## 2. Chronological Incident Timeline (UTC)

| Timestamp (UTC) | Phase | Event Description & Technical Activity |
| :--- | :--- | :--- |
| **00:51:26.324** | **Reconnaissance** | Adversary initiates TCP SYN handshake to Modbus port 502 on `10.10.30.50`. Suricata fires `SID: 2026101` (Port Scan / Discovery). |
| **00:51:26.325** | **Discovery (T0846)** | Adversary issues Modbus Function Code 03 (Read Holding Registers: start=0, count=4) to read live sensor telemetry (`Pressure=100 psi, Flow=500 gpm`). Suricata fires `SID: 2026102`. |
| **00:51:27.327** | **Command Injection (T0855)** | Adversary injects unauthorized Write Single Coil (`0x05`, Coil=0, Val=`0xFF00`) forcing Coolant Pump A to trip. Suricata fires `SID: 2026103`. |
| **00:51:28.328** | **Setpoint Tampering (T0836)** | Adversary injects unauthorized Write Single Register (`0x06`, Reg=0, Val=`9999`), overwriting safety pressure threshold. Suricata fires `SID: 2026104`. |
| **00:51:29.329** | **Mass Parameter Overwrite** | Adversary injects Write Multiple Registers (`0x10`, Regs=[9999, 8888, 7777, 6666]). Suricata fires `SID: 2026105`. |
| **00:51:35.000** | **Detection & Triage** | Tier 1 SOC Analyst identifies high-severity alert burst on EveBox SIEM dashboard (`http://localhost:5636`). Escalates to Tier 2 IR Lead. |
| **00:52:10.000** | **Containment** | IR Analyst severs malicious TCP stream, terminates rogue client sessions, and isolates adversary source IP at the perimeter boundary. |
| **00:53:40.000** | **Eradication & Remediation** | Reset PLC holding registers to safe baseline (`100 psi, 500 gpm, 75 C, 1200 RPM`). Deployed persistent systemd watchdog service `modbus-plc.service` on Node 7. |
| **00:55:00.000** | **Verification & Closure** | Re-polled PLC register bank; confirmed nominal operational stability and full logging compliance. |

---

## 3. Indicators of Compromise (IOCs) & Forensic Evidence

### Network Indicators
- **Attacker Source IP:** `10.10.30.1` (Simulated Gateway / Red Team Source)
- **Target IP / Port:** `10.10.30.50:502/TCP`
- **Protocol:** Modbus TCP (MBAP Header + Industrial PDU)
- **Monitored Interface:** `vnet0_5` (VLAN 30 Host Bridge)

### Suricata NIDS Detection Telemetry
```json
{
  "timestamp": "2026-10-01T00:51:28.328271+0000",
  "flow_id": 1956791254902513,
  "in_iface": "vnet0_5",
  "event_type": "alert",
  "src_ip": "10.10.30.1",
  "src_port": 53848,
  "dest_ip": "10.10.30.50",
  "dest_port": 502,
  "proto": "TCP",
  "alert": {
    "action": "allowed",
    "gid": 1,
    "signature_id": 2026104,
    "rev": 1,
    "signature": "SURICATA OT/ICS Modbus TCP Setpoint Modification Write Register (FC 06)",
    "category": "Attempted Administrator Privilege Gain",
    "severity": 1
  }
}
```

---

## 4. Impact Assessment & Blast Radius

- **Confidentiality:** LOW. Only non-proprietary sensor readings (telemetry registers 0-3) were read during stage 1 polling.
- **Integrity:** CRITICAL. Setpoint register 0 was manipulated from nominal operating limits (100 psi) to an unsafe overpressure limit (9999 psi), creating extreme physical overpressure hazard.
- **Availability:** HIGH. Coolant actuator coil 0 was temporarily forced into a trip state, disabling cooling circulation for 73 seconds prior to manual reset.
- **Scope:** Isolated strictly to VLAN 30 (`10.10.30.0/24`). Corporate LAN (VLAN 10) and DMZ (VLAN 20) assets remained untouched.

---

## 5. Root Cause Analysis (RCA)

1. **Lack of Purdue Model Enforcement:** Modbus TCP port 502 was listening unauthenticated on all IP interfaces without Layer 4 access restriction or application proxying.
2. **Missing Inter-VLAN Whitelisting:** Default routing allowed non-engineering subnets to establish direct TCP sessions to OT field devices.
3. **In-Band SPAN Failure in Virtual Switching:** Software switch emulation dropped port mirror frames; hypervisor bridge-level packet tapping (`vnet0_5`) was required to capture raw frames.

---

## 6. Corrective Actions & Preventative Hardening

### Immediate Actions Taken
1. Restored baseline PLC registers and enabled automated `modbus-plc.service` systemd unit on Node 7.
2. Verified multi-interface Suricata AF-PACKET engine configuration on `vnet0_5`.
3. Verified EveBox SIEM dashboard alert indexing.

### Long-Term Architectural Controls
1. **Firewall Strict Rule Enforcement:** Enforce strict OPNsense firewall rule allowing Modbus TCP (port 502) traffic *only* from authorized Engineering Workstation (`10.10.10.50`) and dropping all external WAN/DMZ ingress.
2. **Inline IPS Mode:** Transition Suricata from passive IDS to inline IPS mode (`NFQUEUE` / `af-packet` IPS) to automatically drop unauthorized Function Code 05/06 packets on the wire.
3. **Purdue Model IDMZ:** Implement a jump-host architecture with MFA and protocol inspection for all remote engineering maintenance access.
