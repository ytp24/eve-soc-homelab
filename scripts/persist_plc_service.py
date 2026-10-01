import telnetlib
import time
import base64

def main():
    tn = telnetlib.Telnet('127.0.0.1', 32775, timeout=10)
    time.sleep(1)
    tn.write(b'\n')
    time.sleep(0.5)

    buf = tn.read_very_eager().decode('latin1', errors='ignore')
    if 'login:' in buf:
        tn.write(b'root\n')
        time.sleep(0.5)
        tn.write(b'eve\n')
        time.sleep(1)

    # 1. Netplan configuration
    netplan_yaml = """network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      dhcp4: no
      addresses:
        - 10.10.30.50/24
      gateway4: 10.10.30.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
"""
    b64_netplan = base64.b64encode(netplan_yaml.encode()).decode()
    tn.write(f'echo {b64_netplan} | base64 -d > /etc/netplan/01-netcfg.yaml\n'.encode())
    time.sleep(0.5)
    tn.write(b'netplan apply 2>/dev/null || true\n')
    time.sleep(1)

    # 2. Systemd service for Modbus PLC
    service_unit = """[Unit]
Description=Industrial OT Modbus TCP PLC Server Daemon
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /root/plc_daemon.py
Restart=always
RestartSec=3
KillMode=process

[Install]
WantedBy=multi-user.target
"""
    b64_service = base64.b64encode(service_unit.encode()).decode()
    tn.write(f'echo {b64_service} | base64 -d > /etc/systemd/system/modbus-plc.service\n'.encode())
    time.sleep(0.5)
    tn.write(b'systemctl daemon-reload\n')
    time.sleep(0.5)
    tn.write(b'systemctl enable modbus-plc\n')
    time.sleep(0.5)
    tn.write(b'killall -9 python3 2>/dev/null || true\n')
    time.sleep(0.5)
    tn.write(b'systemctl restart modbus-plc\n')
    time.sleep(1)
    tn.write(b'systemctl status modbus-plc --no-pager\n')
    time.sleep(1)
    tn.write(b'ip addr show ens3; ip route show; netstat -tlpn\n')
    time.sleep(2)

    out = tn.read_very_eager().decode('latin1', errors='ignore')
    print(out)
    tn.close()

if __name__ == '__main__':
    main()
