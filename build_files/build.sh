#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
#dnf5 install -y tmux

dnf5 install -y adw-gtk3-theme bat bridge-utils ddcutil eza fio gnome-tweaks htop iotop libgda libgda-sqlite lm_sensors morewaita-icon-theme mullvad-vpn nautilus-python ncdu neovim nvidia-container-toolkit nvtop perf podman-docker python3-devel ripgrep smartmontools steam-devices strace syncthing sysprof tcpdump virt-install virt-manager waydroid wireguard-tools ydotool zsh

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

#systemctl enable podman.socket
