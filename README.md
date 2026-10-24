# CoreELEC_FPV

面向 **FPV 数字图传地面站** 的 Amlogic 固件,基于 [CoreELEC](https://coreelec.org)
21.2 Omega(`PROJECT=Amlogic-ce` / `DEVICE=Amlogic-ng` / `ARCH=arm`)定制。
目标硬件为 S905X2 等 Amlogic-ng 板卡,使用 Generic 通用镜像。

固件在标准 CoreELEC 基础上增加了完整的图传链路:

- **AMLDigitalFPV** —— 接收天空端 wfb-ng 转发的 RTP/H.265 流,经 GStreamer 解包、
  Amlogic VFM/amcodec 硬件解码后 HDMI 输出;支持 UDP `:5612` 控制协议
  (录像 / 声音开关 / ping)、minimp4 DVR 录像、音频接收(`PT 98`)。
- **AMLgsMenu** —— EGL/GLES2 透明叠加 OSD 菜单(libinput + ImGui),
  提供链路参数配置(信道/带宽/码率/功率/MCS/自适应)、MAVLink 遥测
  (UDP `:14452`)、地面端温度、远程同步与 SSH 命令下发,开机内嵌 splash 动画。
- **wfb-ng / GStreamer 依赖链** —— 视频源(tx/rx)与 `gst-plugins-good/base`
  等运行时组件,保证 `udpsrc → rtph265depay → h265parse → appsink` 可用。

## 目录结构

| 路径 | 说明 |
| --- | --- |
| `packages/multimedia/amldigitalfpv/` | 视频接收/解码/DVR 包(源码、启动脚本、systemd unit) |
| `packages/multimedia/amlgsmenu/` | OSD 菜单包(源码、字体、图标、`command.cfg`、`wfb.conf`) |
| `packages/multimedia/gstreamer/` | GStreamer 插件定制 |
| `packages/multimedia/wfb-ng/` | 无线图传链路组件 |
| `doc/项目架构总览.md` | 系统架构、进程/数据流、参数传递链 |
| `doc/模块流程图.md` | AMLgsMenu / AMLDigitalFPV 详细流程图 |
| `doc/刷机指南.md` | 烧写步骤与常见问题 |
| `build_ng.sh` | 一键构建 Amlogic-ng 镜像 |

## 构建

方式一:宿主机直接构建(推荐 Ubuntu 22.04,需安装 CoreELEC 依赖)

```shell
./build_ng.sh
```

等价于:

```shell
PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=arm DISTRO=CoreELEC make image
```

方式二:Docker 构建

```shell
docker build -t dfp .
docker run -it -v $(pwd):/home/docker/CoreELEC --name mycontainer dfp bash
# 容器内:
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/build toolchain
ARCH=arm PROJECT=Amlogic-ce DEVICE=Amlogic-ng scripts/build
```

产物位于 `target/`:

```
target/CoreELEC-Amlogic-ng.arm-21.2-Omega_devel_<时间戳>-Generic.img.gz
```

单独重编某个包(便于调试):

```shell
PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=arm scripts/build amlgsmenu
PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=arm scripts/build amldigitalfpv
```

## 运行机制概要

两个用户态进程由 systemd 依次拉起:

```
amlgsmenu.service     → /usr/bin/gsmenu.sh
                        └─ AMLgsMenu -t <ZC0005 字体> -T <LXGW 等宽字体>
amldigitalfpv.service → /usr/bin/amldigitalfpv.sh
                        └─ AMLDigitalFPV -w <宽> -h <高> -p <fps>
                                        -a <sound> -l <buf_level>
                                        -g <alignment> -m <dec_mode>
```

两个脚本都会优先使用 `/storage/digitalfpv`(或 `/storage/streamer`)下的可执行文件,
便于免刷机替换调试。

- 启动顺序:`amlgsmenu.service` → `amldigitalfpv.service`,均 `Restart=on-failure`
- 参数来源:`/storage/.config/wfb.conf`(首次启动从 `/usr/share/digitalfpv` 引导)
- 菜单修改链路参数后写回 `wfb.conf`,并通过 SSH/命令通道下发到天空端

详见 [doc/项目架构总览.md](doc/项目架构总览.md) 与 [doc/模块流程图.md](doc/模块流程图.md)。

## 烧写

见 [doc/刷机指南.md](doc/刷机指南.md)。

## 上游与许可

本项目基于 CoreELEC / LibreELEC 构建系统(GPLv2),并包含
[AMLDigitalFPV](https://github.com/imagemlt/AMLDigitalFPV)、
[AMLgsMenu](https://github.com/imagemlt/AMLgsMenu) 等项目代码。
所有上游代码版权归其各自作者所有;CoreELEC 原始代码以
[GPLv2](https://www.gnu.org/licenses/gpl-2.0.html) 发布。

问题与支持:请在本仓库提交 Issue。
