#!/bin/bash
# Stream live Suricata IDS alerts in clean JSON
tail -f /var/log/suricata/eve.json | jq -c --unbuffered 'select(.event_type=="alert") | {timestamp: .timestamp, src: .src_ip, sport: .src_port, dst: .dest_ip, dport: .dest_port, signature: .alert.signature, category: .alert.category, severity: .alert.severity}'
