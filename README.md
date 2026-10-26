# Gole1 Linux

Schlanke, schnelle Linux-Distribution für den **GOLE1 Mini-PC**
(Intel Atom x5 „Cherry Trail“, 4 GB RAM, eMMC, 5"-Touchscreen 1280×720).

| Bereich | Wahl | Warum |
|---|---|---|
| Basis | Debian 13 „trixie“ (64 Bit) | stabil, Sicherheitsupdates bis 2030, Kernel 6.12 mit guter Cherry-Trail-Unterstützung |
| Desktop | **labwc** (Wayland) + waybar | sehr wenig RAM/CPU, Touch nativ, keine Desktop-Dienste im Hintergrund |
| Touch | Bildschirmtastatur `wvkbd`, Starter `fuzzel`, Fenster immer maximiert | auf 5 Zoll mit dem Finger bedienbar |
| Anmeldung | greetd mit Auto-Login | direkt in den Desktop |
| Speicher | zram-Swap (zstd), Journal begrenzt, unnötige Timer aus | schont eMMC, mehr nutzbarer RAM |
| Apps | Firefox ESR, PCManFM, Mousepad, foot, imv, pavucontrol | leichtgewichtig |
## Ordnerstruktur

```
gole1-linux/
├── build.sh              Build-Skript (Linux, als root)
├── build.ps1             Build unter Windows mit Docker Desktop
├── Dockerfile            Build-Umgebung (Debian + live-build)
├── .github/workflows/    Build in der Cloud über GitHub Actions
├── firmware-extra/       eigene Firmware (z. B. WLAN-NVRAM aus Windows)
└── config/               live-build-Konfiguration
    ├── package-lists/    welche Pakete installiert werden
    ├── hooks/normal/     Einstellungen beim Bauen (Sprache, Dienste, Aufräumen)
    └── includes.chroot/  Dateien, die 1:1 ins System kommen
        ├── etc/gole1.conf          Drehung, Skalierung, Kernel-Parameter
        ├── etc/xdg/labwc/          Desktop (rc.xml, autostart, Menü)
        ├── etc/xdg/waybar/         Leiste
        └── usr/local/bin/gole1-*   Helfer: install, display, rotate, keyboard, info
```

## 1. ISO bauen

Du brauchst **eine** der folgenden Möglichkeiten. Der erste Build lädt ca. 1 GB
Pakete herunter und dauert 15–40 Minuten. Ergebnis: `out/gole1-linux-<datum>-amd64.hybrid.iso`.

**a) Windows mit WSL2 (empfohlen auf diesem Rechner)**

WSL einmalig als Administrator installieren und neu starten:

```powershell
wsl --install -d Debian
```

Dann in der Debian-Konsole:

```bash
sudo apt update && sudo apt install -y live-build debootstrap xorriso squashfs-tools cpio rsync grub-efi-amd64-bin grub-efi-ia32-bin mtools dosfstools isolinux syslinux-common syslinux-utils
```

```bash
cd /mnt/c/Entwicklung/gole1-linux && sudo ./build.sh
```

Gebaut wird automatisch in `/var/tmp/gole1-build` (Linux-Dateisystem), nur das
fertige ISO wird nach `out\` kopiert.

**b) Windows mit Docker Desktop**

```powershell
.\build.ps1
```

**c) GitHub Actions (ohne lokale Installation)**

Ordner als Repository auf GitHub hochladen → *Actions* → „ISO bauen“ →
*Run workflow*. Das ISO liegt danach als Artefakt zum Download bereit.

**d) Beliebiger Debian-/Ubuntu-PC**: Pakete wie in a) installieren, dann `sudo ./build.sh`.

## 2. Vor dem Überschreiben: WLAN-Datei aus Windows sichern

Läuft auf dem GOLE1 noch Windows, sichere vorher die WLAN-NVRAM-Datei
(Details in [firmware-extra/README.md](firmware-extra/README.md)). Ohne sie
funktioniert das Broadcom-WLAN unter Linux oft nicht. Notfalls geht auch ein
USB-WLAN- oder USB-LAN-Adapter.

## 3. USB-Stick erstellen & starten

1. ISO mit **Rufus** (Modus „DD-Image“) oder **balenaEtcher** auf einen USB-Stick schreiben.
2. Stick am GOLE1 anstecken, einschalten und je nach BIOS **F7**, **F11** oder **ESC**
   (Bootmenü) drücken, dann den USB-Stick wählen. Eine USB-Tastatur ist dafür nötig.
3. Das Live-System startet direkt in den Desktop (Benutzer `user`, Passwort `live`).

Jetzt alles ausprobieren: Touch, WLAN, Ton, Drehung. **Systeminfo** im
App-Menü zeigt erkannte Hardware und fehlende Firmware.

## 4. Auf den eMMC installieren

App-Menü (Gitter-Symbol links oben) → **Gole1 Linux installieren**.
Der Installer fragt Ziellaufwerk (meist `/dev/mmcblk0`), Benutzer, Passwort,
Rechnername und Auto-Login. Er erkennt selbst, ob der GOLE1 ein 64- oder
32-Bit-UEFI hat, und richtet GRUB passend ein. Danach USB-Stick abziehen und neu starten.

> ⚠️ Der Installer löscht das gewählte Laufwerk komplett – auch Windows.

## Bedienung

| Symbol in der Leiste | Funktion |
|---|---|
| Gitter (links) | Programme starten |
| Tastatur | Bildschirmtastatur ein/aus |
| Kreispfeile | Bildschirm um 90° drehen (wird gespeichert) |
| Ein/Aus (rot) | Abmelden / Bereitschaft / Neustart / Ausschalten |
| Lautsprecher | Lautstärke (Tippen öffnet Mixer) |

Mit Tastatur: `Super+Leertaste` Programme, `Super+Enter` Terminal, `Super+E` Dateien, `Super+K` Bildschirmtastatur.

## Anpassen

- **Drehung/Skalierung** systemweit: `/etc/gole1.conf` (`ROTATION`, `SCALE`).
  Pro Benutzer: `~/.config/gole1/display.conf`.
- **Pakete** hinzufügen/entfernen: `config/package-lists/*.list.chroot`, dann neu bauen.
  Auf dem laufenden System geht auch `sudo apt install <paket>`.
- **Desktop**: `config/includes.chroot/etc/xdg/labwc/` und `.../waybar/`.

## Bekannte Punkte / Fehlersuche

- **Bild steht auf dem Kopf:** einmal auf das Dreh-Symbol tippen oder `ROTATION=270` setzen.
- **Touch trifft nach dem Drehen daneben:** `gole1-info` zeigt den Ausgangsnamen. In
  `/etc/gole1.conf` `OUTPUT=` setzen und neu anmelden.
- **Kein WLAN:** NVRAM-Datei fehlt → siehe Abschnitt 2.
- **Kein Ton:** Cherry-Trail-Audio braucht teils einen Neustart nach dem ersten
  Boot; `gole1-info` zeigt `aplay -l`. Ausgabegerät in pavucontrol prüfen.
- **Sporadisches Einfrieren:** auf dem installierten System
  `intel_idle.max_cstate=1` in `GRUB_CMDLINE_LINUX_DEFAULT` in
  `/etc/default/grub.d/gole1.cfg` ergänzen, dann `sudo update-grub`.
  Für künftige Installationen: `KERNEL_ARGS` in `config/includes.chroot/etc/gole1.conf` setzen.
- **Nach dem Abmelden** erscheint eine Text-Anmeldung, dafür ist eine Tastatur
  nötig. Mit Auto-Login reicht ein Neustart.

## Status

Die Konfiguration ist vollständig, aber **noch nicht auf echter GOLE1-Hardware
getestet**. Hardware-Details (Display-Ausrichtung, Touch-Controller, WLAN-Chip)
stammen aus Erfahrungswerten für Cherry-Trail-Geräte. Deshalb gibt es die
Helfer `gole1-info`, `gole1-rotate` und den Ordner `firmware-extra/`.
