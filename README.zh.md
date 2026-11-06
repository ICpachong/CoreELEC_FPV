# CoreELEC FPV（Amlogic S905X2）

[English](README.md) | **简体中文**

本仓库是 [CoreELEC](https://coreelec.org) 21.2-Omega（项目 `Amlogic-ce`、设备 `Amlogic-ng`、Linux 4.9.269）的定制分支，面向 Amlogic **S905X2（G12A）** 系列的电视盒子与云终端，并在 Kodi 之上集成了 FPV 图传地面站组件。

参考硬件为 2 GB DDR4 / 8 GB eMMC 的 S905X2 板卡，无 RJ45 网口。系统保留厂商 u-boot 不动，可从 SD 卡/U 盘启动，也能安装到板载 eMMC 而不擦除原厂引导。

## 本分支的定制内容

| 领域 | 内容 |
| --- | --- |
| 板型支持 | S905X2 子设备，复用 `g12a_s905x2_2g.dtb`；支持用 `SUBDEVICES_FILTER` 只构建单一板型 |
| 启动 | `cfgload` 启动脚本：HDMI 默认 RGB 8bit、默认 1080p60、仅保留串口控制台（不带 `console=tty0`，内核日志不会盖住 OSD） |
| eMMC 安装 | `install2emmc` 工具：先备份前 4 MiB（厂商 u-boot + 环境变量 + dtb），创建标准 MBR，再把 u-boot 写回；boot 分区从 1000 MiB 开始；启动时带 `emmc_mbr=1`，让 Linux 忽略 Amlogic MPT |
| 内核 | 新增 `linux-11-add-emmc-mbr-boot-option.patch`，并预加载 USB 网卡驱动 |
| 网络 | `network-rescue` 服务：有线口 DHCP 反复重试，可选静态地址兜底 |
| FPV 应用 | `amldigitalfpv`（接收 RTP H.265，经 `libamcodec` 硬解）、`amlgsmenu`（GLES/ImGui OSD 与设置菜单） |
| 数字图传 | `wfb-ng` 工具（`wfb_rx`、`wfb_tx`、`wfb_keygen`）以及默认 `wfb.conf` |
| 本地化 | 内置 Kodi 简体中文语言包（`resource.language.zh_cn`） |

## 硬件参数

| 项目 | 参数 |
| --- | --- |
| SoC | Amlogic S905X2（G12A），4x Cortex-A53 |
| 内存 | 2 GB DDR4（参考板） |
| 存储 | 8 GB eMMC（参考板） |
| 网络 | 参考板为 WiFi 5 + 蓝牙 5.0；**无 RJ45 网口** |
| 接口 | HDMI、3x USB 2.0、Type-C 供电 |
| 引导 | 厂商 u-boot；eMMC 前 4 MiB 为保留区，任何操作都不会覆盖 |

## 构建

需要 Linux（x86_64）主机，或使用仓库自带的 Docker 镜像；Docker 流程见 [BUILD_FPV.md](BUILD_FPV.md)。

```shell
# 1. 首次构建先编译工具链
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/build toolchain

# 2. 构建 S905X2 镜像
./build_ng_w100d.sh
```

该脚本会设置 `PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=arm DISTRO=CoreELEC`，并且只构建 S905X2 子设备。

产物：

```text
target/CoreELEC-Amlogic-ng.arm-21.2-Omega_devel_<时间戳>-<子设备名>.img.gz
target/CoreELEC-Amlogic-ng.arm-21.2-Omega_devel_<时间戳>-<子设备名>.img.gz.sha256
```

如需同时构建其它板型，在调用前设置 `SUBDEVICES_FILTER`，例如 `SUBDEVICES_FILTER="Odroid_N2"`。

## 刷写与安装

1. 把 `.img.gz` 写入 SD 卡或 U 盘（balenaEtcher、Rufus 的 DD 模式，或 `dd`）。
2. 从该介质启动盒子，首次启动耗时较长。
3. 进入系统后安装到 eMMC：

```shell
install2emmc -y
```

4. 关机、拔出启动介质、重新上电，即从 eMMC 启动。

完整步骤、启动链说明和故障排查见 [docs/flashing-guide.md](docs/flashing-guide.md)。

## 目录结构

| 路径 | 作用 |
| --- | --- |
| `build_ng_w100d.sh` | 构建 S905X2 镜像的入口脚本 |
| `distributions/CoreELEC/` | 发行版版本（`21.2` Omega）与软件包选择 |
| `projects/Amlogic-ce/devices/Amlogic-ng/options` | 设备级配置：内核、子设备列表、附加驱动与固件 |
| `projects/Amlogic-ce/devices/Amlogic-ng/bootloader/` | `cfgload`/`autoscript` 脚本源、`config.ini`、`dtb.conf`、镜像生成钩子 |
| `projects/Amlogic-ce/devices/Amlogic-ng/filesystem/usr/bin/install2emmc` | eMMC 安装工具 |
| `projects/Amlogic-ce/devices/Amlogic-ng/patches/linux/` | 内核补丁，含 eMMC MBR 启动选项 |
| `projects/Amlogic-ce/filesystem/usr/bin/network-rescue.sh` | 有线网络兜底脚本 |
| `packages/multimedia/amldigitalfpv/` | FPV 视频接收程序及其 systemd 单元 |
| `packages/multimedia/amlgsmenu/` | OSD/设置菜单、默认 `wfb.conf`、字体与图标 |
| `packages/multimedia/wfb-ng/` | `wfb-ng` 用户态工具 |
| `docs/` | 中文文档（刷机教程、架构总览、流程图） |

## 文档

`docs/` 下的文档均为中文。

- [刷机教程与故障排查](docs/flashing-guide.md)
- [项目架构总览](docs/architecture-overview.md)
- [流程与启动模型图](docs/workflow-diagrams.md)
- [构建环境说明](BUILD_FPV.md)
- [eMMC 黑屏调试记录](debug-emmc-boot-black-screen.md)

## 已知限制

- **参考板的板载 WiFi 与蓝牙不可用。** 该板使用 MediaTek MT7663 SDIO combo。4.9.269 内核没有 MT7663S 驱动（自带的 `wlan_mt76x8_sdio` 只匹配 `0x6602`/`0x7608`），且 MT7663 固件未打进镜像。请使用 USB 有线网卡（驱动已预加载）或 USB WiFi 网卡。原因与排查方法见 [docs/flashing-guide.md](docs/flashing-guide.md) 第 8.1 节。
- `SUBDEVICES` 中的其它板型仍可构建，但本分支只验证了 S905X2 目标。
- 内核视频解码依赖 Amlogic `amcodec` 体系，六个 `aml*` 内核模块与 `libamcodec` 均与 Linux 4.9 版本绑定。

## 上游与许可证

本仓库基于 [CoreELEC](https://github.com/CoreELEC/CoreELEC)，后者是 [LibreELEC](https://libreelec.tv) 的分支，用于运行 [Kodi](https://kodi.tv)。

- CoreELEC 原创代码以 [GPLv2](https://www.gnu.org/licenses/gpl-2.0.html) 发布。
- 对上游代码的补丁，除非另有说明，沿用上游许可证。
- `amldigitalfpv` 为 GPL-3.0；`amlgsmenu` 为专有软件，详见其包元数据。

本代码树包含来自众多上游项目的代码，因此涉及众多版权所有者。CoreELEC 不对上游代码主张版权。除非另有明确声明，提交到本仓库的代码均以 GPLv2 授权；你可以在自己提交的文件中添加版权声明以保留版权。
