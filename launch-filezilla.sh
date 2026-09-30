#!/bin/bash
# Launch FileZilla connecting directly to EVE-NG SFTP
if command -v filezilla >/dev/null 2>&1; then
    filezilla "sftp://root:eve@192.168.1.35:2222/opt/unetlab/addons/" &
else
    echo "FileZilla is not installed. Please install with: sudo apt install filezilla"
fi
