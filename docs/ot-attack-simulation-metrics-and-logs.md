# OT/ICS Modbus TCP Attack Simulation: Metrics and Execution Logs

## 1. Executive Summary and Test Environment
- **Target Node:** `OT-PLC-Node` (QEMU Linux Node 7 in EVE-NG)
- **Target IP / Port:** `10.10.30.50:502`
- **Zone / Subnet:** Critical OT/ICS SCADA Enclave (VLAN 30: `10.10.30.0/24`) on bridge `vnet0_5`
- **Adversary Source:** Kali Red Team Node / Simulated Intruder (`10.10.30.1`)
- **Detection Engine:** Suricata 8.0.7 AF-PACKET NIDS with active multithreaded monitoring on `vnet0_5`
- **SIEM / GUI:** EveBox SQLite backend (`http://localhost:5636` / `http://192.168.1.35:5636`)

---

## 2. Industrial Telemetry and Register State Transition Metrics

| Parameter / Sensor | Nominal State (Pre-Attack) | Compromised State (Post-Attack) | Status and Physical Impact | Suricata SID |
| :--- | :--- | :--- | :--- | :--- |
| **Port Recon / Discovery** | Normal SYN scans | SYN Flooding to port 502 | Reconnaissance detected | `2026101` |
| **Telemetry Read (FC 03)** | Read Holding Regs | Unauthorized polling | Policy violation alert | `2026102` |
| **Coolant Valve (Coil 0)** | Closed (0x0000) | Forced Open (0xFF00) | Actuator forced trip | `2026103` |
| **Chamber Pressure (Reg 0)** | 100 psi | 9999 psi | Critical Overpressure Setpoint Tampering | `2026104` |
| **Mass Parameter Set (FC 16)** | [100, 500, 75, 1200] | [9999, 8888, 7777, 6666] | Mass Safety Setpoint Override | `2026105` |

---

## 3. Modbus TCP Exploit Suite Execution Output

```
============================================================
 [*] INITIATING OT/ICS MODBUS TCP ADVERSARY SIMULATION
 Target SCADA PLC IP : 10.10.30.50
 Target Port         : 502
============================================================
[+] TCP Connection established to Modbus PLC service at 10.10.30.50:502

[Stage 1/4] [MITRE T0846] Polling Current Telemetry and Operational State (FC 03)...
    [+] Current PLC Registers: [100, 500]

[Stage 2/4] [MITRE T0855] Injecting Unauthorized Command Message - Force Trip Coil 0 (FC 05)...
    [+] Coil 0 forced to ON (Trip state injected). Response len: 12 bytes

[Stage 3/4] [MITRE T0836] Tampering with Industrial Setpoints - Register 0 to Overpressure 9999 (FC 06)...
    [+] Holding Register 0 overwritten to 9999 psi! Triggering Suricata Alert.

[Stage 4/4] [MITRE T0836] Mass Parameter Overwrite - Write Multiple Registers (FC 16)...
    [+] Multiple registers overwritten. Response len: 12 bytes

============================================================
 [+] Modbus TCP ICS Exploitation Complete. Verifying IDS alerts...
============================================================
```

---

## 4. Suricata EVE JSON Forensic Alert Telemetry

```json
{
  "timestamp": "2026-10-01T00:51:26.324528+0000",
  "flow_id": 1956791254902513,
  "in_iface": "vnet0_5",
  "event_type": "alert",
  "src_ip": "10.10.30.1",
  "src_port": 53848,
  "dest_ip": "10.10.30.50",
  "dest_port": 502,
  "proto": "TCP",
  "ip_v": 4,
  "alert": {
    "action": "allowed",
    "gid": 1,
    "signature_id": 2026101,
    "rev": 1,
    "signature": "SURICATA OT/ICS Modbus TCP Port Scan / Discovery to PLC Subnet",
    "category": "Attempted Information Leak",
    "severity": 2
  }
}
```

```json
{
  "timestamp": "2026-10-01T00:51:27.327560+0000",
  "flow_id": 1956791254902513,
  "in_iface": "vnet0_5",
  "event_type": "alert",
  "src_ip": "10.10.30.1",
  "src_port": 53848,
  "dest_ip": "10.10.30.50",
  "dest_port": 502,
  "proto": "TCP",
  "ip_v": 4,
  "alert": {
    "action": "allowed",
    "gid": 1,
    "signature_id": 2026103,
    "rev": 1,
    "signature": "SURICATA OT/ICS Modbus TCP Critical Write Single Coil Command (FC 05)",
    "category": "Attempted Administrator Privilege Gain",
    "severity": 1
  }
}
```

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
  "ip_v": 4,
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

```json
{
  "timestamp": "2026-10-01T00:51:29.329601+0000",
  "flow_id": 1956791254902513,
  "in_iface": "vnet0_5",
  "event_type": "alert",
  "src_ip": "10.10.30.1",
  "src_port": 53848,
  "dest_ip": "10.10.30.50",
  "dest_port": 502,
  "proto": "TCP",
  "ip_v": 4,
  "alert": {
    "action": "allowed",
    "gid": 1,
    "signature_id": 2026105,
    "rev": 1,
    "signature": "SURICATA OT/ICS Modbus TCP Write Multiple Holding Registers (FC 16)",
    "category": "Attempted Administrator Privilege Gain",
    "severity": 1
  }
}
```

---

## 5. EveBox SQLite Event Verification

```sql
SELECT timestamp, signature_id, signature, src_ip, dest_ip, in_iface 
FROM events 
WHERE signature_id LIKE '202610%' 
ORDER BY timestamp DESC;
```

**Indexed Records:**
- `1790815889332849000` | `2026102` | `SURICATA OT/ICS Modbus TCP Unauthorized Read Holding Registers Request (FC 03)` | `10.10.30.1` | `10.10.30.50` | `vnet0_5`
- `1790815889329601000` | `2026105` | `SURICATA OT/ICS Modbus TCP Write Multiple Holding Registers (FC 16)` | `10.10.30.1` | `10.10.30.50` | `vnet0_5`
- `1790815888328271000` | `2026104` | `SURICATA OT/ICS Modbus TCP Setpoint Modification Write Register (FC 06)` | `10.10.30.1` | `10.10.30.50` | `vnet0_5`
- `1790815887327560000` | `2026103` | `SURICATA OT/ICS Modbus TCP Critical Write Single Coil Command (FC 05)` | `10.10.30.1` | `10.10.30.50` | `vnet0_5`
- `1790815886324528000` | `2026101` | `SURICATA OT/ICS Modbus TCP Port Scan / Discovery to PLC Subnet` | `10.10.30.1` | `10.10.30.50` | `vnet0_5`

---

## 6. Automated Verification Checklist
- [x] Linux QEMU OT-PLC Node boots and accepts static IP `10.10.30.50/24` on interface `ens3`.
- [x] Modbus TCP Server daemon is active and listening on TCP port 502 (`0.0.0.0:502`).
- [x] Pre-attack telemetry polling (FC 03) accurately reflects nominal industrial state.
- [x] Kali Red Team attack injection successfully forces Coil 0 and overwrites holding registers.
- [x] Suricata AF-PACKET engine on `vnet0_5` captures all Modbus TCP packets without packet drops.
- [x] All 5 custom OT/ICS detection signatures trigger and log to `/var/log/suricata/eve.json`.
- [x] EveBox SIEM parses and indexes all alerts in its SQLite event store.
