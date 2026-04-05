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
chmod 755 /usr/local/bin/ahmados-apply-session-defaults
chmod 755 /usr/local/bin/lumina-apply-session-defaults
chmod 755 /usr/local/bin/ahmados-vm-display-prep
chmod 755 /usr/local/bin/lumina-vm-display-prep
chmod 755 /usr/local/bin/ahmados-vm-guest-services
chmod 755 /usr/local/bin/lumina-vm-guest-services
chmod 755 /usr/local/bin/ahmados-refresh-update-markers
chmod 755 /usr/local/bin/lumina-refresh-update-markers
chmod 755 /usr/local/bin/ahmados-finalize-install
chmod 755 /usr/local/bin/lumina-finalize-install
chmod 755 /usr/local/bin/ahmados-capture-screenshot
chmod 755 /usr/local/bin/lumina-capture-screenshot
chmod 755 /usr/local/bin/ahmados-windows-apps-catalog
chmod 755 /usr/local/bin/lumina-windows-apps-catalog
chmod 755 /usr/local/bin/ahmados-windows-app-assistant
chmod 755 /usr/local/bin/lumina-windows-app-assistant
chmod 755 /usr/local/bin/ahmados-windows-profile-assistant
chmod 755 /usr/local/bin/lumina-windows-profile-assistant
chmod 755 /usr/local/bin/ahmados-windows-profile-runbook
chmod 755 /usr/local/bin/lumina-windows-profile-runbook
chmod 755 /usr/local/bin/ahmados-windows-workflow-bootstrap
chmod 755 /usr/local/bin/lumina-windows-workflow-bootstrap
chmod 755 /usr/local/bin/ahmados-windows-workflow-state
chmod 755 /usr/local/bin/lumina-windows-workflow-state
chmod 755 /usr/local/bin/ahmados-windows-workflow-mark
chmod 755 /usr/local/bin/lumina-windows-workflow-mark
chmod 755 /usr/local/bin/ahmados-windows-workflow-recipe
chmod 755 /usr/local/bin/lumina-windows-workflow-recipe
chmod 755 /usr/local/bin/ahmados-windows-workflow-hub
chmod 755 /usr/local/bin/lumina-windows-workflow-hub
chmod 755 /usr/local/bin/ahmados-windows-workflow-action-pack
chmod 755 /usr/local/bin/lumina-windows-workflow-action-pack
chmod 755 /usr/local/bin/ahmados-windows-workflow-next-action
chmod 755 /usr/local/bin/lumina-windows-workflow-next-action
chmod 755 /usr/local/bin/ahmados-windows-vm-template
chmod 755 /usr/local/bin/lumina-windows-vm-template
chmod 755 /usr/local/bin/ahmados-windows-vm-creation-starter
chmod 755 /usr/local/bin/lumina-windows-vm-creation-starter
chmod 755 /usr/local/bin/ahmados-windows-vm-postcreate
chmod 755 /usr/local/bin/lumina-windows-vm-postcreate
chmod 755 /usr/local/bin/ahmados-windows-app-install-starter
chmod 755 /usr/local/bin/lumina-windows-app-install-starter
chmod 755 /usr/local/bin/ahmados-windows-workflow-proof-pass
chmod 755 /usr/local/bin/lumina-windows-workflow-proof-pass
chmod 755 /usr/local/bin/ahmados-windows-onboarding
chmod 755 /usr/local/bin/lumina-windows-onboarding
chmod 755 /usr/local/bin/ahmados-windows-vm-launcher
chmod 755 /usr/local/bin/lumina-windows-vm-launcher
chmod 755 /usr/local/bin/ahmados-windows-vm-runner
chmod 755 /usr/local/bin/lumina-windows-vm-runner
chmod 755 /usr/local/bin/ahmados-windows-auto-configure
chmod 755 /usr/local/bin/lumina-windows-auto-configure
chmod 755 /usr/local/bin/ahmados-windows-launch-broker
chmod 755 /usr/local/bin/lumina-windows-launch-broker
chown -R live:live /home/live

for optional_group in libvirt kvm; do
    if getent group "${optional_group}" >/dev/null 2>&1; then
        usermod -aG "${optional_group}" live
    fi
done

systemctl enable NetworkManager.service
systemctl enable sddm.service
systemctl enable ahmados-vm-guest-services.service
systemctl enable ahmados-update-markers.service

for service in libvirtd.service virtlogd.service virtlockd.service; do
    if [[ -f "/usr/lib/systemd/system/${service}" ]]; then
        systemctl enable "${service}"
    elif [[ -f "/etc/systemd/system/${service}" ]]; then
        systemctl enable "${service}"
    fi
done

systemctl set-default graphical.target

# The image is fully customized at build time, so mark /etc and /var as updated
# to avoid slow ConditionNeedsUpdate jobs like ldconfig.service on first boot.
touch /etc/.updated
mkdir -p /var
touch /var/.updated
mkdir -p /var/lib/lumina
touch /var/lib/lumina/pending-update-marker-refresh
