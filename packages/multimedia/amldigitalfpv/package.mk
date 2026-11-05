# SPDX-License-Identifier: GPL-3.0-or-later

PKG_NAME="amldigitalfpv"
PKG_VERSION="503573e5f020ec56f29d741ed9b7c3f2c1ac54a3"
PKG_LICENSE="GPL-3.0"
PKG_SITE="https://github.com/imagemlt/AMLDigitalFPV"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="main"
PKG_DEPENDS_TARGET="toolchain gstreamer gst-plugins-base gst-plugins-bad gst-plugins-good libamcodec opus libfmt spdlog pulseaudio"
PKG_LONGDESC="AMLDigitalFPV ground station video receiver (RTP H.265 -> amcodec)"
PKG_TOOLCHAIN="cmake"

post_unpack() {
  git -C ${PKG_BUILD} submodule update --init --recursive
}

pre_configure_target() {
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}
  PKG_CMAKE_OPTS_TARGET="-DCMAKE_SYSROOT=${PKG_ORIG_SYSROOT_PREFIX:-${SYSROOT_PREFIX}}"
}

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/share

  # init scripts and systemd units
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/scripts/amldigitalfpv.sh ${INSTALL}/usr/bin/
  chmod 0755 ${INSTALL}/usr/bin/amldigitalfpv.sh
}

post_install() {
  enable_service amldigitalfpv.service
}
