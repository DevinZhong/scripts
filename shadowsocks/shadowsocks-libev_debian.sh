#!/bin/bash
#==================================================================
#   System Required:  Debian 8 (32bit/64bit)
#   Description:  Install Shadowsocks-libev for Debian 8
#   Author: Devin Zhong <devinzhong@outlook.com>
#   Intro:  https://github.com/DevinZhong/scripts/tree/master/shadowsocks
#==================================================================

# 清屏与打印脚本说明
clear
cat << EOF
#############################################################
# Install Shadowsocks-libev for Debian 8 (32bit/64bit)
# Intro:  https://github.com/DevinZhong/scripts/tree/master/shadowsocks
#
# Author: Devin Zhong <devinzhong@outlook.com>
#############################################################

EOF

# 确保是 root 来运行此脚本
if [[ $EUID -ne 0 ]]; then
    echo "this script must be run as root!" 1>&2
    exit 1
fi

# 确保系统为 Debian 发行版
if [ ! -f /etc/debian_version ]; then
    echo "distribution is not supported!" 1>&2
    exit 1
fi

# 更新包列表
echo 'update packages list...'
apt-get update > /dev/null

# 安装 git
echo 'install git...'
apt-get -y install git > /dev/null

# 安装 shadowsocks-libev
echo 'install shadowsocks-libev...'
TEMP_DIR="shadowsocks-libev-$RANDOM"
mkdir $TEMP_DIR && cd $TEMP_DIR
git clone https://github.com/shadowsocks/shadowsocks-libev.git &> /dev/null
cd shadowsocks-libev
apt-get -y install --no-install-recommends gettext build-essential autoconf libtool \
    gawk debhelper dh-systemd init-system-helpers pkg-config asciidoc xmlto apg libpcre3-dev libmbedtls-dev \
    libev-dev libudns-dev libsodium-dev &> /dev/null
./autogen.sh && dpkg-buildpackage -b -us -uc -i &> /dev/null
cd ..
dpkg -i shadowsocks-libev*.deb &> /dev/null
cd ..
rm -rf $TEMP_DIR

# 配置 shadowsocks-libev
echo 'configure shadowsocks-libev...'
# 启用 UDP 转发、一次性认证、TCP 快速启动
sed -i 's/\(DAEMON_ARGS\).*$/\1="-u -A --fast-open"/' /etc/default/shadowsocks-libev

# 配置 config.json
echo "please input password (way2hacker.com):"
read shadowsockspwd
[ -z "${shadowsockspwd}" ] && shadowsockspwd="way2hacker.com"

echo "please input port (8686):"
read shadowsocksport
[ -z "$shadowsocksport" ] && shadowsocksport="8686"

cat << EOF > /etc/shadowsocks-libev/config.json
{
    "server":"0.0.0.0",
    "server_port":${shadowsocksport},
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "timeout":60,
    "method":"chacha20"
}
EOF

# 开启服务器 TCP Fast Open 支持
echo 'enable TCP Fast Open on server...'
echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
sysctl -p > /dev/null

# 重启服务
echo 'restart shadowsocks-libev...'
sudo systemctl daemon-reload
sudo systemctl restart shadowsocks-libev.service

# 搭建完成
echo 'Complete!'
cat << EOF

please configure you shadowsocks client as below:
----------------------------------------
server:"$(curl ifconfig.co 2>/dev/null)"
server_port:${shadowsocksport}
password:"${shadowsockspwd}"
method:"chacha20"
auth:true
fast_open:true
----------------------------------------
- remember to add the '-u' argument to the ss-local to enable the udprelay mode.
- your system must support TCP fast open if you want to enjoy this feature.

EOF
echo 'reboot your server to get more free memory!'

exit 0