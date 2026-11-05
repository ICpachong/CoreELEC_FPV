#!/bin/bash
# 只构建中兴 W100D(S905X2)的镜像,不生成 Odroid/Radxa/Generic 等其它板型
#
#   ./build_ng_w100d.sh
#
# 等价于:
#   PROJECT=Amlogic-ce DEVICE=Amlogic-ng ARCH=arm DISTRO=CoreELEC \
#   SUBDEVICES_FILTER=ZTE_W100D make image
#
# 需要其它板型时直接 export SUBDEVICES_FILTER="ZTE_W100D Odroid_N2" 再调用本脚本。

cd "$(dirname "$0")" || exit 1

export PROJECT=Amlogic-ce
export DEVICE=Amlogic-ng
export ARCH=arm
export DISTRO=CoreELEC
export SUBDEVICES_FILTER="${SUBDEVICES_FILTER:-ZTE_W100D}"

BUILD_DIR="build.CoreELEC-Amlogic-ng.arm-21"
STAMP="${BUILD_DIR}/.stamps/linux/build_target"

# 增量构建保护:SUBDEVICES 变更后内核包的 stamp 不一定失效,若已构建过内核
# 却没有 ZTE_W100D_dtb.img,镜像里就会缺 dtb.img。此时强制重新构建内核包。
if [ -f "${STAMP}" ]; then
  W100D_DTB=$(find "${BUILD_DIR}/build" -maxdepth 5 -path "*/arch/arm64/boot/ZTE_W100D_dtb.img" 2>/dev/null | head -n1)
  if [ -z "${W100D_DTB}" ]; then
    echo "==> 未找到 ZTE_W100D_dtb.img,删除内核构建标记以重新生成(内核将重新编译,耗时较长)"
    rm -f "${STAMP}"
  fi
fi

echo "==> 构建板型: ${SUBDEVICES_FILTER}"
make image 2>&1
ret=$?

if [ ${ret} -ne 0 ]; then
  echo "==> 构建失败(退出码 ${ret}),请检查上方日志"
  exit ${ret}
fi

echo "==> 构建完成,产物:"
for device in ${SUBDEVICES_FILTER}; do
  img=$(ls -t target/*-${device}.img.gz 2>/dev/null | head -n1)
  if [ -n "${img}" ]; then
    echo "    ${img}"
    echo "    ${img}.sha256"
  else
    echo "    未找到 ${device} 镜像,请检查构建日志"
  fi
done
