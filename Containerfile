FROM ghcr.io/ublue-os/aurora:stable

# Metadata
LABEL org.opencontainers.image.title="NIK-OS"
LABEL org.opencontainers.image.description="High-stakes office optimized Fedora Atomic with KDE"
LABEL org.opencontainers.image.version="1.0"

# Copy configuration files
COPY system_files /
COPY build_files /tmp/build_files

# Install essential packages for office work and hardware support
RUN rpm-ostree install \
    # Fingerprint support
    fprintd \
    fprintd-pam \
    # Power management
    tlp \
    tlp-rdw \
    powertop \
    # Firewall management
    firewall-config \
    # Performance tools
    irqbalance \
    # Codec support for media
    ffmpeg \
    # System monitoring
    htop \
    btop \
    && \
    # Remove unnecessary packages to reduce bloat
    rpm-ostree override remove \
    gnome-tour \
    yelp \
    && \
    # Apply system optimizations
    chmod +x /tmp/build_files/optimize.sh && \
    /tmp/build_files/optimize.sh && \
    # Cleanup
    rm -rf /tmp/build_files && \
    ostree container commit
