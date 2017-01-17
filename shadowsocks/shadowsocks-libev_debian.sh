#!/bin/bash

# 确保是 root 来运行此脚本
if [[ $EUID -ne 0 ]]; then
    echo "this script must be run as root!" 1>&2
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
git clone https://github.com/shadowsocks/shadowsocks-libev.git &> /dev/null
cd shadowsocks-libev
apt-get -y install --no-install-recommends build-essential autoconf libtool libssl-dev \
    gawk debhelper dh-systemd init-system-helpers pkg-config asciidoc xmlto apg libpcre3-dev zlib1g-dev &> /dev/null
dpkg-buildpackage -b -us -uc -i &> /dev/null
cd ..
dpkg -i shadowsocks-libev*.deb &> /dev/null
rm -rf shadowsocks-libev*

# 配置 shadowsocks-libev
echo 'configure shadowsocks-libev...'
sed -i 's/\(DAEMON_ARGS\).*$/\1="-u -A --fast-open"/' /etc/default/shadowsocks-libev

# 配置 config.json
read -p "please input password for shadowsocks-libev (way2hacker.com):" shadowsockspwd
[ -z "${shadowsockspwd}" ] && shadowsockspwd="way2hacker.com"

read -p "please input port for shadowsocks-libev (8686):" shadowsocksport
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
server:"$(curl ifconfig.io 2>/dev/null)"
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