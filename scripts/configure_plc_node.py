import telnetlib
import time
import base64

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

tn.write(b'ip addr flush dev ens3\n')
time.sleep(0.3)
tn.write(b'ip addr add 10.10.30.50/24 dev ens3\n')
time.sleep(0.3)
tn.write(b'ip link set ens3 up\n')
time.sleep(0.3)
tn.write(b'ip route add default via 10.10.30.1\n')
time.sleep(0.3)
tn.write(b'hostname OT-PLC-01\n')
time.sleep(0.3)

plc_code = """import socket, threading, struct

def handle(c):
    while True:
        try:
            d = c.recv(1024)
            if not d or len(d) < 7:
                break
            tid, proto, length, uid = struct.unpack('>HHHB', d[:7])
            fc = d[7] if len(d) > 7 else 0
            if fc in (1, 2):
                p = b'\\x01\\x00'
            elif fc in (3, 4):
                p = b'\\x04\\x00\\x64\\x01\\xf4'
            elif fc in (5, 6, 15, 16):
                p = d[8:12]
            else:
                p = b'\\x80'
            resp = struct.pack('>HHHBB', tid, proto, len(p) + 2, uid, fc) + p
            c.sendall(resp)
        except Exception:
            break
    c.close()

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('0.0.0.0', 502))
s.listen(10)
while True:
    conn, _ = s.accept()
    t = threading.Thread(target=handle, args=(conn,))
    t.daemon = True
    t.start()
"""

b64_plc = base64.b64encode(plc_code.encode()).decode()
tn.write(f'echo {b64_plc} | base64 -d > /root/plc_daemon.py\n'.encode())
time.sleep(0.5)
tn.write(b'killall -9 python3 2>/dev/null; nohup python3 /root/plc_daemon.py > /tmp/plc.log 2>&1 &\n')
time.sleep(1)
tn.write(b'ip addr show ens3; ip route show; netstat -tlpn\n')
time.sleep(2)
out = tn.read_very_eager().decode('latin1', errors='ignore')
print(out)
tn.close()
