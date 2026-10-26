#!/bin/bash
# Baut das Gole1-Linux Live-/Installations-ISO mit Debian live-build.
#
# Muss als root auf einem Debian/Ubuntu-System (oder im mitgelieferten
# Docker-Container) laufen. Gebaut wird in einem Linux-Dateisystem
# ($WORKDIR), weil live-build auf NTFS / Windows-Freigaben nicht funktioniert.
#
#   sudo ./build.sh            # normaler Build
#   sudo ./build.sh clean      # Arbeitsverzeichnis komplett leeren
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="${WORKDIR:-/var/tmp/gole1-build}"
OUT_DIR="${OUT_DIR:-$SRC_DIR/out}"
DIST="${DIST:-trixie}"
MIRROR="${MIRROR:-http://deb.debian.org/debian/}"
VERSION="${VERSION:-$(date +%Y.%m.%d)}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Bitte als root ausführen (sudo ./build.sh)." >&2
    exit 1
fi

if [ "${1:-}" = "clean" ]; then
    if [ -d "$WORKDIR" ]; then (cd "$WORKDIR" && lb clean --purge) || true; fi
    rm -rf "$WORKDIR"
    echo "Arbeitsverzeichnis $WORKDIR entfernt."
    exit 0
fi

for tool in lb debootstrap xorriso mksquashfs; do
    command -v "$tool" >/dev/null || {
        echo "Fehlt: $tool - bitte installieren: apt install live-build debootstrap xorriso squashfs-tools grub-efi-amd64-bin grub-efi-ia32-bin mtools dosfstools isolinux syslinux-common" >&2
        exit 1
    }
done

echo "==> Arbeitsverzeichnis: $WORKDIR"
mkdir -p "$WORKDIR" "$OUT_DIR"
cd "$WORKDIR"
# "lb clean" ohne --purge behält den Paket-Cache -> schnellere Folge-Builds
lb clean >/dev/null 2>&1 || true

# Eigene Konfiguration (Paketlisten, Hooks, Dateien) frisch übernehmen
rm -rf config
mkdir -p config
cp -a "$SRC_DIR/config/." config/
# Windows-Zeilenenden entfernen, falls Dateien unter Windows bearbeitet wurden
find config -type f -exec sed -i 's/\r$//' {} +

# Zusätzliche Firmware (z. B. WLAN-NVRAM aus dem alten Windows) einbinden
if compgen -G "$SRC_DIR/firmware-extra/*" >/dev/null; then
    echo "==> Übernehme Zusatz-Firmware aus firmware-extra/"
    mkdir -p config/includes.chroot/usr/lib/firmware
    find "$SRC_DIR/firmware-extra" -mindepth 1 -maxdepth 1 ! -name 'README*' \
        -exec cp -a {} config/includes.chroot/usr/lib/firmware/ \;
fi

# Ausführungsrechte setzen (gehen beim Kopieren von Windows aus verloren)
find config/hooks -type f -exec chmod 0755 {} +
find config/includes.chroot/usr/local/bin -type f -exec chmod 0755 {} +
chmod 0755 config/includes.chroot/etc/xdg/labwc/autostart

echo "$VERSION" > config/includes.chroot/etc/gole1-release

lb config \
    --distribution "$DIST" \
    --architectures amd64 \
    --archive-areas "main contrib non-free non-free-firmware" \
    --mirror-bootstrap "$MIRROR" \
    --mirror-chroot "$MIRROR" \
    --mirror-binary "$MIRROR" \
    --linux-flavours amd64 \
    --binary-images iso-hybrid \
    --bootloaders "grub-efi,syslinux" \
    --debian-installer none \
    --apt-recommends false \
    --firmware-chroot false \
    --firmware-binary false \
    --security true \
    --updates true \
    --memtest none \
    --iso-application "Gole1 Linux" \
    --iso-publisher "Gole1 Linux" \
    --iso-volume "GOLE1_LINUX" \
    --image-name "gole1-linux-$VERSION" \
    --bootappend-live "boot=live components quiet loglevel=3 locales=de_DE.UTF-8 keyboard-layouts=de timezone=Europe/Berlin hostname=gole1 username=user user-fullname=Gole1"

echo "==> Starte lb build (dauert je nach Internet 15-40 Minuten)"
lb build 2>&1 | tee build.log

ISO="$(ls -1 gole1-linux-"$VERSION"*.iso 2>/dev/null | head -n1 || true)"
if [ -z "$ISO" ]; then
    echo "FEHLER: Kein ISO erzeugt. Siehe $WORKDIR/build.log" >&2
    exit 1
fi

cp "$ISO" "$OUT_DIR/"
(cd "$OUT_DIR" && sha256sum "$(basename "$ISO")" > "$(basename "$ISO").sha256")
echo
echo "==> Fertig: $OUT_DIR/$(basename "$ISO") ($(du -h "$ISO" | cut -f1))"
