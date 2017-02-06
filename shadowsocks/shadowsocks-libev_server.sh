#!/bin/bash
#=========================================================================
#   System Required:  Linux distribution with Systemd supported
#   Description:  Install Shadowsocks-libev Server
#   Author: Devin Zhong <devinzhong@outlook.com>
#   Intro:  https://github.com/DevinZhong/scripts/tree/master/shadowsocks
#=========================================================================

# 清屏
clear

# 确保是 root 来运行此脚本
if [[ $EUID -ne 0 ]]; then
    echo "this script must be run as root!" 1>&2
    exit 1
fi

# 提取发行版 ID
distributor_id=$(lsb_release -i) && distributor_id=${distributor_id:16}

# 生成并进入临时目录
TEMP_DIR="shadowsocks-libev-$RANDOM"
mkdir $TEMP_DIR && cd $TEMP_DIR

# 更新软件包，并安装确保 git，gcc，make
if [ $distributor_id = Debian -o $distributor_id = Ubuntu ]; then
  apt update
  apt upgrade -y
  apt install -y git gcc make
elif [ $distributor_id = CentOS -o $distributor_id = RedHatEnterpriseServer ]; then
  yum upgrade -y
  yum install -y git gcc make
elif [ $distributor_id = Fedora ]; then
  dnf upgrade -y
  dnf install -y git gcc make
elif [ $distributor_id = archlinux ]; then
  pacman -Syu
  pacman -S git gcc make
fi

# 编译安装最新的 mbedTLS 和 libsodium
export LIBSODIUM_VER=1.0.11
export MBEDTLS_VER=2.4.0
wget https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_VER.tar.gz
tar xvf libsodium-$LIBSODIUM_VER.tar.gz
pushd libsodium-$LIBSODIUM_VER
./configure --prefix=/usr && make
make install
popd
wget https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz
tar xvf mbedtls-$MBEDTLS_VER-gpl.tgz
pushd mbedtls-$MBEDTLS_VER
make SHARED=1 CFLAGS=-fPIC
make install
popd

# 安装 shadowsocks-libev
git clone https://github.com/shadowsocks/shadowsocks-libev.git &> /dev/null
cd shadowsocks-libev
git submodule update --init --recursive
if [ $distributor_id = Debian -o $distributor_id = Ubuntu ]; then
  apt install -y --no-install-recommends gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libudns-dev automake
elif [ $distributor_id = CentOS -o $distributor_id = RedHatEnterpriseServer ]; then
  yum install -y gettext gcc autoconf libtool automake make asciidoc xmlto udns-devel libev-devel
elif [ $distributor_id = Fedora ]; then
  dnf install -y gettext gcc autoconf libtool automake make asciidoc xmlto udns-devel libev-devel
elif [ $distributor_id = archlinux ]; then
  pacman -S gettext gcc autoconf libtool automake make asciidoc xmlto udns libev
fi
./autogen.sh && ./configure && make
make install
cd ..

# 销毁临时目录
cd ..
rm -rf $TEMP_DIR

# 编写 service 单元配置文件
if [ ! -d /usr/lib/systemd/system ]; then
  mkdir /usr/lib/systemd/system
fi
cat << "EOF" > /usr/lib/systemd/system/shadowsocks-libev.service
[Unit]
Description=Shadowsocks-libev Server Service
After=network.target

[Service]
Type=simple
User=root
LimitNOFILE=32768
ExecStart=/usr/local/bin/ss-server -c /etc/shadowsocks-libev/config.json -u --fast-open
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -QUIT $MAINPID
PrivateTmp=true
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target

EOF

# 获取 IP
shadowsocksip=$(curl ifconfig.co)

# 交互式配置 shadowsocks-libev
echo "please input password (way2hacker.com):"
read shadowsockspwd
[ -z "${shadowsockspwd}" ] && shadowsockspwd="way2hacker.com"
echo "please input port (8686):"
read shadowsocksport
[ -z "$shadowsocksport" ] && shadowsocksport="8686"
mkdir /etc/shadowsocks-libev
cat << EOF > /etc/shadowsocks-libev/config.json
{
  "server":"${shadowsocksip}",
  "server_port":${shadowsocksport},
  "local_port":1080,
  "password":"${shadowsockspwd}",
  "timeout":60,
  "method":"chacha20"
}
EOF

# 开启服务器 TCP Fast Open 支持
echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
sysctl -p > /dev/null

# 启动服务
systemctl enable shadowsocks-libev.service
systemctl start shadowsocks-libev.service

# 搭建完成
cat << EOF
Complete!

please configure you shadowsocks client as below:
------------------------------------------------
server:"${shadowsocksip}"
server_port:${shadowsocksport}
password:"${shadowsockspwd}"
method:"chacha20"
fast_open:true
------------------------------------------------
EOF

# 脚本结束
exit 0