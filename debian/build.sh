#!/bin/bash
set -e
#--------------------------------------------------------------------------
# Construction du paquet Debian
#
# Syntaxe : deb_build.sh [nom_paquet] [version_asgard] [revision_paquet]
#-------------------------------------------------------------------------

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_DIR=$( cd "$SCRIPT_DIR" && cd .. && pwd )

# Usage
usage() {
  echo "Usage : $0 [nom_paquet] [version_asgard] [revision_paquet]"
  exit 1
}
[ $# -lt 3 ] && usage

# Lecture arguments
PKG_NAME=$1
PKG_VERSION=$2
DEB_REV=$3
DEB_ARCH=all
DEB_FULLNAME=${PKG_NAME}_${PKG_VERSION}-${DEB_REV}_${DEB_ARCH}

# Dossier de base et DEBIAN
mkdir $DEB_FULLNAME
cp -a $PROJECT_DIR/debian/DEBIAN $DEB_FULLNAME
# Mise à jour de la version et du nom du paquet dans les fichiers control et postinst
sed -i s/#PKG_VERSION#/$PKG_VERSION/ $DEB_FULLNAME/DEBIAN/control
sed -i s/#PKG_VERSION#/$PKG_VERSION/ $DEB_FULLNAME/DEBIAN/postinst
sed -i s/#PKG_NAME#/$PKG_NAME/ $DEB_FULLNAME/DEBIAN/control
sed -i s/#PKG_NAME#/$PKG_NAME/ $DEB_FULLNAME/DEBIAN/postinst
  
# La documentation
DEB_DOC_DIR=$DEB_FULLNAME/usr/share/doc/$PKG_NAME
mkdir -p $DEB_DOC_DIR
cp -r $PROJECT_DIR/debian/doc/* $DEB_DOC_DIR
gzip -n --best $DEB_DOC_DIR/changelog
cp $PROJECT_DIR/README.md $DEB_DOC_DIR
gzip -n --best $DEB_DOC_DIR/README.md

# Les fichiers Postgresql
DEB_LIB=$DEB_FULLNAME/usr/share/$PKG_NAME/$PKG_VERSION
mkdir -p $DEB_LIB
cp $PROJECT_DIR/asgard--*.sql $PROJECT_DIR/asgard.control $DEB_LIB

# Ajustement des permissions
find $DEB_FULLNAME -type f -exec chmod 644 {} \;
find $DEB_FULLNAME -type d -exec chmod 755 {} \;
chmod +x $DEB_FULLNAME/DEBIAN/post*

# Construction du paquet
dpkg-deb -Zxz --root-owner-group --build $DEB_FULLNAME 1>/dev/null
echo $DEB_FULLNAME.deb
