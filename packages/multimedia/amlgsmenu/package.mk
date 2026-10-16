# SPDX-License-Identifier: GPL-3.0-or-later

PKG_NAME="amlgsmenu"
PKG_VERSION="7828c62daadae1bec2143c238d11c73da8a19ed1"
PKG_LICENSE="proprietary"
PKG_SITE="https://github.com/imagemlt/AMLgsMenu"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="main"
PKG_DEPENDS_TARGET="toolchain libinput systemd opengl-meson openssl"
PKG_LONGDESC="Transparent OSD and configuration menu for Amlogic GLES/fbdev targets using libinput + Dear ImGui (no SDL)."
PKG_TOOLCHAIN="cmake"

post_unpack() {
  git -C ${PKG_BUILD} submodule update --init --recursive
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
