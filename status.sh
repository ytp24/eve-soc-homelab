#!/bin/bash
# EVE-NG Status and Health Check Script
echo "========================================="
echo "   EVE-NG Lab Environment Health Check   "
echo "========================================="

echo -n "[1/4] Checking tp24 remote host... "
if ping -c 1 -W 2 192.168.1.35 >/dev/null 2>&1; then
    echo "ONLINE (192.168.1.35)"
else
    echo "OFFLINE / Unreachable"
fi

echo -n "[2/4] Checking EVE-NG SSH (Port 2222)... "
if nc -z -w 3 192.168.1.35 2222 2>/dev/null; then
    echo "LISTENING"
else
    echo "NOT RESPONDING"
fi

echo -n "[3/4] Checking EVE-NG Web GUI HTTP (Port 80)... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 http://192.168.1.35/ || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "301" ]; then
    echo "ONLINE (HTTP $HTTP_CODE) -> http://192.168.1.35"
else
    echo "HTTP Status: $HTTP_CODE"
fi

echo -n "[4/4] Checking EveBox Local IDS Web GUI (Port 5636)... "
EVEBOX_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 http://localhost:5636/ || echo "000")
if [ "$EVEBOX_CODE" = "200" ] || [ "$EVEBOX_CODE" = "302" ]; then
    echo "ONLINE (HTTP $EVEBOX_CODE) -> http://localhost:5636"
else
    echo "HTTP Status: $EVEBOX_CODE"
fi

echo "========================================="
