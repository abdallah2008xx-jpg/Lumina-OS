#!/usr/bin/env bash
set -euo pipefail

# Keep the baseline deterministic while still having a valid localtime link.
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

if ! id live >/dev/null 2>&1; then
    useradd -m -G wheel -s /usr/bin/bash live
fi

passwd -d live
chmod 755 /home/live/.local/bin/ahmados-apply-session-defaults
chmod 755 /home/live/.local/bin/lumina-apply-session-defaults
chown -R live:live /home/live

systemctl enable NetworkManager.service
systemctl enable sddm.service

for service in vboxservice.service vmtoolsd.service vmware-vmblock-fuse.service; do
    if [[ -f "/usr/lib/systemd/system/${service}" ]]; then
        systemctl enable "${service}"
    fi
done

systemctl set-default graphical.target
