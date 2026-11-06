# Build guide

Build environment, toolchain and image commands for CoreELEC FPV on
Amlogic S905X2 (Amlogic-ng, Linux 4.9.269).

## 1. Build environment

### Docker (recommended)

```shell
docker build -t dfp .
docker run -it -v $(pwd):/home/docker/CoreELEC --name mycontainer dfp bash
cd /home/docker/CoreELEC
```

The repository is mounted at `/home/docker/CoreELEC`; all commands below run
inside that directory.

### Native Linux

A x86_64 host with the same dependencies used by upstream CoreELEC. Use the
Docker image if unsure.

## 2. Toolchain

First build only:

```shell
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/build toolchain
```

## 3. Full image

```shell
./build_ng_w100d.sh
```

Equivalent to:

```shell
PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=arm DISTRO=CoreELEC \
SUBDEVICES_FILTER=ZTE_W100D make image
```

`SUBDEVICES_FILTER` limits the build to the listed subdevices, which skips
Odroid, Radxa, Generic and other boards. To build several at once:

```shell
SUBDEVICES_FILTER="ZTE_W100D Odroid_N2" ./build_ng_w100d.sh
```

The script also checks that `ZTE_W100D_dtb.img` exists after a kernel build and
drops the kernel stamp if it does not, so an incremental build cannot ship an
image without the device tree.

Output:

```text
target/CoreELEC-Amlogic-ng.arm-21.2-Omega_devel_<timestamp>-<subdevice>.img.gz
target/CoreELEC-Amlogic-ng.arm-21.2-Omega_devel_<timestamp>-<subdevice>.img.gz.sha256
```

## 4. Kernel and single packages

```shell
# kernel only
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/build linux

# one package
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/build amlgsmenu

# rebuild from scratch
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/clean amlgsmenu
```

## 5. Application sources

`AMLgsMenu` and `AMLDigitalFPV` are vendored under `third_party/`. The
`package.mk` files copy them into the build directory during unpack instead of
cloning from GitHub, and hash the source tree into `PKG_STAMP`, so any edit is
picked up by the next build automatically:

```text
third_party/AMLgsMenu/       -> AMLgsMenu
third_party/AMLDigitalFPV/   -> AMLDigitalFPV
```

Upstream startup scripts, default data and fonts under
`packages/multimedia/*/` still override the vendored ones at install time.

## 6. Notes

- ccache is enabled; repeated builds of an unchanged package finish in seconds.
  A changed source file still goes through a full compile and link.
- Build artifacts live in `build.CoreELEC-Amlogic-ng.arm-21/` and are not
  tracked by git.
