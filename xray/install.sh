#! /bin/sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export xray_`

mkdir -p $KSROOT/init.d
mkdir -p $KSROOT/xray
[ "$xray_basic_enable" == "1" ] && $KSROOT/scripts/xray_config.sh stop >/dev/null 2>&1

cp -rf /tmp/xray/bin/* $KSROOT/bin/
cp -rf /tmp/xray/init.d/* $KSROOT/init.d/
cp -rf /tmp/xray/xray/* $KSROOT/xray/
cp -rf /tmp/xray/scripts/* $KSROOT/scripts/
cp -rf /tmp/xray/webs/* $KSROOT/webs/
cp /tmp/xray/uninstall.sh $KSROOT/scripts/uninstall_xray.sh

chmod +x $KSROOT/scripts/xray_*
chmod +x $KSROOT/scripts/uninstall_xray.sh
chmod +x $KSROOT/bin/xray

if [ -n "$xray_basic_config" ]; then
	dbus set xray_server_tag_1="节点1"
	dbus set xray_server_config_1="$xray_basic_config"
	dbus set xray_basic_server=1
	dbus set xray_basic_type=1
	dbus set xray_server_node_max=1
	dbus set xray_sub_node_max=0
	dbus remove xray_basic_config
fi

[ -z "$xray_server_tag_1" ] && dbus set xray_server_node_max=0
[ -z "$xray_sub_tag_1" ] && dbus set xray_sub_node_max=0

dbus set softcenter_module_xray_description=模块化的代理软件包
dbus set softcenter_module_xray_install=4
dbus set softcenter_module_xray_name=xray
dbus set softcenter_module_xray_title="xRay"
dbus set softcenter_module_xray_version=1.5.3
dbus set xray_version=1.5.3

sleep 1
rm -rf $KSROOT/xray/gfw.txt
rm -rf $KSROOT/init.d/S98xray.sh
rm -rf /tmp/xray >/dev/null 2>&1

[ "$xray_basic_enable" == "1" ] && $KSROOT/scripts/xray_config.sh start >/dev/null 2>&1

exit 0
