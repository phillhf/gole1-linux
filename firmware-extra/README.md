# Zusätzliche Firmware

Alles in diesem Ordner (außer dieser README) wird beim Bauen nach
`/usr/lib/firmware/` ins System kopiert. Die Unterordner-Struktur bleibt erhalten.

## WLAN (Broadcom/AMPAK, z. B. AP6255 → `brcmfmac43455-sdio`)

Der Treiber braucht neben der Firmware eine **board-spezifische NVRAM-Datei**,
die Debian nicht mitliefert. Am einfachsten aus dem vorhandenen Windows des
GOLE1 holen, **bevor** der eMMC überschrieben wird:

1. Unter Windows im Ordner `C:\Windows\System32\DriverStore\FileRepository\`
   nach `4345*.txt` bzw. `*nvram*.txt` suchen (Ordner heißt meist `bcmdhd...`).
2. Datei hierher kopieren als `brcm/brcmfmac43455-sdio.txt`
   (bei anderem Chip den Namen aus `gole1-info` → `dmesg` übernehmen).
3. ISO neu bauen.

## Touchscreen (nur falls Silead-Controller)

Zeigt `gole1-info` einen Silead-Touch (`MSSL1680`) ohne Funktion, wird eine
Firmware `silead/<name>.fw` benötigt – siehe
https://github.com/onitake/gsl-firmware
