#!/bin/bash
#=========================================================================
#   System Required:  CentOS 7
#   Description:  Install TShock
#   Author: Devin Zhong <devinzhong@outlook.com>
#   Intro:  https://github.com/DevinZhong/scripts/tree/master/tshock
#=========================================================================

# 清屏
clear

# 确保是 root 来运行此脚本
if [[ $EUID -ne 0 ]]; then
    echo "this script must be run as root!" 1>&2
    exit 1
fi

echo "#### upgrade packages..."
yum upgrade -y

echo "#### install mono..."
yum install -y yum-utils
rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
yum-config-manager --add-repo http://download.mono-project.com/repo/centos7/
yum install -y mono-devel mono-complete

echo "#### download tshock..."
wget -O tshock.zip 'https://github.com/Pryaxis/TShock/releases/download/v4.3.25/tshock_4.3.25.zip'

echo "#### unzip tshock..."
unzip tshock.zip -d ~/tshock

echo "#### install tmux..."
yum install -y tmux

# 搭建完成
cat << EOF
#### Complete!

You can run the TShock in tmux session.
Here is usages for tmux:
------------------------------------------------
# start a session
tmux new -s <session_name>

# detach current session (Ctrl + B + D)
:detach

# list session
tmux list-sessions

# back to last session
tmux attach

# turn to target session
tmux attach -t <session_name>

# kill session
tmux kill-session -t <session_name>
------------------------------------------------
EOF

# 脚本结束
exit 0
