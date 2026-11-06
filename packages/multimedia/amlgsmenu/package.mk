# SPDX-License-Identifier: GPL-3.0-or-later

PKG_NAME="amlgsmenu"
PKG_VERSION="7828c62daadae1bec2143c238d11c73da8a19ed1"
PKG_LICENSE="proprietary"
PKG_SITE="https://github.com/imagemlt/AMLgsMenu"
PKG_DEPENDS_TARGET="toolchain libinput systemd opengl-meson openssl"
PKG_LONGDESC="Transparent OSD and configuration menu for Amlogic GLES/fbdev targets using libinput + Dear ImGui (no SDL)."
PKG_TOOLCHAIN="cmake"

# Build from the vendored copy in third_party/ instead of cloning from GitHub
AMLGSMENU_SRC="${ROOT}/third_party/AMLgsMenu"

# Fold the source tree state into the stamp, so any edit triggers a rebuild
PKG_STAMP="$(find "${AMLGSMENU_SRC}" -type f -printf '%P %s %T@\n' 2>/dev/null | LC_ALL=C sort | sha256sum)"

unpack() {
  rm -rf "${PKG_BUILD}"
  mkdir -p "${PKG_BUILD}"
  # submodules (imgui, mavlink) are already checked out in the working copy
  tar -C "${AMLGSMENU_SRC}" --exclude=.git -cf - . | tar -C "${PKG_BUILD}" -xf -
}

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="-DIMGUI_ROOT=${PKG_BUILD}/third_party/imgui -DMAVLINK_ROOT=${PKG_BUILD}/third_party/mavlink -DAML_ENABLE_GLES=ON"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_BUILD}/.${TARGET_NAME}/AMLgsMenu ${INSTALL}/usr/bin/

  # startup script
  cp ${PKG_DIR}/scripts/gsmenu.sh ${INSTALL}/usr/bin/
  chmod 0755 ${INSTALL}/usr/bin/gsmenu.sh

  # factory defaults (icons, fonts, wfb.conf, command.cfg)
  mkdir -p ${INSTALL}/usr/share/digitalfpv
  cp -a ${PKG_DIR}/data/. ${INSTALL}/usr/share/digitalfpv/
  mkdir -p ${INSTALL}/usr/share/digitalfpv/fonts
  cp -a ${PKG_DIR}/fonts/*.ttf ${INSTALL}/usr/share/digitalfpv/fonts/
}

post_install() {
  enable_service amlgsmenu.service
}
