#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="lumina-os"
iso_label="LUMINA_OS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Lumina-OS <https://github.com/abdallah2008xx-jpg/Lumina-OS>"
iso_application="Lumina-OS Live ISO"
iso_version="0.1.0-dev"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.grub')
pacman_conf="pacman.conf"
airootfs_image_type="erofs"
airootfs_image_tool_options=('-zlzma,109' -E 'ztailpacking')
bootstrap_tarball_compression=(xz -9e)
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/customize_airootfs.sh"]="0:0:755"
  ["/home/live/.local/bin/ahmados-apply-session-defaults"]="0:0:755"
  ["/home/live/.local/bin/lumina-apply-session-defaults"]="0:0:755"
  ["/usr/local/bin/ahmados-export-diagnostics"]="0:0:755"
  ["/usr/local/bin/ahmados-installer"]="0:0:755"
  ["/usr/local/bin/ahmados-run-smoke-checks"]="0:0:755"
  ["/usr/local/bin/ahmados-open-firstboot-report"]="0:0:755"
  ["/usr/local/bin/ahmados-refresh-release-metadata"]="0:0:755"
  ["/usr/local/bin/ahmados-update-center"]="0:0:755"
  ["/usr/local/bin/ahmados-welcome"]="0:0:755"
  ["/usr/local/bin/ahmados-firstboot"]="0:0:755"
  ["/usr/local/bin/lumina-export-diagnostics"]="0:0:755"
  ["/usr/local/bin/lumina-installer"]="0:0:755"
  ["/usr/local/bin/lumina-run-smoke-checks"]="0:0:755"
  ["/usr/local/bin/lumina-open-firstboot-report"]="0:0:755"
  ["/usr/local/bin/lumina-refresh-release-metadata"]="0:0:755"
  ["/usr/local/bin/lumina-update-center"]="0:0:755"
  ["/usr/local/bin/lumina-welcome"]="0:0:755"
  ["/usr/local/bin/lumina-firstboot"]="0:0:755"
  ["/usr/local/bin/ahmados-windows-compat-check"]="0:0:755"
  ["/usr/local/bin/ahmados-windows-vm-lab"]="0:0:755"
  ["/usr/local/bin/lumina-windows-compat-check"]="0:0:755"
  ["/usr/local/bin/lumina-windows-vm-lab"]="0:0:755"
  ["/home/live/Desktop/Install Lumina-OS.desktop"]="0:0:755"
)
