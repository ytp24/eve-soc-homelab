# OPNsense 24.7 Next-Gen Firewall Configuration & Policy Baseline

## Interface Allocations
| Interface ID | Virtual NIC | Name | Subnet / IP | Description |
|---|---|---|---|---|
| `vtnet0` | Port 0 | WAN | `172.31.255.50/24` (DHCP) | Upstream Internet NAT Gateway (`172.31.255.1`) |
| `vtnet1` | Port 1 | LAN | `10.10.10.1/24` | Corporate User LAN (VLAN 10) |
| `vtnet2` | Port 2 | DMZ | `10.10.20.1/24` | Public DMZ Web Services (VLAN 20) |
| `vtnet3` | Port 3 | OT_ICS | `10.10.30.1/24` | Isolated Industrial Control Systems (VLAN 30) |

---

## Security Policy & Filter Rules

### 1. WAN Rules (Inbound from External / Red Team)
- **Block & Log RFC1918**: Disabled for Home Lab testing on `172.31.255.0/24`.
- **Inbound ICMP**: Allow Echo Request (`ping`) from WAN to WAN address (rate-limited).
- **DMZ Port Forwarding (NAT Reflection)**:
  - Port 80 / 443 $\rightarrow$ Forward to `10.10.20.50` (DMZ Web Server).
- **Default WAN Inbound Policy**: `BLOCK & LOG ALL` (Captures Nmap scans, SYN probes, brute-force attempts).

### 2. Corporate LAN Rules (`vtnet1`)
- Allow LAN to any (Outbound Internet NAT Masquerade).
- Block LAN to `10.10.30.0/24` (Strict OT/ICS isolation).
- Allow LAN to `10.10.20.0/24` (HTTP/HTTPS only).

### 3. DMZ Rules (`vtnet2`)
- Allow DMZ to Internet (HTTP/HTTPS outbound for updates).
- Block DMZ to Corporate LAN (`10.10.10.0/24`).
- Block DMZ to OT/ICS (`10.10.30.0/24`).

### 4. Intrusion Detection & Prevention (Suricata / IPS Mode)
- **Interfaces**: WAN (`vtnet0`), LAN (`vtnet1`), DMZ (`vtnet2`).
- **Rule Sets Enabled**:
  - `ET Open / Scan Rules` (Nmap, Masscan, Nessus detection).
  - `ET Open / Exploit Rules` (SQLi, Web RCE, Log4j).
  - `ET Open / Brute Force Rules` (SSH, RDP, FTP brute-force).
  - `ET Open / Policy Rules` (Suspicious User-Agents, Outbound Tor/Proxy).
- **Alert Stream**: Forwarded to `/var/log/suricata/eve.json` and parsed by EveBox SIEM.
