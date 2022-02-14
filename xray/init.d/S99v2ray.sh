#!/bin/sh /etc/rc.common
#
# Copyright (C) 2015 OpenWrt-dist
# Copyright (C) 2016 fw867 <ffkykzs@gmail.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

START=99
STOP=15

source /koolshare/scripts/base.sh
eval `dbus export v2ray_`


start(){
	[ "$v2ray_basic_enable" == "1" ] && /koolshare/scripts/xray_config.sh start > /tmp/upload/xray_log.txt
}

stop(){
	/koolshare/scritps/xray_config.sh stop
}
