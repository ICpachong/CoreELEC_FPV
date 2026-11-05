# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present Team CoreELEC (https://coreelec.org)

PKG_NAME="resource.language.zh_cn"
PKG_VERSION="11.0.104"
PKG_SHA256="ccc385765b07bca7582c9158282fcd061241da58f169399b082a96703b5b2434"
PKG_LICENSE="GPL-2.0-only"
PKG_SITE="https://kodi.tv"
PKG_URL="https://mirrors.kodi.tv/addons/omega/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.zip"
PKG_SOURCE_DIR="${PKG_NAME}"
PKG_DEPENDS_TARGET="kodi"
PKG_LONGDESC="Chinese (Simple) language pack for Kodi"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/kodi/addons
    cp -a ${PKG_BUILD} ${INSTALL}/usr/share/kodi/addons/${PKG_NAME}
}

post_install() {
  manifest="${INSTALL}/usr/share/kodi/system/addon-manifest.xml"
  [ -f "${manifest}" ] || return 0
  grep -q "<addon>${PKG_NAME}</addon>" "${manifest}" && return 0
  xmlstarlet ed -L --subnode "/addons" -t elem -n "addon" -v "${PKG_NAME}" "${manifest}"
}
