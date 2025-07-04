FROM quay.io/fedora/fedora-bootc:43

ADD usr /usr
ADD etc /etc

# bootupd currently does not support Raspberry Pi-specific firmware and bootloader files.
# This shim script copies the firmware and bootloader files to the correct location before
# calling the original bootupctl script.
# This is a temporary workaround until https://github.com/coreos/bootupd/issues/651 is resolved.
RUN dnf install -y bcm2711-firmware uboot-images-armv8 \
  	&& cp -P /usr/share/uboot/rpi_arm64/u-boot.bin /boot/efi/rpi-u-boot.bin \
  	&& mkdir -p /usr/lib/bootc-raspi-firmwares \
  	&& cp -a /boot/efi/. /usr/lib/bootc-raspi-firmwares/ \
  	&& dnf remove -y bcm2711-firmware uboot-images-armv8 \
  	&& mkdir /usr/bin/bootupctl-orig \
  	&& mv /usr/bin/bootupctl /usr/bin/bootupctl-orig/

COPY bootupctl-shim /usr/bin/bootupctl

# Enable general setup
RUN systemctl enable setup.service

# Install tailscale and start it
RUN dnf -y install 'dnf5-command(config-manager)' \
    && dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo \
	&& dnf -y install tailscale \
	&& systemctl enable tailscaled

# Install docker
RUN dnf install -y docker-cli containerd docker-compose moby-engine wget unzip

# Install nomad & consul and configure them
RUN wget https://releases.hashicorp.com/nomad/1.10.2/nomad_1.10.2_linux_arm64.zip && unzip nomad_1.10.2_linux_arm64.zip \
    && mv nomad /usr/bin/nomad \
    && rm -rf nomad_1.10.2_linux_arm64.zip && rm LICENSE.txt \
    && wget https://releases.hashicorp.com/consul/1.21.1/consul_1.21.1_linux_arm64.zip && unzip consul_1.21.1_linux_arm64.zip \
    && mv consul /usr/bin/consul \
    && rm -rf consul_1.21.1_linux_arm64.zip && rm LICENSE.txt \
    && $(useradd nomad -s /bin/false -d /etc/nomad/nomad.d -G docker || true) \
    && chown -R nomad:nomad /etc/nomad \
    && systemctl enable nomad.service \
    && $(useradd consul -s /bin/false -d /etc/consul/consul.d || true) \
    && chown -R consul:consul /etc/consul \
    && systemctl enable consul.service

RUN dnf clean all && rm -rf /var/cache/dnf

# Optimize Tailscale https://web.archive.org/web/20250312064023/https://www.reddit.com/r/Fedora/comments/1h2s38i/beginners_guide_to_install_and_optimize_tailscale/
RUN echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.d/99-tailscale.conf \
    && echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.d/99-tailscale.conf \
    && systemctl enable network-opt.service

RUN bootc container lint
