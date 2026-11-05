# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gst-plugins-good"
PKG_VERSION="1.24.2"
PKG_SHA256="6e347c72d4b8b2886d890ffe9f6767a9edb02f201588e8c3a572dcd08d9852bd"
PKG_LICENSE="LGPL-2.1-or-later"
PKG_SITE="https://gstreamer.freedesktop.org/modules/gst-plugins-good.html"
PKG_URL="https://gstreamer.freedesktop.org/src/gst-plugins-good/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain gst-plugins-base"
PKG_LONGDESC="Good GStreamer plugins and helper libraries"
PKG_BUILD_FLAGS="-gold"

pre_configure_target() {
  PKG_MESON_OPTS_TARGET="-Dexamples=disabled \
                         -Dtests=disabled \
                         -Dnls=disabled \
                         -Dorc=disabled \
                         -Ddoc=disabled \
                         -Dgobject-cast-checks=disabled \
                         -Dglib-asserts=disabled \
                         -Dglib-checks=disabled \
                         -Dpackage-name=gst-plugins-good \
                         -Dpackage-origin=CoreELEC \
                         -Dalpha=disabled \
                         -Dapetag=disabled \
                         -Daudiofx=disabled \
                         -Daudioparsers=disabled \
                         -Dauparse=disabled \
                         -Dautodetect=disabled \
                         -Davi=disabled \
                         -Dcutter=disabled \
                         -Ddebugutils=disabled \
                         -Ddeinterlace=disabled \
                         -Ddtmf=disabled \
                         -Deffectv=disabled \
                         -Dequalizer=disabled \
                         -Dflv=disabled \
                         -Dflx=disabled \
                         -Dgoom=disabled \
                         -Dgoom2k1=disabled \
                         -Dicydemux=disabled \
                         -Did3demux=disabled \
                         -Dimagefreeze=disabled \
                         -Dinterleave=disabled \
                         -Disomp4=enabled \
                         -Dlaw=disabled \
                         -Dlevel=disabled \
                         -Dmatroska=disabled \
                         -Dmonoscope=disabled \
                         -Dmultifile=disabled \
                         -Dmultipart=disabled \
                         -Dreplaygain=disabled \
                         -Drtp=enabled \
                         -Drtpmanager=enabled \
                         -Drtsp=disabled \
                         -Dshapewipe=disabled \
                         -Dsmpte=disabled \
                         -Dspectrum=disabled \
                         -Dudp=enabled \
                         -Dvideobox=disabled \
                         -Dvideocrop=disabled \
                         -Dvideofilter=disabled \
                         -Dvideomixer=disabled \
                         -Dwavenc=disabled \
                         -Dwavparse=disabled \
                         -Dxingmux=disabled \
                         -Dy4m=disabled \
                         -Dadaptivedemux2=disabled \
                         -Daalib=disabled \
                         -Damrnb=disabled \
                         -Damrwbdec=disabled \
                         -Dbz2=disabled \
                         -Dcairo=disabled \
                         -Ddv=disabled \
                         -Ddv1394=disabled \
                         -Dflac=disabled \
                         -Dgdk-pixbuf=disabled \
                         -Dgtk3=disabled \
                         -Djack=disabled \
                         -Djpeg=disabled \
                         -Dlame=disabled \
                         -Dlibcaca=disabled \
                         -Dmpg123=disabled \
                         -Doss=disabled \
                         -Doss4=disabled \
                         -Dosxaudio=disabled \
                         -Dosxvideo=disabled \
                         -Dpng=disabled \
                         -Dpulse=disabled \
                         -Dshout2=disabled \
                         -Dspeex=disabled \
                         -Dtaglib=disabled \
                         -Dtwolame=disabled \
                         -Dvpx=disabled \
                         -Dwaveform=disabled \
                         -Dwavpack=disabled \
                         -Dv4l2=enabled \
                         -Dv4l2-probe=true \
                         -Dv4l2-libv4l2=disabled \
                         -Dv4l2-gudev=disabled \
                         -Dsoup=disabled \
                         -Dqt5=disabled \
                         -Dqt6=disabled \
                         -Dximagesrc=disabled \
                         -Drpicamsrc=disabled"
}

post_makeinstall_target() {
  # clean up: keep libs and gstreamer-1.0 plugins for the image
  for d in bin include share; do
    if [ -e ${INSTALL}/usr/$d -o -L ${INSTALL}/usr/$d ]; then
      safe_remove ${INSTALL}/usr/$d
    fi
  done
}
