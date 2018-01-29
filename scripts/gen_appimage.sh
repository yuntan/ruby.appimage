#!/bin/bash

########################################################################
# Package the binaries built as an AppImage
# By Simon Peter 2016
# For more information, see http://appimage.org/
########################################################################

# App arch, used by generate_appimage.
if [ -z "$ARCH" ]; then
  export ARCH="$(arch)"
fi

# App name, used by generate_appimage.
APP=ruby
VERSION=2.3.6

APP_DIR="$PWD/$APP.AppDir"

echo "--> get ruby source"
wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.6.tar.gz
tar xf ruby-2.3.6.tar.gz

echo "--> compile Ruby and install it into AppDir"
pushd ruby-2.3.6
./configure --prefix=/usr
make
make "DESTDIR=$APP_DIR" install
popd

echo "--> patch away absolute paths"
sed -i -e 's|/usr|././|g' "$APP_DIR/usr/bin/ruby"

# remove doc, man, ri
rm -rf "$APP_DIR/usr/share"

########################################################################
# Get helper functions and move to AppDir
########################################################################
wget -q https://github.com/AppImage/AppImages/raw/master/functions.sh -O ./functions.sh
. ./functions.sh

# Copy desktop and icon file to AppDir for AppRun to pick them up.
# get_apprun
# get_desktop
# cp "$ROOT_DIR/runtime/nvim.desktop" "$APP_DIR/"
# cp "$ROOT_DIR/runtime/nvim.png" "$APP_DIR/"

pushd "$APP_DIR"

# copy dependencies
copy_deps
# move the libraries to usr/bin
move_lib

# delete stuff that should not go into the AppImage.
delete_blacklisted

########################################################################
# AppDir complete. Now package it as an AppImage.
########################################################################

# No need for a fancy script. AppRun can just be a symlink to nvim.
ln -s usr/bin/ruby AppRun

popd

# Generate AppImage.
#   - Expects: $ARCH, $APP, $VERSION env vars
#   - Expects: ./$APP.AppDir/ directory
#   - Produces: ../out/$APP-$VERSION.glibc$GLIBC_NEEDED-$ARCH.AppImage
generate_appimage

# NOTE: There is currently a bug in the `generate_appimage` function (see
# https://github.com/probonopd/AppImages/issues/228) that causes repeated builds
# that result in the same name to fail.
# Moving the final executable to a different folder gets around this issue.

# mv "$ROOT_DIR"/out/*.AppImage "$ROOT_DIR"/build/bin
# Remove the (now empty) folder the AppImage was built in
# rmdir "$ROOT_DIR"/out

echo '==> finished'
