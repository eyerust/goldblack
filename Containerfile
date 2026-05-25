# Allow build scripts to be referenced without being copied into the final image
ARG BASE_TAG=stable

FROM scratch AS ctx
COPY build_files /

FROM fedora:latest AS thumbnailer-builder
RUN dnf install -y cargo meson ninja-build gcc shared-mime-info curl
RUN curl -fsSL https://gitlab.gnome.org/World/gnome-raw-thumbnailer/-/archive/48.0.0/gnome-raw-thumbnailer-48.0.0.tar.gz \
      | tar -xzf - -C /tmp \
 && cd /tmp/gnome-raw-thumbnailer-48.0.0 \
 && meson setup build --prefix=/usr -Dprofile=release \
 && meson compile -C build \
 && meson install -C build --destdir=/install

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

COPY system_files/desktop/shared /

COPY --from=thumbnailer-builder /install/usr/bin/raw-thumbnailer /usr/bin/raw-thumbnailer
COPY --from=thumbnailer-builder /install/usr/share/thumbnailers/raw.thumbnailer /usr/share/thumbnailers/raw.thumbnailer
COPY --from=thumbnailer-builder /install/usr/share/mime/packages/raw-thumbnailer.xml /usr/share/mime/packages/raw-thumbnailer.xml

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN update-mime-database /usr/share/mime

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
