#!/bin/bash
# Trigger unl_wrapper fixpermissions on EVE-NG
echo "Fixing permissions on EVE-NG (/opt/unetlab/addons/)..."
sshpass -p 'eve' ssh -o StrictHostKeyChecking=no -p 2222 root@192.168.1.35 "/opt/unetlab/wrappers/unl_wrapper -a fixpermissions"
echo "Permissions successfully updated."
