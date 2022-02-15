#! /bin/sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export xray`

confs=`dbus list xray|cut -d "=" -f1`

for conf in $confs
do
	dbus remove $conf
done

sleep 1
rm -rf $KSROOT/scripts/xray*
rm -rf $KSROOT/init.d/S99xray.sh
rm -rf $KSROOT/xray
rm -rf $KSROOT/bin/xray
rm -rf $KSROOT/bin/smartdns
rm -rf $KSROOT/webs/Module_xray.asp
rm -rf $KSROOT/webs/res/icon-xray.png
rm -rf $KSROOT/webs/res/icon-xray-bg.png
rm -rf $KSROOT/scripts/uninstall_xray.sh

dbus remove softcenter_module_xray_home_url
dbus remove softcenter_module_xray_install
dbus remove softcenter_module_xray_md5
dbus remove softcenter_module_xray_version
dbus remove softcenter_module_xray_name
dbus remove softcenter_module_xray_description
