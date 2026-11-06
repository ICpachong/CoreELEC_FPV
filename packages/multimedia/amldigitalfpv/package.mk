# SPDX-License-Identifier: GPL-3.0-or-later

PKG_NAME="amldigitalfpv"
PKG_VERSION="503573e5f020ec56f29d741ed9b7c3f2c1ac54a3"
PKG_LICENSE="GPL-3.0"
PKG_SITE="https://github.com/imagemlt/AMLDigitalFPV"
PKG_DEPENDS_TARGET="toolchain gstreamer gst-plugins-base gst-plugins-bad gst-plugins-good libamcodec opus libfmt spdlog pulseaudio"
PKG_LONGDESC="AMLDigitalFPV ground station video receiver (RTP H.265 -> amcodec)"
PKG_TOOLCHAIN="cmake"

# Build from the vendored copy in third_party/ instead of cloning from GitHub
AMLDIGITALFPV_SRC="${ROOT}/third_party/AMLDigitalFPV"

# Fold the source tree state into the stamp, so any edit triggers a rebuild
PKG_STAMP="$(find "${AMLDIGITALFPV_SRC}" -type f -printf '%P %s %T@\n' 2>/dev/null | LC_ALL=C sort | sha256sum)"

unpack() {
  rm -rf "${PKG_BUILD}"
  mkdir -p "${PKG_BUILD}"
  # submodule (src/concurrentqueue) is already checked out in the working copy
  tar -C "${AMLDIGITALFPV_SRC}" --exclude=.git -cf - . | tar -C "${PKG_BUILD}" -xf -
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
