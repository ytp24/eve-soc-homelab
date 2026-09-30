#!/usr/bin/env python3
"""
Lightweight Modbus TCP SCADA / PLC Simulator for EVE-NG SOC Homelab
Listens on TCP port 502 (or custom port) and responds to standard Modbus TCP function codes:
- FC 01 (0x01): Read Coils
- FC 03 (0x03): Read Holding Registers
- FC 05 (0x05): Write Single Coil (Simulates actuator/valve control)
- FC 06 (0x06): Write Single Register (Simulates setpoint modification)
- FC 16 (0x10): Write Multiple Registers
"""

import socket
import struct
import sys
import threading
import time

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 502
HOST = '0.0.0.0'

# Simulated Industrial State (Level 1/2 Purdue SCADA)
STATE = {
    'coils': {0: True, 1: False, 2: True, 3: False}, # Pump A, Pump B, Valve 1, Valve 2
    'holding_registers': {0: 100, 1: 450, 2: 75, 3: 1200} # Pressure (psi), Flow (gpm), Temp (C), RPM
}

def handle_client(conn, addr):
    print(f"[+] Modbus TCP Client connected: {addr[0]}:{addr[1]}")
    try:
        while True:
            header = conn.recv(7) # MBAP Header: TransID(2), ProtoID(2), Length(2), UnitID(1)
            if not header or len(header) < 7:
                break
            trans_id, proto_id, length, unit_id = struct.unpack('>HHHB', header)
            pdu = conn.recv(length - 1)
            if not pdu:
                break
            
            fc = pdu[0]
            resp_pdu = bytearray()
            
            if fc == 1: # Read Coils
                start_addr, count = struct.unpack('>HH', pdu[1:5])
                byte_count = (count + 7) // 8
                bits = 0
                for i in range(count):
                    val = STATE['coils'].get(start_addr + i, False)
                    if val:
                        bits |= (1 << i)
                resp_pdu.append(fc)
                resp_pdu.append(byte_count)
                resp_pdu.append(bits & 0xFF)
                print(f"[*] [FC 01] Read Coils from {start_addr} (count={count}) -> bits={bin(bits)}", flush=True)
                
            elif fc == 3: # Read Holding Registers
                start_addr, count = struct.unpack('>HH', pdu[1:5])
                resp_pdu.append(fc)
                resp_pdu.append(count * 2)
                for i in range(count):
                    val = STATE['holding_registers'].get(start_addr + i, 0)
                    resp_pdu.extend(struct.pack('>H', val))
                print(f"[*] [FC 03] Read Holding Registers from {start_addr} (count={count})", flush=True)
                
            elif fc == 5: # Write Single Coil
                coil_addr, coil_val = struct.unpack('>HH', pdu[1:5])
                bool_val = (coil_val == 0xFF00)
                STATE['coils'][coil_addr] = bool_val
                resp_pdu.extend(pdu[0:5]) # Echo request
                print(f"[!] [ALERT] [FC 05] Unauthorized Write Single Coil! Coil {coil_addr} set to {bool_val} by {addr[0]}", flush=True)
                
            elif fc == 6: # Write Single Register
                reg_addr, reg_val = struct.unpack('>HH', pdu[1:5])
                STATE['holding_registers'][reg_addr] = reg_val
                resp_pdu.extend(pdu[0:5])
                print(f"[!] [ALERT] [FC 06] Unauthorized Write Single Register! Reg {reg_addr} set to {reg_val} by {addr[0]}", flush=True)
                
            elif fc == 16: # Write Multiple Registers
                start_addr, reg_count, byte_count = struct.unpack('>HHB', pdu[1:6])
                for i in range(reg_count):
                    val = struct.unpack('>H', pdu[6 + i*2:8 + i*2])[0]
                    STATE['holding_registers'][start_addr + i] = val
                resp_pdu.extend(pdu[0:5])
                print(f"[!] [ALERT] [FC 16] Unauthorized Write Multiple Registers! Regs {start_addr}..{start_addr+reg_count-1} modified by {addr[0]}", flush=True)
            else:
                resp_pdu.append(fc | 0x80) # Exception
                resp_pdu.append(0x01) # Illegal Function
                print(f"[!] [FC {fc}] Unsupported or Illegal Modbus Function Code from {addr[0]}", flush=True)

            resp_len = len(resp_pdu) + 1
            resp_header = struct.pack('>HHHB', trans_id, proto_id, resp_len, unit_id)
            conn.sendall(resp_header + resp_pdu)
    except Exception as e:
        print(f"[-] Client {addr} disconnected with error: {e}")
    finally:
        conn.close()

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        s.bind((HOST, PORT))
    except PermissionError:
        print(f"[-] Port {PORT} requires root privileges. Falling back to port 5020 or run with sudo.")
        sys.exit(1)
    s.listen(5)
    print(f"============================================================")
    print(f" [✓] Modbus TCP Industrial SCADA PLC Simulator Running")
    print(f" Listening on {HOST}:{PORT} (Purdue Level 1/2 Controller)")
    print(f"============================================================")
    while True:
        conn, addr = s.accept()
        t = threading.Thread(target=handle_client, args=(conn, addr), daemon=True)
        t.start()

if __name__ == '__main__':
    main()
