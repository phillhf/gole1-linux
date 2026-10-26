# Build-Umgebung für Gole1 Linux (Debian 13 + live-build)
#   docker build -t gole1-builder .
#   docker run --rm --privileged -v "$PWD:/src" gole1-builder
FROM debian:trixie

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        live-build debootstrap xorriso squashfs-tools cpio rsync \
        grub-efi-amd64-bin grub-efi-ia32-bin grub-common \
        mtools dosfstools isolinux syslinux-common syslinux-utils \
        ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ENTRYPOINT ["/bin/bash", "/src/build.sh"]
