# CoreELEC FPV for Amlogic S905X2

**English** | [简体中文](README.zh.md)

A customized fork of [CoreELEC](https://coreelec.org) 21.2-Omega (project `Amlogic-ce`, device `Amlogic-ng`, Linux 4.9.269) for Amlogic **S905X2 (G12A)** TV boxes and cloud terminals, with an FPV ground-station stack layered on top of Kodi.

The reference hardware is a 2 GB DDR4 / 8 GB eMMC S905X2 board with no RJ45 port. The vendor u-boot is kept untouched: the system boots from SD/USB media and can be installed to the internal eMMC without erasing the vendor bootloader.

## What this fork adds

| Area | Change |
| --- | --- |
| Board support | S905X2 subdevice using the existing `g12a_s905x2_2g.dtb`; `SUBDEVICES_FILTER` support to build only one board |
| Boot | `cfgload` boot script: RGB 8-bit HDMI by default, 1080p60 default mode, serial console only (no `console=tty0`, so kernel messages never cover the OSD) |
| eMMC install | `install2emmc` tool: backs up the first 4 MiB (vendor u-boot + environment + dtb), creates a standard MBR, restores u-boot, boot partition starts at 1000 MiB; booted with `emmc_mbr=1` so Linux ignores the Amlogic MPT |
| Kernel | `linux-11-add-emmc-mbr-boot-option.patch` plus USB NIC drivers preloaded at boot |
| Networking | `network-rescue` service: forces DHCP retries on wired links and offers an optional static fallback |
| FPV apps | `amldigitalfpv` (RTP H.265 receiver, decode via `libamcodec`) and `amlgsmenu` (GLES/ImGui OSD and settings menu) |
| Digital video | `wfb-ng` tools (`wfb_rx`, `wfb_tx`, `wfb_keygen`) and a default `wfb.conf` |
| Localization | Simplified Chinese Kodi language pack (`resource.language.zh_cn`) bundled |

## Hardware

| Item | Value |
| --- | --- |
| SoC | Amlogic S905X2 (G12A), 4x Cortex-A53 |
| Memory | 2 GB DDR4 (reference board) |
| Storage | 8 GB eMMC (reference board) |
| Network | WiFi 5 + Bluetooth 5.0 on the reference board; **no RJ45 port** |
| Ports | HDMI, 3x USB 2.0, Type-C power |
| Bootloader | Vendor u-boot; the first 4 MiB of the eMMC is reserved and never overwritten |

## Build

Building requires a Linux host (x86_64) or the provided Docker image. See [BUILD_FPV.md](docs/BUILD_FPV.md) for the Docker workflow.

```shell
# 1. Toolchain and cross-compiler (first build only)
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/build toolchain

# 2. Build the S905X2 image
./build_ng_w100d.sh
```

The script sets `PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=arm DISTRO=CoreELEC` and builds the S905X2 subdevice only.

Output:

```text
target/CoreELEC-Amlogic-ng.arm-21.2-Omega_devel_<timestamp>-<subdevice>.img.gz
target/CoreELEC-Amlogic-ng.arm-21.2-Omega_devel_<timestamp>-<subdevice>.img.gz.sha256
```

To build additional subdevices, set `SUBDEVICES_FILTER` before running the script, for example `SUBDEVICES_FILTER="Odroid_N2"`.

## Flash and install

1. Write the `.img.gz` to an SD card or USB stick (balenaEtcher, Rufus in DD mode, or `dd`).
2. Boot the box from that media; the first boot takes a while.
3. Install to eMMC from the running system:

```shell
install2emmc -y
```

4. Power off, remove the boot media, power on. The box now boots from eMMC.

Detailed steps, boot-chain explanation and troubleshooting: [docs/flashing-guide.md](docs/flashing-guide.md).

## Repository layout

| Path | Purpose |
| --- | --- |
| `build_ng_w100d.sh` | Build entry point for the S905X2 image |
| `distributions/CoreELEC/` | Distribution version (`21.2` Omega) and package selection |
| `projects/Amlogic-ce/devices/Amlogic-ng/options` | Device config: kernel, subdevice list, additional drivers and firmware |
| `projects/Amlogic-ce/devices/Amlogic-ng/bootloader/` | `cfgload`/`autoscript` sources, `config.ini`, `dtb.conf`, image hooks |
| `projects/Amlogic-ce/devices/Amlogic-ng/filesystem/usr/bin/install2emmc` | eMMC installer |
| `projects/Amlogic-ce/devices/Amlogic-ng/patches/linux/` | Kernel patches, including the eMMC MBR boot option |
| `projects/Amlogic-ce/filesystem/usr/bin/network-rescue.sh` | Wired network fallback |
| `packages/multimedia/amldigitalfpv/` | FPV video receiver and its service unit |
| `packages/multimedia/amlgsmenu/` | OSD/settings menu, default `wfb.conf`, fonts and icons |
| `packages/multimedia/wfb-ng/` | `wfb-ng` userspace tools |
| `docs/` | Chinese documentation (guide, architecture, diagrams) |

## Documentation

All documentation under `docs/` is written in Chinese.

- [Flash and troubleshooting guide](docs/flashing-guide.md)
- [Architecture overview](docs/architecture-overview.md)
- [Workflow and boot diagrams](docs/workflow-diagrams.md)
- [Build guide](docs/BUILD_FPV.md)

## Known limitations

- **Onboard WiFi and Bluetooth do not work on the reference board.** It uses a MediaTek MT7663 SDIO combo. The 4.9.269 kernel has no MT7663S driver (the bundled `wlan_mt76x8_sdio` only matches `0x6602`/`0x7608`), and the MT7663 firmware is not packaged. Use a USB Ethernet adapter (drivers are preloaded) or a USB WiFi dongle. Background and diagnostics are in [docs/flashing-guide.md](docs/flashing-guide.md) section 8.1.
- Other subdevices listed in `SUBDEVICES` still build, but only the S905X2 target is tested by this fork.
- Kernel video decode relies on the Amlogic `amcodec` stack; the six `aml*` kernel modules and `libamcodec` are version-locked to Linux 4.9.

## Upstream and license

This repository is based on [CoreELEC](https://github.com/CoreELEC/CoreELEC), a minor fork of [LibreELEC](https://libreelec.tv), which runs [Kodi](https://kodi.tv).

- CoreELEC original code is released under [GPLv2](https://www.gnu.org/licenses/gpl-2.0.html).
- Patches to upstream code keep the upstream license unless stated otherwise.
- `amldigitalfpv` is GPL-3.0; `amlgsmenu` is proprietary, see its package metadata.

As this tree includes code from many upstream projects it includes many copyright owners. CoreELEC makes no claim of copyright on upstream code. Unless expressly stated otherwise, all code submitted to this repository is licensed under GPLv2; you are free to retain your own copyright by adding a copyright header to files you submit.
