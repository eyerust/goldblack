# Allow build scripts to be referenced without being copied into the final image
ARG BASE_TAG=stable

FROM fedora:43 AS builder

RUN dnf install -y \
    meson \
    ninja-build \
    gcc \
    git \
    wayland-devel \
    wayland-protocols-devel \
    eglexternalplatform-devel \
    libglvnd-devel \
    libdrm-devel

RUN git clone https://github.com/NVIDIA/egl-wayland.git /tmp/egl-wayland
WORKDIR /tmp/egl-wayland
# checkout commit 0beb96e2df3ca40cd5156946a42048185b653c2d
RUN git checkout 0beb96e2df3ca40cd5156946a42048185b653c2d
RUN meson setup builddir --prefix=/usr --libdir=lib64 && \
    ninja -C builddir

FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/bazzite-gnome-nvidia-open:${BASE_TAG}

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

COPY --from=builder /tmp/egl-wayland/builddir/src/libnvidia-egl-wayland.so.1.1.22 /usr/lib64/
RUN ln -sf /usr/lib64/libnvidia-egl-wayland.so.1.1.22 /usr/lib64/libnvidia-egl-wayland.so.1 && \
    ln -sf /usr/lib64/libnvidia-egl-wayland.so.1.1.22 /usr/lib64/libnvidia-egl-wayland.so

COPY system_files/desktop/shared /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
