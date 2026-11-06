# 构建指南

本文说明 Amlogic S905X2（Amlogic-ng，Linux 4.9.269）上 CoreELEC FPV 的
构建环境、工具链与镜像构建命令。

## 1. 构建环境

### Docker（推荐）

```shell
docker build -t dfp .
docker run -it -v $(pwd):/home/docker/CoreELEC --name mycontainer dfp bash
cd /home/docker/CoreELEC
```

仓库挂载在 `/home/docker/CoreELEC`，下文命令都在该目录下执行。

### 原生 Linux

x86_64 主机，依赖与上游 CoreELEC 相同。不确定时请用 Docker 镜像。

## 2. 工具链

仅首次构建需要：

```shell
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/build toolchain
```

## 3. 完整镜像

```shell
./build_ng_w100d.sh
```

等价于：

```shell
PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=arm DISTRO=CoreELEC \
SUBDEVICES_FILTER=ZTE_W100D make image
```

`SUBDEVICES_FILTER` 限定只构建列出的子设备，跳过 Odroid、Radxa、Generic
等其它板型。需要同时构建多个时：

```shell
SUBDEVICES_FILTER="ZTE_W100D Odroid_N2" ./build_ng_w100d.sh
```

脚本还会在内核构建后检查 `ZTE_W100D_dtb.img` 是否存在，缺失时删除内核构建
标记，避免增量构建产出缺少设备树的镜像。

产物：

```text
target/CoreELEC-Amlogic-ng.arm-21.2-Omega_devel_<时间戳>-<子设备>.img.gz
target/CoreELEC-Amlogic-ng.arm-21.2-Omega_devel_<时间戳>-<子设备>.img.gz.sha256
```

## 4. 内核与单个软件包

```shell
# 只构建内核
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/build linux

# 只构建单个包
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/build amlgsmenu

# 从头重新构建
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/clean amlgsmenu
```

## 5. 应用源码

`AMLgsMenu` 与 `AMLDigitalFPV` 以源码形式存放于 `third_party/`。对应的
`package.mk` 在解包阶段直接复制本地源码，不再从 GitHub 克隆；同时把源码树
哈希进 `PKG_STAMP`，因此任何改动都会在下次构建时自动生效：

```text
third_party/AMLgsMenu/       -> AMLgsMenu
third_party/AMLDigitalFPV/   -> AMLDigitalFPV
```

`packages/multimedia/*/` 下的上游启动脚本、默认数据与字体仍在安装阶段覆盖
`third_party/` 中的同名文件。

## 6. 说明

- 已启用 ccache：未改动任何源码时重复构建只需几秒；一旦某个源文件变化，仍会
  完整走一遍编译与链接。
- 构建产物位于 `build.CoreELEC-Amlogic-ng.arm-21/`，不受 git 跟踪。
