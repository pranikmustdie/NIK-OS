#!/bin/bash
# build_files/optimize.sh
# NIK-OS Build-time Optimization Script

set -euo pipefail

echo "Applying NIK-OS optimizations..."

# Disable unnecessary systemd services for faster boot
SERVICES_TO_DISABLE=(
    "ModemManager.service"
    "cups.service"
    "avahi-daemon.service"
    "bluetooth.service"
    "lvm2-monitor.service"
    "NetworkManager-wait-online.service"
    "systemd-resolved.service"
)

for service in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl list-unit-files | grep -q "^${service}"; then
        echo "Disabling ${service}..."
        systemctl disable "${service}" 2>/dev/null || true
    fi
done

# Enable essential services
SERVICES_TO_ENABLE=(
    "tlp.service"
    "fstrim.timer"
    "irqbalance.service"
    "firewalld.service"
    "thermald.service"
)

for service in "${SERVICES_TO_ENABLE[@]}"; do
    if systemctl list-unit-files | grep -q "^${service}"; then
        echo "Enabling ${service}..."
        systemctl enable "${service}" 2>/dev/null || true
    fi
done

# Set default firewall zone
if command -v firewall-cmd &> /dev/null; then
    echo "Configuring firewall..."
    firewall-offline-cmd --set-default-zone=nik-office 2>/dev/null || true
fi

# Configure fingerprint authentication
if [ -f /usr/lib64/security/pam_fprintd.so ]; then
    echo "Configuring fprintd..."
    # PAM configuration will be handled by the system
    systemctl enable fprintd.service 2>/dev/null || true
fi

# Create necessary directories
mkdir -p /etc/systemd/system.conf.d
mkdir -p /etc/systemd/journald.conf.d
mkdir -p /etc/systemd/sleep.conf.d
mkdir -p /etc/systemd/logind.conf.d
mkdir -p /etc/sysctl.d
mkdir -p /etc/tlp.d
mkdir -p /etc/grub.d
mkdir -p /etc/firewalld/zones

# Set up preload for faster application launches (if available)
if rpm -q preload &> /dev/null; then
    systemctl enable preload.service 2>/dev/null || true
fi

# Configure journal to be less aggressive
journalctl --vacuum-size=500M 2>/dev/null || true
journalctl --vacuum-time=30d 2>/dev/null || true

# Set swappiness for better responsiveness
echo "vm.swappiness=10" > /etc/sysctl.d/98-swappiness.conf

# Create custom profile for laptop-mode
cat > /etc/profile.d/nik-os.sh << 'EOF'
# NIK-OS Environment Variables
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_QPA_PLATFORMTHEME=kde
export EDITOR=nano
export SYSTEMD_PAGER=
EOF

chmod +x /etc/profile.d/nik-os.sh

# Optimize DNF for faster updates
cat > /etc/dnf/dnf.conf << 'EOF'
[main]
gpgcheck=True
installonly_limit=2
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
defaultyes=True
fastestmirror=True
deltarpm=True
EOF

# Set hostname
echo "nik-os" > /etc/hostname

# Create info file
cat > /etc/nik-os-release << EOF
NIK-OS_VERSION="1.0"
NIK-OS_CODENAME="Office Edition"
NIK-OS_BUILD_DATE="$(date -u +%Y-%m-%d)"
NIK-OS_BASE="Aurora Linux (Fedora Atomic)"
EOF

echo "NIK-OS optimizations complete!"
