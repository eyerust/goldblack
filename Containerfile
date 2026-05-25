# Allow build scripts to be referenced without being copied into the final image
ARG BASE_TAG=stable

FROM scratch AS ctx
COPY build_files /

ARG GRT_VERSION=48.0.1
FROM ghcr.io/ublue-os/bazzite-gnome-nvidia-open:${BASE_TAG} AS thumbnailer-builder
ARG GRT_VERSION
ENV RUSTUP_HOME=/opt/rust/rustup CARGO_HOME=/opt/rust/cargo PATH=/opt/rust/cargo/bin:$PATH
RUN dnf5 install -y meson ninja-build gcc git shared-mime-info rustup \
 && rustup-init -y --default-toolchain stable --profile minimal
RUN git clone --depth 1 --branch "${GRT_VERSION}" \
      https://gitlab.gnome.org/World/gnome-raw-thumbnailer.git /src \
 && cd /src \
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

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

COPY --from=thumbnailer-builder /install/usr/bin/raw-thumbnailer /usr/bin/raw-thumbnailer
COPY --from=thumbnailer-builder /install/usr/share/thumbnailers/raw.thumbnailer /usr/share/thumbnailers/raw.thumbnailer
COPY --from=thumbnailer-builder /install/usr/share/mime/packages/raw-thumbnailer.xml /usr/share/mime/packages/raw-thumbnailer.xml
RUN update-mime-database /usr/share/mime
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
