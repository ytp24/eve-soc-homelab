#!/bin/bash
# SSH into EVE-NG VM
sshpass -p 'eve' ssh -o StrictHostKeyChecking=no -p 2222 root@192.168.1.35 "$@"
