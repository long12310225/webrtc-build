#!/bin/bash

cd `dirname $0`
source VERSION
SCRIPT_DIR="`pwd`"

PACKAGE_NAME=android
SOURCE_DIR="`pwd`/_source/$PACKAGE_NAME"
BUILD_DIR="`pwd`/_build/$PACKAGE_NAME"
PACKAGE_DIR="`pwd`/_package/$PACKAGE_NAME"

set -ex

_name=WebrtcBuildVersion
_branch="M`echo $WEBRTC_VERSION | cut -d'.' -f1`"
_commit="`echo $WEBRTC_VERSION | cut -d'.' -f3`"
_revision=$WEBRTC_COMMIT
_maint="`echo $WEBRTC_BUILD_VERSION | cut -d'.' -f4`"
./scripts/generate_version_android.sh "$_name" "$_branch" "$_commit" "$_revision" "$_maint" > android/$_name.java
cat android/$_name.java

# 更新系统
apt update && apt -y install ca-certificates
if [ ! -f "/etc/apt/sources.list_bak" ]; then
    mv /etc/apt/sources.list /etc/apt/sources.list_bak
fi
cat /dev/null > /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb https://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse" >> /etc/apt/sources.list
echo "deb-src https://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse" >> /etc/apt/sources.list
apt-get update
apt-get -y upgrade
apt-get -y install tzdata
echo 'Asia/Shanghai' > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
echo 'db_get () { if [ "$@" = "snapcraft/snap-no-connectivity" ]; then RET="Skip"; else _db_cmd "GET $@"; fi }' >> /usr/share/debconf/confmodule
apt-get install -y snapcraft \
  git \
  libsdl2-dev \
  lsb-release \
  python \
  rsync \
  sudo \
  vim \
  wget \
  openjdk-11-jdk

mkdir -p $SOURCE_DIR
export http_proxy=10.2.110.233:26001
export https_proxy=10.2.110.233:26001
git config --global http.sslVerify false
pushd $SOURCE_DIR
    if [ ! -d "$SOURCE_DIR/depot_tools" ]; then
        # 如果不存在，克隆仓库并切换到4147分支
        git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git depot_tools
        cd "$SOURCE_DIR/depot_tools"
        git checkout -b 4147 remotes/origin/chrome/4147
    fi
popd
export PATH=$SOURCE_DIR/depot_tools:$PATH
mkdir -p $SOURCE_DIR/webrtc
export DEPOT_TOOLS_UPDATE=0
cat /dev/null > $SOURCE_DIR/webrtc/.boto
echo "[Boto]" >> $SOURCE_DIR/webrtc/.boto
echo "proxy = 10.2.110.233" >> $SOURCE_DIR/webrtc/.boto
echo "proxy_port = 26001" >> $SOURCE_DIR/webrtc/.boto
export NO_AUTH_BOTO_CONFIG=$SOURCE_DIR/webrtc/.boto
pushd $SOURCE_DIR/webrtc
  if [ ! -d "src" ]; then
    fetch --nohooks webrtc_android
    cd src
    git checkout -b m94/4606 branch-heads/4606
    cd ..
    gclient sync -D
  else
    gclient sync -D
  fi
popd
# pushd $SOURCE_DIR/webrtc
#   gclient
#   if [ ! -e src ]; then
#     fetch webrtc
#   fi
# popd
# pushd $SOURCE_DIR/webrtc/src
#   git reset --hard
#   git clean -xdf
#   pushd third_party
#     git reset --hard
#     git clean -xdf
#   popd
#   git fetch
#   git checkout -f $WEBRTC_COMMIT
#   gclient sync
# popd