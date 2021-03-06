#!/bin/bash

PKG_BUILD_ROOT=$HOME/pkgbuild
DEST_DIR_ROOT=${PKG_BUILD_ROOT}/packages
CURR_DIR=`pwd`
GIT_IGRAPH_ROOT=${PKG_BUILD_ROOT}/git/igraph

SIGN=yes
SIGNING_GPG_KEY=D6360653

#####################################################################


if [ $# -ne 3 ]; then
    echo "Usage: $0 igraph_version debian_revision series git_branch"
	echo "where igraph_version is the version number of igraph,"
	echo "debian_revision is the Debian package revision number,"
	echo "series is the distribution series (e.g., unstable,"
	echo "karmic, jaunty etc) and git_branch is the name of the git"
	echo "branch from which the package will be built."
	echo ""
	echo "For the Launchpad PPA, you have to prepare a package"
	echo "for the two most recent Ubuntu series"
	exit 1
fi

IGRAPH_VERSION=$1
DEBIAN_REVISION=$2
SERIES=$3
GIT_BRANCH=$4

DEST_DIR=${DEST_DIR_ROOT}/${SERIES}

if [ x$SIGN == xyes ]; then
  SIGN_OPTIONS="-k0x${SIGNING_GPG_KEY}"
else
  SIGN_OPTIONS="-us -uc"
fi

function prechecks {
  if [ ! -d ${GIT_IGRAPH_ROOT} ]; then
    echo ${GIT_IGRAPH_ROOT} does not exist or is not a directory!
    exit 1
  fi

  if [ x$SIGN == xyes ]; then
    which gpg >/dev/null || ( echo "gpg not installed, exiting"; exit 1 )
    gpg --list-secret-keys ${SIGNING_GPG_KEY} >/dev/null || ( echo "Secret key not found: ${SIGNING_GPG_KEY}, exiting"; exit 1 )
  fi
}

function install_build_dependencies {
  apt-get update
  apt-get -y --no-install-recommends install \
          cdbs debhelper devscripts fakeroot automake autoconf gcc g++ \
          pkg-config flex bison build-essential libxml2-dev libglpk-dev \
          libarpack2-dev libgmp3-dev libxml2-dev libblas-dev liblapack-dev \
          python-all-dev python-central python-epydoc texlive-latex-base \
		  texlive-latex-extra libtool source-highlight docbook2x
}

function make_destdir {
  mkdir -p ${DEST_DIR}
}

function git_pull {
  pushd ${GIT_IGRAPH_ROOT}/${GIT_BRANCH}
  git pull
  git checkout ${GIT_BRANCH}
  popd
}

function create_igraph_debian_pkg {
  if [ -f ${CURR_DIR}/igraph_$1.orig.tar.gz ]; then
    cp ${CURR_DIR}/igraph_$1.orig.tar.gz .
  else
    wget -O igraph_$1.orig.tar.gz http://files.igraph.org/c/igraph-$1.tar.gz
  fi
  tar -xvvzf igraph_$1.orig.tar.gz
  cd igraph-$1
  cp -r ${GIT_IGRAPH_ROOT}/${GIT_BRANCH}/debian .
  cat debian/changelog | sed -e "s/unstable/${SERIES}/g" >debian/changelog.new
  mv debian/changelog.new debian/changelog
  debuild -S -sa ${SIGN_OPTIONS}
  debuild -b ${SIGN_OPTIONS}
  cd ..
}

function install_igraph_debian_pkg {
  if [ x$2 != x0 ]; then
    FULLVERSION=$1-$2
  else
    FULLVERSION=$1
  fi
  ${SUDO} dpkg -i libigraph0_${FULLVERSION}_*.deb libigraph-dev_${FULLVERSION}_*.deb || exit 3
}

function remove_igraph_debian_pkg {
  dpkg -r libigraph0 libigraph-dev
}

function compile_python_interface {
  if [ -f ${CURR_DIR}/python-igraph_$1.orig.tar.gz ]; then
    cp ${CURR_DIR}/python-igraph_$1.orig.tar.gz .
  else
    wget -O python-igraph_$1.orig.tar.gz http://pypi.python.org/packages/source/p/python-igraph/python-igraph-$1.tar.gz
  fi
  tar -xvvzf python-igraph_$1.orig.tar.gz
  cd python-igraph-$1
  if [ x$2 != x0 ]; then
    cat debian/changelog.in | sed -e "s/@VERSION@/@VERSION@-$2/g" >debian/changelog.in.new
  fi
  mv debian/changelog.in.new debian/changelog.in
  debian/prepare
  cat debian/changelog | sed -e "s/unstable/${SERIES}/g" >debian/changelog.new
  mv debian/changelog.new debian/changelog
  debuild -b ${SIGN_OPTIONS}
  debuild -S -sa ${SIGN_OPTIONS}
  cd ..
}

function move_packages {
  mv igraph_* libigraph* python-igraph_* python-igraph-doc_* ${DEST_DIR}
}

function remove_build_dir {
  cd /
  rm -rf ${BUILD_DIR}
}

prechecks || exit 1

BUILD_DIR=`mktemp -d`
cd ${BUILD_DIR}
trap "{ cd /; rm -rf \"${BUILD_DIR}\"; exit 255; }" INT EXIT TERM

if [ `id -u` != 0 ]; then
  echo "Not running as root, skipping installation of build-deps."
  SUDO=sudo
else
  install_build_dependencies
  SUDO=
fi
make_destdir
git_pull
create_igraph_debian_pkg ${IGRAPH_VERSION} ${DEBIAN_REVISION}
install_igraph_debian_pkg ${IGRAPH_VERSION} ${DEBIAN_REVISION}
compile_python_interface ${IGRAPH_VERSION} ${DEBIAN_REVISION}
remove_igraph_debian_pkg
move_packages
remove_build_dir

echo ""
echo "Commands to upload packages to the Launchpad PPA:"
echo "dput ppa:igraph/ppa <source.changes>"
