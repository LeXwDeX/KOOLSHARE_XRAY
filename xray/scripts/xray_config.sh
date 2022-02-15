#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
source $KSROOT/bin/helper.sh
eval `dbus export xray_`
alias echo_date='echo 【$(date +%Y年%m月%d日\ %X)】:'
lan_ipaddr=`uci get network.lan.ipaddr`
LOCK_FILE=/var/lock/xray.lock
LOG_FILE=/tmp/upload/xray_log.txt
ISP_DNS1=`cat /tmp/resolv.conf.d/resolv.conf.auto|cut -d " " -f 2|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 2p`
ISP_DNS2=`cat /tmp/resolv.conf.d/resolv.conf.auto|cut -d " " -f 2|grep -v 0.0.0.0|grep -v 127.0.0.1|sed -n 3p`
KP_ENABLE=`dbus get koolproxy_enable`
XRAY_CONFIG_FILE_TMP="/tmp/xray_tmp.json"
XRAY_CONFIG_FILE="/koolshare/xray/xray.json"
set_lock(){
	exec 1000>"$LOCK_FILE"
	flock -x 1000
}
unset_lock(){
	flock -u 1000
	rm -rf "$LOCK_FILE"
}
get_lan_cidr(){
	netmask=`uci get network.lan.netmask`
	local x=${netmask##*255.}
	set -- 0^^^128^192^224^240^248^252^254^ $(( (${#netmask} - ${#x})*2 )) ${x%%.*}
	x=${1%%$3*}
	suffix=$(( $2 + (${#x}/4) ))
	prefix=`uci get network.lan.ipaddr | cut -d "." -f1,2,3`
	echo $prefix.0/$suffix
}
create_dnsmasq_conf(){
	local CDN IFIP_DNS wanwhitedomain wanblackdomain IFIP_DNS1 IFIP_DNS2
	IFIP_DNS=`echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
	[ -n "$IFIP_DNS" ] && CDN="$ISP_DNS1" || CDN="114.114.114.114"
	[ "$xray_dns_china" == "2" ] && CDN="223.5.5.5"
	[ "$xray_dns_china" == "3" ] && CDN="223.6.6.6"
	[ "$xray_dns_china" == "4" ] && CDN="114.114.114.114"
	[ "$xray_dns_china" == "5" ] && CDN="114.114.115.115"
	[ "$xray_dns_china" == "6" ] && CDN="1.2.4.8"
	[ "$xray_dns_china" == "7" ] && CDN="210.2.4.8"
	[ "$xray_dns_china" == "8" ] && CDN="112.124.47.27"
	[ "$xray_dns_china" == "9" ] && CDN="114.215.126.16"
	[ "$xray_dns_china" == "10" ] && CDN="180.76.76.76"
	[ "$xray_dns_china" == "11" ] && CDN="119.29.29.29"
	[ "$xray_dns_china" == "12" ] && CDN="$xray_dns_china_user"
	# append china site
	[ ! -f /tmp/dnsmasq.d/xraycdn.conf -a "$xray_dns_plan" == "2" ] && {
		echo_date 创建国内CDN解析优化配置文件
		cat $KSROOT/xray/cdn.txt | sed "s/^/server=&\/./g" | sed "s/$/\/&$CDN/g" | sort | awk '{if ($0!=line) print;line=$0}' > /tmp/dnsmasq.d/xraycdn.conf
	}
	[ ! -f /tmp/dnsmasq.d/xraygfw.conf -a "$xray_dns_plan" == "1" -o "$xray_acl_default_mode" == "1" ] && {
		echo_date 创建国外GFW解析优化配置文件
		#cat $KSROOT/xray/gfwlist.conf | awk '{print "server=/"$1"/127.0.0.1#7913\nipset=/"$1"/black_list"}' >> /tmp/dnsmasq.d/xraygfw.conf
		ln -sf $KSROOT/xray/gfwlist.conf /tmp/dnsmasq.d/xraygfw.conf
	}
	if [ -n "$xray_dnsmasq" ];then
		echo_date 添加自定义dnsmasq设置到/tmp/dnsmasq.d/xraycustom.conf
		echo "$xray_dnsmasq" | base64_decode | sort -u >> /tmp/dnsmasq.d/xraycustom.conf
	fi
	[ ! -f "/tmp/dnsmasq.d/xrayroute.conf" ] && {
		echo_date 创建状态检测解析优化配置文件
		cat > /tmp/dnsmasq.d/xrayroute.conf <<-EOF
			#for router itself
			server=/.google.com.hk/127.0.0.1#7913
			ipset=/.google.com.hk/router
			server=/.google.com.ncr/127.0.0.1#7913
			ipset=/.google.com.ncr/router
			server=/.github.com/127.0.0.1#7913
			ipset=/.github.com/router
			server=/.github.io/127.0.0.1#7913
			ipset=/.github.io/router
			server=/.raw.githubusercontent.com/127.0.0.1#7913
			ipset=/.raw.githubusercontent.com/router
			server=/.apnic.net/127.0.0.1#7913
			ipset=/.apnic.net/router
			server=/.s3.amazonaws.com/127.0.0.1#7913
			ipset=/.s3.amazonaws.com/router
			server=/.openwrt.org/127.0.0.1#7913
			ipset=/.openwrt.org/router
		EOF
	}
	# append white domain list,not through ss
	wanwhitedomain=$(echo $xray_wan_white_domain | base64_decode)
	if [ -n "$xray_wan_white_domain" ];then
		echo_date 应用域名白名单
		echo "#for white_domain" >> /tmp/dnsmasq.d/xraywblist.conf
		for wan_white_domain in $wanwhitedomain
		do 
			echo "$wan_white_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN/g" >> /tmp/dnsmasq.d/xraywblist.conf
			echo "$wan_white_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >> /tmp/dnsmasq.d/xraywblist.conf
		done
	fi
	# apple 和microsoft不能走代理
	echo "#for special site" >> /tmp/dnsmasq.d/xraywblist.conf
	for wan_white_domain2 in "apple.com" "microsoft.com"
	do 
		echo "$wan_white_domain2" | sed "s/^/server=&\/./g" | sed "s/$/\/$CDN/g" >> /tmp/dnsmasq.d/xraywblist.conf
		echo "$wan_white_domain2" | sed "s/^/ipset=&\/./g" | sed "s/$/\/white_list/g" >> /tmp/dnsmasq.d/xraywblist.conf
	done
	
	# append black domain list,through ss
	wanblackdomain=$(echo $xray_wan_black_domain | base64_decode)
	if [ -n "$xray_wan_black_domain" ];then
		echo_date 应用域名黑名单
		echo "#for black_domain" >> /tmp/dnsmasq.d/xraywblist.conf
		for wan_black_domain in $wanblackdomain
		do 
			echo "$wan_black_domain" | sed "s/^/server=&\/./g" | sed "s/$/\/127.0.0.1#7913/g" >> /tmp/dnsmasq.d/xraywblist.conf
			echo "$wan_black_domain" | sed "s/^/ipset=&\/./g" | sed "s/$/\/black_list/g" >> /tmp/dnsmasq.d/xraywblist.conf
		done
	fi
	
	if [ "$xray_dns_china" == "1" ];then
		IFIP_DNS1=`echo $ISP_DNS1|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
		IFIP_DNS2=`echo $ISP_DNS2|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
		[ -n "$IFIP_DNS1" ] && CDN1="$ISP_DNS1" || CDN1="114.114.114.114"
		[ -n "$IFIP_DNS2" ] && CDN2="$ISP_DNS2" || CDN2="114.114.115.115"
	fi
	
	echo "no-resolv" >> /tmp/dnsmasq.d/xray.conf
	if [ "$xray_dns_plan" == "1" ] || [ -z "$xray_dns_china" ];then
		if [ "$xray_dns_china" == "1" ];then
			echo_date DNS解析方案国内优先，使用运营商DNS优先解析国内DNS.
			echo "all-servers" >> /tmp/dnsmasq.d/xray.conf
			echo "server=$CDN1" >> /tmp/dnsmasq.d/xray.conf
			echo "server=$CDN2" >> /tmp/dnsmasq.d/xray.conf
		else
			echo_date DNS解析方案国内优先，使用自定义DNS：$CDN进行解析国内DNS.
			echo "server=$CDN" >> /tmp/dnsmasq.d/xray.conf
		fi
	elif [ "$xray_dns_plan" == "2" ];then
		echo_date DNS解析方案国外优先，优先解析国外DNS.
		echo "server=127.0.0.1#7913" >> /tmp/dnsmasq.d/xray.conf
	fi
}
restore_dnsmasq_conf(){
	if [ -n "`ls /tmp/dnsmasq.d/xray*.conf 2>/dev/null`" ];then
		echo_date 删除 xray 相关的名单配置文件.
		rm -rf /tmp/dnsmasq.d/xray*.conf
	fi
}
restore_start_file(){
	echo_date 清除firewall中相关的 xray 启动命令...
	uci -q batch <<-EOT
		delete firewall.ks_xray
		commit firewall
	EOT
}
kill_process(){
	if [ -n "`pidof xray`" ]; then 
		echo_date 关闭 xray 进程...
		killall xray >/dev/null 2>&1
	fi
}
auto_start(){
	# nat start
	echo_date 添加nat-start触发事件...
	uci -q batch <<-EOT
		delete firewall.ks_xray
		set firewall.ks_xray=include
		set firewall.ks_xray.type=script
		set firewall.ks_xray.path=/koolshare/scripts/xray_nat.sh
		set firewall.ks_xray.family=any
		set firewall.ks_xray.reload=1
		commit firewall
	EOT
	# auto start
	[ ! -L "/etc/rc.d/S99xray.sh" ] && ln -sf $KSROOT/init.d/S99xray.sh /etc/rc.d/S99xray.sh
}
get_function_switch() {
	case "$1" in
		0)
			echo "false"
		;;
		1)
			echo "true"
		;;
	esac
}
get_auth_status() {
	case "$1" in
		1)
			echo "noauth"
		;;
		2)
			echo "password"
		;;
	esac
}
close_in_five(){
	echo_date "插件将在5秒后自动关闭！！"
	sleep 1
	echo_date 5
	sleep 1
	echo_date 4
	sleep 1
	echo_date 3
	sleep 1
	echo_date 2
	sleep 1
	echo_date 1
	sleep 1
	echo_date 0
	dbus set xray_basic_enable="0"
	stop_xray >/dev/null
	echo_date "某些老版本固件已经无法使用新版插件，请升级到最新版固件使用！"
	echo_date "插件已关闭！！"
	echo_date ------------------------- xray 成功关闭 -------------------------
	echo XU6J03M6
	http_response "233"
	unset_lock
	exit
}
get_dns_user(){
	if [ -n "$xray_dns_foreign_user" ];then
		if [ -n "`echo $xray_dns_foreign_user|grep :`" ];then
			echo $xray_dns_foreign_user | cut -d ":" -f1
		else
			echo $xray_dns_foreign_user
		fi
	else
		echo "8.8.8.8"
	fi
}
get_dns_port(){
	if [ "$xray_dns_foreign" == "4" ];then
		if [ -n "$xray_dns_foreign_user" ];then
			if [ -n "`echo $xray_dns_foreign_user|grep :`" ];then
				echo $xray_dns_foreign_user | cut -d ":" -f2
			else
				echo "53"
			fi
		else
			echo "53"
		fi
	else
		echo "53"
	fi
}
gen_xray_config(){
	local KDF server_tag server_config JSON_INFO TEMPLATE result resultstatus TEMSOCKS TEMHTTP TEMSS TEMAUTH
	[ "$xray_dns_foreign" == "1" ] && KDF="208.67.220.220"
	[ "$xray_dns_foreign" == "2" ] && KDF="8.8.8.8"
	[ "$xray_dns_foreign" == "3" ] && KDF="8.8.4.4"
	[ "$xray_dns_foreign" == "4" ] && KDF="$(get_dns_user)"
	rm -rf "$XRAY_CONFIG_FILE_TMP"
	rm -rf "$XRAY_CONFIG_FILE"
	if [ "$xray_basic_type" == "1" ]; then
		server_tag=$(dbus get "xray_server_tag_$xray_basic_server")
		server_config=$(dbus get "xray_server_config_$xray_basic_server")
	else
		server_tag=$(dbus get "xray_sub_tag_$xray_basic_server")
		server_config=$(dbus get "xray_sub_config_$xray_basic_server")
	fi
	echo_date 使用 $server_tag 配置文件...
	
	echo $server_config | base64_decode > "$XRAY_CONFIG_FILE_TMP"
	if [ "$xray_basic_sbmode" == "1" ]; then
		JSON_INFO=`cat "$XRAY_CONFIG_FILE_TMP" | jq 'del (.inbound) | del (.inbounds) | del (.inboundDetour) | del (.log)'`
	else
		JSON_INFO=`cat "$XRAY_CONFIG_FILE_TMP" | jq 'del (.inbound) | del (.inbounds) | del (.inboundDetour) | del (.log) | del (.routing)'`
	fi
	#OUTBOUND=`cat "$XRAY_CONFIG_FILE_TMP" | jq .outbound`	
	#INBOUND_TAG=`cat "$XRAY_CONFIG_FILE_TMP" | jq '.inbound.tag'
	#INBOUND_DETOUR_TAG=`cat "$XRAY_CONFIG_FILE_TMP" | jq '.inbound.tag'
	if [ "$xray_service_auth" == "2" ]; then
		TEMAUTH="{
					\"user\": \"$xray_service_username\",
					\"pass\": \"$xray_service_passwd\"
				}"
	else
		TEMAUTH=""
	fi
	if [ "$xray_basic_socks" == "1" ]; then
		echo_date 开启允许本地局域网或者远程用户连接的socks5代理服务器，端口1281
		TEMSOCKS="{
				  \"tag\": \"socks5\",
				  \"protocol\": \"socks\",
				  \"port\": 1281,
				  \"settings\": {
					  \"auth\": \"$(get_auth_status $xray_service_auth)\",
					  \"accounts\": [
						$TEMAUTH					  
					  ],
					  \"userLevel\": 0,
					  \"ip\": \"0.0.0.0\",
					  \"udp\": true
					},
				  \"sniffing\": {
					\"enabled\": $(get_function_switch $xray_basic_sniffing),
					\"destOverride\": [
					  \"http\",
					  \"tls\"
					]
				  }
				},"
	else
		TEMSOCKS=""
	fi
	if [ "$xray_basic_http" == "1" ]; then
		echo_date 开启允许本地局域网或者远程用户连接的http代理服务器，端口1282
		TEMHTTP="{
				  \"tag\": \"http\",
				  \"protocol\": \"http\",
				  \"port\": 1282,
				  \"settings\": {
					  \"accounts\": [
						$TEMAUTH
					  ],
					  \"timeout\": 0,
					  \"userLevel\": 0,
					  \"allowTransparent\": false
				  },
				  \"sniffing\": {
					\"enabled\": $(get_function_switch $xray_basic_sniffing),
					\"destOverride\": [
					  \"http\",
					  \"tls\"
					]
				  }
				},"
	else
		TEMHTTP=""
	fi
	if [ "$xray_basic_ss" == "1" ]; then
		echo_date 开启允许本地局域网或者远程用户连接的shadowsocks代理服务器，端口1283
		TEMSS="{
				  \"tag\": \"shadowsocks\",
				  \"protocol\": \"shadowsocks\",
				  \"port\": 1283,
				  \"settings\": {
					\"method\": \"$xray_service_ssmethod\",
					\"password\": \"$xray_service_sspasswd\",
					\"udp\": true,
					\"level\": 0,
					\"ota\": false
				  }
				},"
	else
		TEMSS=""
	fi
	local TEMPLATE="{
					\"log\":{
						\"access\":\"/dev/null\",
						\"error\":\"/tmp/xray_log.log\",
						\"loglevel\":\"error\"
					},
					  \"inbounds\": [
						{
						  \"tag\": \"tproxy\",
						  \"protocol\": \"dokodemo-door\",
						  \"listen\": \"0.0.0.0\",
						  \"port\": 1280,
						  \"settings\": {
							\"network\": \"tcp,udp\",
							\"followRedirect\": true
						  },
						  \"sniffing\": {
							\"enabled\": $(get_function_switch $xray_basic_sniffing),
							\"destOverride\": [
							  \"http\",
							  \"tls\"
							]
						  }
						},$TEMHTTP$TEMSOCKS$TEMSS
						{
						  \"tag\": \"dns\",
						  \"protocol\": \"dokodemo-door\",
						  \"port\": 7913,
						  \"settings\": {
							\"address\": \"$KDF\",
							\"port\": $(get_dns_port),
							\"network\": \"udp\",
							\"timeout\": 0,
							\"followRedirect\": false
						  }
						}
					]
					}"
	echo_date 解析xray配置文件...
	#echo $TEMPLATE | jq --argjson args "$OUTBOUND" '. + {outbound: $args}' > "$XRAY_CONFIG_FILE"
	echo $TEMPLATE | jq --argjson args "$JSON_INFO" '. + $args' > "$XRAY_CONFIG_FILE"
	
	echo_date xray配置文件写入成功到"$XRAY_CONFIG_FILE"
	# 检测用户json的服务器ip地址
	xray_protocal=`cat "$XRAY_CONFIG_FILE" | jq -r .outbound.protocol`
	[ -z "$xray_protocal" -o "$xray_protocal" == "null" ] && xray_protocal=`cat "$XRAY_CONFIG_FILE" | jq -r .outbounds[0].protocol`
	case $xray_protocal in
	vmess)
		xray_server=`cat "$XRAY_CONFIG_FILE" | jq -r .outbound.settings.vnext[0].address`
		;;
	socks)
		xray_server=`cat "$XRAY_CONFIG_FILE" | jq -r .outbound.settings.servers[0].address`
		;;
	shadowsocks)
		xray_server=`cat "$XRAY_CONFIG_FILE" | jq -r .outbound.settings.servers[0].address`
		;;
	*)
		xray_server=""
		;;
	esac
	[ -z "$xray_server" -o "$xray_server" == "null" ] && {
		case $xray_protocal in
		vmess)
			xray_server=`cat "$XRAY_CONFIG_FILE" | jq -r .outbounds[0].settings.vnext[0].address`
			;;
		socks)
			xray_server=`cat "$XRAY_CONFIG_FILE" | jq -r .outbounds[0].settings.servers[0].address`
			;;
		shadowsocks)
			xray_server=`cat "$XRAY_CONFIG_FILE" | jq -r .outbounds[0].settings.servers[0].address`
			;;
		*)
			xray_server=""
			;;
		esac
	}
	if [ -n "$xray_server" -a "$xray_server" != "null" ];then
		IFIP_VS=`echo $xray_server|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
		if [ -n "$IFIP_VS" ];then
			xray_basic_server_ip="$xray_server"
			echo_date "检测到你的json配置的xray服务器是：$xray_server"
		else
			echo_date "检测到你的json配置的xray服务器：$xray_server不是ip格式！"
			echo_date "尝试解析xray服务器的ip地址..."
			# 服务器地址强制由114解析，以免插件还未开始工作而导致解析失败
			echo "server=/$xray_server/114.114.114.114" > /tmp/dnsmasq.d/xray_server.conf
			xray_server_ip=`nslookup "$xray_server" 114.114.114.114 | sed '1,4d' | awk '{print $3}' | grep -v :|awk 'NR==1{print}'`
			if [ "$?" == "0" ]; then
				xray_server_ip=`echo $xray_server_ip|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
			else
				echo_date xray服务器域名解析失败！
				echo_date 尝试用resolveip方式解析...
				xray_server_ip=`resolveip -4 -t 2 $xray_server|awk 'NR==1{print}'`
				if [ "$?" == "0" ];then
					xray_server_ip=`echo $xray_server_ip|grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}|:"`
				fi
			fi
			if [ -n "$xray_server_ip" ];then
				echo_date "xray服务器的ip地址解析成功：$xray_server_ip"
				#echo "address=/$xray_server/$xray_server_ip" > /tmp/dnsmasq.d/xray_host.conf
				xray_basic_server_ip="$xray_server_ip"
			else
				echo_date "xray服务器的ip地址解析失败!插件将继续运行，域名解析将由xray自己进行！"
				echo_date "请自行将xray服务器的ip地址填入IP/CIDR白名单中!"
				echo_date "为了确保xray的正常工作，建议配置ip格式的xray服务器地址！"
			fi
		fi
	else
		echo_date "没有检测到你的xray服务器地址，如果你确定你的配置是正确的"
		echo_date "请自行将xray服务器的ip地址填入【IP/CIDR】黑名单中，以确保正常使用"
	fi
	echo_date 测试xray配置文件.....
	cd /koolshare/bin
	result=$(xray -test -config="$XRAY_CONFIG_FILE_TMP" | grep "Configuration OK.")
	if [ -n "$result" ];then
		echo_date $result
		if [ -s "$XRAY_CONFIG_FILE" ];then
			echo_date xray配置文件通过测试!!!
		else
			echo_date xray配置文件通过测试，但固件版本过低，无法正确解析配置文件，请升级到最新固件！
			close_in_five
		fi
	else
		#rm -rf "$XRAY_CONFIG_FILE_TMP"
		#rm -rf "$XRAY_CONFIG_FILE"
		echo_date xray配置文件没有通过测试，请检查设置!!!
		resultstatus=$(xray -test -config="$XRAY_CONFIG_FILE_TMP" | tail -n +3)
		echo_date 出错原因：$resultstatus
		close_in_five
	fi
}
start_xray(){
	optimized_network
	gen_xray_config
	echo_date 开启 xray 主进程...
	cd /koolshare/bin
	xray --config=/koolshare/xray/xray.json >/dev/null 2>&1 &
	
	local i=10
	until [ -n "$V2PID" ]
	do
		i=$(($i-1))
		V2PID=`pidof xray`
		if [ "$i" -lt 1 ];then
			echo_date "xray进程启动失败！"
			close_in_five
		fi
		sleep 1
	done
	echo_date xray启动成功，pid：$V2PID
}
# =======================================================================================================
flush_nat(){
	local ip_nat_exist ip_mangle_exist chromecast_nu ip_rule_exist service_exist
	echo_date 尝试先清除已存在的iptables规则，防止重复添加
	# flush rules and set if any
	ip_nat_exist=`iptables -t nat -L PREROUTING | grep -c XRAY`
	ip_mangle_exist=`iptables -t mangle -L PREROUTING | grep -c XRAY`
	if [ "$ip_nat_exist" -ne 0 ]; then
		for i in `seq $ip_nat_exist`
		do
			iptables -t nat -D OUTPUT -j XRAY > /dev/null 2>&1
			iptables -t nat -D OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 1280 > /dev/null 2>&1
			iptables -t nat -D PREROUTING -p tcp -j XRAY > /dev/null 2>&1
			echo_date 清除NAT规则
		done
	fi
	if [ "$ip_mangle_exist" -ne 0 ]; then
		for i in `seq $ip_mangle_exist`
		do
			iptables -t mangle -D PREROUTING -j XRAY > /dev/null 2>&1
			echo_date 清除Mangle规则
		done
	fi
	sleep 1
	chromecast_nu=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "dpt:53"|awk '{print $1}'|head -1`
	[ "$KP_ENABLE" == "1" ] || iptables -t nat -D PREROUTING $chromecast_nu > /dev/null 2>&1
	iptables -t nat -F XRAY > /dev/null 2>&1 && iptables -t nat -X XRAY > /dev/null 2>&1
	iptables -t mangle -F XRAY > /dev/null 2>&1 && iptables -t mangle -X XRAY > /dev/null 2>&1
	iptables -t mangle -F XRAY_GFW > /dev/null 2>&1 && iptables -t mangle -X XRAY_GFW > /dev/null 2>&1
	iptables -t mangle -F XRAY_CHN > /dev/null 2>&1 && iptables -t mangle -X XRAY_CHN > /dev/null 2>&1
	iptables -t mangle -F XRAY_GAM > /dev/null 2>&1 && iptables -t mangle -X XRAY_GAM> /dev/null 2>&1
	iptables -t mangle -F XRAY_GLO > /dev/null 2>&1 && iptables -t mangle -X XRAY_GLO > /dev/null 2>&1
	
	service_exist=`iptables -L zone_wan_input | grep -c "softcenter:xray"`
	if [ ! -z "$service_exist" ];then
		until [ "$service_exist" = 0 ]
	do
		relay_nu=`iptables -L zone_wan_input -v -n --line-numbers|grep "softcenter:xray"|awk '{print $1}'|head -1`
		iptables -D zone_wan_input $relay_nu >/dev/null 2>&1
		service_exist=`expr $service_exist - 1`
	done
	fi

	#flush_ipset
	echo_date 先清空已存在的ipset名单，防止重复添加
	ipset -F chnroute >/dev/null 2>&1 && ipset -X chnroute >/dev/null 2>&1
	ipset -F white_list >/dev/null 2>&1 && ipset -X white_list >/dev/null 2>&1
	ipset -F black_list >/dev/null 2>&1 && ipset -X black_list >/dev/null 2>&1
	ipset -F gfwlist >/dev/null 2>&1 && ipset -X gfwlist >/dev/null 2>&1
	ipset -F router >/dev/null 2>&1 && ipset -X router >/dev/null 2>&1
	#remove_redundant_rule
	ip_rule_exist=`ip rule show | grep "fwmark 0x1/0x1 lookup 310" | grep -c 310`
	if [ ! -z "ip_rule_exist" ];then
		echo_date 清除重复的ip rule规则.
		until [ "$ip_rule_exist" = "0" ]
		do 
			#ip rule del fwmark 0x07 table 310
			ip rule del fwmark 0x07 table 310 pref 789
			ip_rule_exist=`expr $ip_rule_exist - 1`
		done
	fi
	# remove_route_table
	echo_date 删除ip route规则.
	ip route del local 0.0.0.0/0 dev lo table 310 >/dev/null 2>&1
}
# creat ipset rules
creat_ipset(){
	echo_date 创建ipset名单
	ipset -! create white_list nethash && ipset flush white_list
	ipset -! create black_list nethash && ipset flush black_list
	ipset -! create gfwlist nethash && ipset flush gfwlist
	ipset -! create router nethash && ipset flush router
	ipset -! create chnroute nethash && ipset flush chnroute
	sed -e "s/^/add chnroute &/g" $KSROOT/xray/chnroute.txt | awk '{print $0} END{print "COMMIT"}' | ipset -R
}
add_white_black_ip(){
	# black ip/cidr
	local ip_tg
	ip_tg="67.198.55.0/24 91.108.4.0/22 91.108.12.0/22 91.108.56.0/22 91.108.8.0/22 93.119.240.0/20 109.239.140.0/24 149.154.0.0/16 149.154.160.0/20"
	for ip in $ip_tg
	do
		ipset -! add black_list $ip >/dev/null 2>&1
	done
	
	if [ ! -z $xray_wan_black_ip ];then
		xray_wan_black_ip=`dbus get xray_wan_black_ip|base64_decode|sed '/\#/d'`
		echo_date 应用IP/CIDR黑名单
		for ip in $xray_wan_black_ip
		do
			ipset -! add black_list $ip >/dev/null 2>&1
		done
	fi
	
	# white ip/cidr
	#ip1=$(nvram get wan0_ipaddr | cut -d"." -f1,2)
	[ ! -z "$xray_basic_server_ip" ] && SERVER_IP=$xray_basic_server_ip || SERVER_IP=""
	ip_lan="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 240.0.0.0/4 $SERVER_IP 223.5.5.5 223.6.6.6 114.114.114.114 114.114.115.115 1.2.4.8 210.2.4.8 112.124.47.27 114.215.126.16 180.76.76.76 119.29.29.29 $ISP_DNS1 $ISP_DNS2"
	for ip in $ip_lan
	do
		ipset -! add white_list $ip >/dev/null 2>&1
	done
	
	if [ ! -z $xray_wan_white_ip ];then
		xray_wan_white_ip=`echo $xray_wan_white_ip|base64_decode|sed '/\#/d'`
		echo_date 应用IP/CIDR白名单
		for ip in $xray_wan_white_ip
		do
			ipset -! add white_list $ip >/dev/null 2>&1
		done
	fi
}
get_action_chain() {
	case "$1" in
		0)
			echo "RETURN"
		;;
		1)
			echo "XRAY_GFW"
		;;
		2)
			echo "XRAY_CHN"
		;;
		3)
			echo "XRAY_GAM"
		;;
		4)
			echo "XRAY_GLO"
		;;
	esac
}
get_mode_name() {
	case "$1" in
		0)
			echo "不通过代理"
		;;
		1)
			echo "gfwlist模式"
		;;
		2)
			echo "大陆白名单模式"
		;;
		3)
			echo "游戏模式"
		;;
		4)
			echo "全局模式"
		;;
	esac
}
factor(){
	if [ -z "$1" ] || [ -z "$2" ]; then
		echo ""
	else
		echo "$2 $1"
	fi
}
get_jump_mode(){
	case "$1" in
		0)
			echo "j"
		;;
		*)
			echo "g"
		;;
	esac
}
lan_acess_control(){
	# lan access control
	local acl_nu ipaddr proxy_mode proxy_name mac
	acl_nu=`dbus list xray_acl_mode|sort -n -t "=" -k 2|cut -d "=" -f 1 | cut -d "_" -f 4`
	if [ -n "$acl_nu" ]; then
		for acl in $acl_nu
		do
			ipaddr=`dbus get xray_acl_ip_$acl`
			proxy_mode=`dbus get xray_acl_mode_$acl`
			proxy_name=`dbus get xray_acl_name_$acl`
			mac=`dbus get xray_acl_mac_$acl`
			[ -n "$ipaddr" ] && [ -z "$mac" ] && echo_date 加载ACL规则：【$ipaddr】模式为：$(get_mode_name $proxy_mode)
			[ -z "$ipaddr" ] && [ -n "$mac" ] && echo_date 加载ACL规则：【$mac】模式为：$(get_mode_name $proxy_mode)
			[ -n "$ipaddr" ] && [ -n "$mac" ] && echo_date 加载ACL规则：【$ipaddr】【$mac】模式为：$(get_mode_name $proxy_mode)
			# acl in xray
			iptables -t mangle -A XRAY $(factor $ipaddr "-s") $(factor $mac "-m mac --mac-source") -$(get_jump_mode $proxy_mode) $(get_action_chain $proxy_mode)
		done
		echo_date 加载ACL规则：其余主机模式为：$(get_mode_name $xray_acl_default_mode)
	else
		#xray_acl_default_mode="1"
		echo_date 加载ACL规则：所有模式为：$(get_mode_name $xray_acl_default_mode)
	fi
}
apply_nat_rules(){
	local PR_INDEX KP_INDEX
	#----------------------BASIC RULES---------------------
	echo_date 写入iptables规则到mangle表中...
	# 创建xray mangle rule
	iptables -t mangle -N XRAY
	iptables -t mangle -A PREROUTING -j XRAY
	# IP/cidr/白域名 白名单控制（不走代理） for xray
	iptables -t mangle -A XRAY -m set --match-set white_list dst -j RETURN
	# MARK 2019 for xray
	#iptables -t mangle -A XRAY -m mark --mark 0x7e3 -j RETURN
	#-----------------------FOR GFWLIST---------------------
	# 创建gfwlist模式
	iptables -t mangle -N XRAY_GFW
	# IP/CIDR/黑域名 黑名单控制（走代理）
	iptables -t mangle -A XRAY_GFW -p tcp -m set --match-set black_list dst -j TTL --ttl-set 188
	iptables -t mangle -A XRAY_GFW -p tcp -m set --match-set gfwlist dst -j TTL --ttl-set 188
	#-----------------------FOR CHNMODE---------------------
	# 创建大陆白名单模式
	iptables -t mangle -N XRAY_CHN
	iptables -t mangle -A XRAY_CHN -p tcp -m set --match-set black_list dst -j TTL --ttl-set 188
	if [ "$xray_bypass" == "2" ];then
		iptables -t mangle -A XRAY_CHN -p tcp -m geoip ! --destination-country CN -j TTL --ttl-set 188
	else
		iptables -t mangle -A XRAY_CHN -p tcp -m set ! --match-set chnroute dst -j TTL --ttl-set 188
	fi
	#-----------------------FOR GLOABLE---------------------
	# 创建全局模式
	iptables -t mangle -N XRAY_GLO
	# 全局模式控制-全局（走代理）
	iptables -t mangle -A XRAY_GLO -p tcp -j TTL --ttl-set 188
	
	#-----------------------FOR GAMEMODE---------------------
	# 创建游戏模式
	iptables -t mangle -N XRAY_GAM
	iptables -t mangle -A XRAY_GAM -p tcp -m set --match-set black_list dst -j TTL --ttl-set 188
	if [ "$xray_bypass" == "2" ];then
		iptables -t mangle -A XRAY_GAM -p tcp -m geoip ! --destination-country CN -j TTL --ttl-set 188
	else
		iptables -t mangle -A XRAY_GAM -p tcp -m set ! --match-set chnroute dst -j TTL --ttl-set 188
	fi
	# 游戏模式UDP
	ip rule add fwmark 0x07 table 310 pref 789
	ip route add local 0.0.0.0/0 dev lo table 310
	iptables -t mangle -A XRAY_GAM -p udp -m set --match-set black_list dst -j TPROXY --on-port 1280 --tproxy-mark 0x07
	# cidr黑名单控制-chnroute（走代理）
	if [ "$xray_bypass" == "2" ];then
		iptables -t mangle -A XRAY_GAM -p udp -m geoip ! --destination-country CN -j TPROXY --on-port 1280 --tproxy-mark 0x07
	else
		iptables -t mangle -A XRAY_GAM -p udp -m set ! --match-set chnroute dst -j TPROXY --on-port 1280 --tproxy-mark 0x07
	fi
	#-------------------------------------------------------
	# 局域网黑名单（不走代理）/局域网黑名单（走代理）
	lan_acess_control
	# 把最后剩余流量重定向到相应模式的nat表中对对应的主模式的链
	iptables -t mangle -A XRAY -j $(get_action_chain $xray_acl_default_mode)
	#-----------------------NAT表规则-----------------------
	iptables -t nat -N XRAY
	# MARK 2019 for xray
	#iptables -t nat -A XRAY -p tcp -m mark --mark 0x7e3 -j RETURN
	iptables -t nat -A XRAY -p tcp -m ttl --ttl-eq 188 -j REDIRECT --to 1280
	PR_INDEX=`iptables -t nat -L PREROUTING|tail -n +3|sed -n -e '/^prerouting_rule/='`
	[ -n "$PR_INDEX" ] && let RULE_INDEX=$PR_INDEX+1
	KP_INDEX=`iptables -t nat -L PREROUTING|tail -n +3|sed -n -e '/^KOOLPROXY/='`
	[ -n "$KP_INDEX" ] && let RULE_INDEX=$KP_INDEX+1
	#确保添加到默认规则之后
	iptables -t nat -I PREROUTING $RULE_INDEX -p tcp -j XRAY
	#-----------------------FOR ROUTER状态检测---------------------
	# router itself
	if [ "$KP_ENABLE" == "1" -o "$xray_acl_default_mode" == "0" ]; then 
		iptables -t nat -I OUTPUT -j XRAY
	else
		echo_date 当前防火墙规则为无KP模式，开启KP后需要重启xray!
	fi
	iptables -t nat -A OUTPUT -p tcp -m set --match-set router dst -j REDIRECT --to-ports 1280
	#-----------------------FOR 其它服务端口远程连接---------------------
	[ "$xray_basic_forward" == "1" ] && {
		[ "$xray_basic_socks" == "1" ] && {
			iptables -I zone_wan_input 2 -p tcp -m tcp --dport 1281 -m comment --comment "softcenter:xray" -j ACCEPT >/dev/null 2>&1
			iptables -I zone_wan_input 2 -p udp -m udp --dport 1281 -m comment --comment "softcenter:xray" -j ACCEPT >/dev/null 2>&1
		}
		[ "$xray_basic_http" == "1" ] && {
			iptables -I zone_wan_input 2 -p tcp -m tcp --dport 1282 -m comment --comment "softcenter:xray" -j ACCEPT >/dev/null 2>&1
		}
		[ "$xray_basic_ss" == "1" ] && {
			iptables -I zone_wan_input 2 -p tcp -m tcp --dport 1283 -m comment --comment "softcenter:xray" -j ACCEPT >/dev/null 2>&1
			iptables -I zone_wan_input 2 -p udp -m udp --dport 1283 -m comment --comment "softcenter:xray" -j ACCEPT >/dev/null 2>&1
		}	
	}
}
chromecast(){
	local chromecast_nu is_right_lanip
	chromecast_nu=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "dpt:53"|awk '{print $1}'`
	is_right_lanip=`iptables -t nat -L PREROUTING -v -n --line-numbers|grep "dpt:53" |grep "$lan_ipaddr"`
	if [ "$xray_basic_dns_chromecast" == "1" ]; then
		if [ -z "$chromecast_nu" -o -z "$is_right_lanip" ]; then
			[ -z "$is_right_lanip" ] && iptables -t nat -D PREROUTING $chromecast_nu >/dev/null 2>&1
			iptables -t nat -A PREROUTING -p udp -s $(get_lan_cidr) --dport 53 -j DNAT --to $lan_ipaddr >/dev/null 2>&1			
			echo_date 开启chromecast功能（DNS劫持功能）
		else
			echo_date DNS劫持规则已存在，跳过~
		fi
	else
		echo_date DNS劫持规则设置不开启，跳过~
	fi
}
optimized_network(){
	echo_date 优化网络参数
	ulimit -HSn 102400
	cat > /tmp/net_optimized.conf <<-EOF
		fs.file-max = 51200
		net.core.rmem_max = 67108864
		net.core.wmem_max = 67108864
		net.core.rmem_default=65536
		net.core.wmem_default=65536
		net.core.netdev_max_backlog = 4096
		net.core.somaxconn = 4096
		net.ipv4.tcp_syncookies = 1
		net.ipv4.tcp_tw_reuse = 1
		net.ipv4.tcp_tw_recycle = 0
		net.ipv4.tcp_fin_timeout = 30
		net.ipv4.tcp_keepalive_time = 1200
		net.ipv4.ip_local_port_range = 10000 65000
		net.ipv4.tcp_max_syn_backlog = 4096
		net.ipv4.tcp_max_tw_buckets = 5000
		net.ipv4.tcp_fastopen = 3
		net.ipv4.tcp_rmem = 4096 87380 67108864
		net.ipv4.tcp_wmem = 4096 65536 67108864
		net.ipv4.tcp_mtu_probing = 1
	EOF
	sysctl -p /tmp/net_optimized.conf >/dev/null 2>&1
	rm -rf /tmp/net_optimized.conf
}
# =======================================================================================================
load_nat(){
	echo_date "加载nat规则!"
	#flush_nat
	creat_ipset
	add_white_black_ip
	apply_nat_rules
	chromecast
}
restart_dnsmasq(){
	# Restart dnsmasq
	echo_date 重启dnsmasq服务...
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
}
write_numbers(){
	[ -z "$xray_basic_version" ] && xray_basic_version="$(xray -version|cut -d" " -f 2|sed -n 1p)"
	
	ipset_numbers=`cat $KSROOT/xray/gfwlist.conf | grep -c ipset`
	chnroute_numbers=`cat $KSROOT/xray/chnroute.txt | grep -c .`
	cdn_numbers=`cat $KSROOT/xray/cdn.txt | grep -c .`
	
	update_ipset=`cat $KSROOT/xray/version | sed -n 1p | sed 's/#/\n/g'| sed -n 1p`
	update_chnroute=`cat $KSROOT/xray/version | sed -n 2p | sed 's/#/\n/g'| sed -n 1p`
	update_cdn=`cat $KSROOT/xray/version | sed -n 4p | sed 's/#/\n/g'| sed -n 1p`
	dbus set xray_basic_gfw_status="$ipset_numbers 条，最后更新版本： $update_ipset "
	dbus set xray_basic_chn_status="$chnroute_numbers 条，最后更新版本： $update_chnroute "
	dbus set xray_basic_cdn_status="$cdn_numbers 条，最后更新版本： $update_cdn "
}
detect_ss(){
	SS_NU=`iptables -nvL PREROUTING -t nat |sed 1,2d | sed -n '/SHADOWSOCKS/='` 2>/dev/null
	if [ -n "$SS_NU" ];then
		echo_date 检测到你开启了SS！！！
		echo_date xray不能和SS混用，请关闭SS后启用本插件！！
		echo_date 退出 xray 启动...
		dbus set xray_basic_enable=0
		close_in_five
	else
		echo_date xray符合启动条件！~
	fi
}

get_latest_release() {
	wget -qO- -t1 -T2 "https://api.github.com/repos/$1/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g'
	wget -qO- -t1 -T2 "https://api.github.com/repos/v2fly/xray-core/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g'
}

check_update_xray(){
	local lastver oldver
	echo_date 开始检查 xray 最新版本。。。
	if [ "$xray_basic_check_releases" == "0" ]; then
		lastver=$(wget -qO- -t1 -T2 "https://api.github.com/repos/v2fly/xray-core/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
	else
		lastver=$(get_latest_release "xtls/Xray-core")
	fi
	lastver=$(get_latest_release)
	oldver="v$(xray -version|cut -d" " -f 2|sed -n 1p)"
	if [ -n "$lastver" ]; then 
		echo_date 当前版本：$oldver
		echo_date 最新版本：$lastver
		if [ "$lastver" == "$oldver" ]; then
			echo_date 当前已经是最新版本！
			dbus set xray_basic_version=$lastver
			sleep 3
			echo XU6J03M6
		else
			echo_date "准备升级到最新版本，开始下载"
			wget --no-check-certificate --timeout=8 -a $LOG_FILE --tries=2 -O - "https://github.com/v2fly/xray-core/releases/download/${lastver}/xray-linux-64.zip" > /tmp/xray_update.zip
			#curl -r 0-100 -L - "https://github.com/v2fly/xray-core/releases/download/${lastver}/xray-linux-64.zip" -o /tmp/xray_update.zip
			if [ "$?" -eq 0 ] ; then
				echo_date "最新版本已下载，准备安装"
				kill_process
				[ -d "/tmp/xray_update" ] && rm -rf /tmp/xray_update
				mkdir -p /tmp/xray_update
				unzip /tmp/xray_update.zip -d /tmp/xray_update
				cp -rf /tmp/xray_update/xray $KSROOT/bin/xray
				chmod a+x $KSROOT/bin/xray		
				rm -rf /tmp/xray_update
				rm -rf /tmp/xray_update.zip
				echo_date "最新版本已安装，准备重启插件"
				dbus set xray_basic_version=$lastver
				restart_xray
			else
				echo_date "最新版本下载失败，请检查网络到github的连通后再试！"
				dbus set xray_basic_version=$oldver
				sleep 3
				echo XU6J03M6
			fi
		fi
	else
		echo_date 最新版本号检查失败，请检查网络到github的连通后再试！
		sleep 3
		echo XU6J03M6
	fi	
}
#=====================
update_rule(){
	url_back="https://raw.githubusercontent.com/hq450//master/rules/"
	url_main="https://raw.githubusercontent.com/HEXtoDEC/LEDE_xRay/main/rules/"
	
	# version dectet
	version_gfwlist1=$(cat $KSROOT/xray/version | sed -n 1p | sed 's/ /\n/g'| sed -n 1p)
	version_chnroute1=$(cat $KSROOT/xray/version | sed -n 2p | sed 's/ /\n/g'| sed -n 1p)
	version_cdn1=$(cat $KSROOT/xray/version | sed -n 4p | sed 's/ /\n/g'| sed -n 1p)
	version_Routing1=$(cat $KSROOT/xray/version | sed -n 5p | sed 's/ /\n/g'| sed -n 1p)
	version_WhiteList1=$(cat $KSROOT/xray/version | sed -n 6p | sed 's/ /\n/g'| sed -n 1p)
	echo_date 开始更新规则，请等待...
	wget --no-check-certificate --timeout=8 -qO - $url_main/version1 > /tmp/version1
	if [ "$?" == "0" ]; then
		echo_date 检测到在线版本文件，继续...
	else
		echo_date 没有检测到在线版本欸，可能是访问github有问题，去大陆白名单模式试试吧！
		rm -rf /tmp/version1
		exit
	fi
	
	online_content=$(cat /tmp/version1)
	if [ -z "$online_content" ];then
		rm -rf /tmp/version1
	fi
	
	git_line1=$(cat /tmp/version1 | sed -n 1p)
	git_line2=$(cat /tmp/version1 | sed -n 2p)
	git_line4=$(cat /tmp/version1 | sed -n 4p)
	git_line5=$(cat /tmp/version1 | sed -n 5p)
	git_line6=$(cat /tmp/version1 | sed -n 6p)
	
	version_gfwlist2=$(echo $git_line1 | sed 's/ /\n/g'| sed -n 1p)
	version_chnroute2=$(echo $git_line2 | sed 's/ /\n/g'| sed -n 1p)
	version_cdn2=$(echo $git_line4 | sed 's/ /\n/g'| sed -n 1p)
	version_Routing2=$(echo $git_line5 | sed 's/ /\n/g'| sed -n 1p)
	version_WhiteList2=$(echo $git_line6 | sed 's/ /\n/g'| sed -n 1p)
	
	md5sum_gfwlist2=$(echo $git_line1 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	md5sum_chnroute2=$(echo $git_line2 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	md5sum_cdn2=$(echo $git_line4 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	md5sum_Routing2=$(echo $git_line5 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	md5sum_WhiteList2=$(echo $git_line6 | sed 's/ /\n/g'| tail -n 2 | head -n 1)
	
	# update gfwlist
	if [ "$xray_basic_gfwlist_update" == "1" ] || [ -n "$1" ];then
		echo_date " ---------------------------------------------------------------------------------------"
		if [ ! -z "$version_gfwlist2" ];then
			if [ "$version_gfwlist1" != "$version_gfwlist2" ];then
				echo_date 检测到新版本gfwlist，开始更新...
				echo_date 下载gfwlist到临时文件...
				wget --no-check-certificate --timeout=8 -qO - $url_main/gfwlist.conf > /tmp/gfwlist.conf
				md5sum_gfwlist1=$(md5sum /tmp/gfwlist.conf | sed 's/ /\n/g'| sed -n 1p)
				if [ "$md5sum_gfwlist1"x = "$md5sum_gfwlist2"x ];then
					echo_date 下载完成，校验通过，将临时文件覆盖到原始gfwlist文件
					mv /tmp/gfwlist.conf $KSROOT/xray/gfwlist.conf
					sed -i "1s/.*/$git_line1/" $KSROOT/xray/version
					reboot="1"
					echo_date 【更新成功】你的gfwlist刚才已经更新到最新了哦~
				else
					echo_date 下载完成，但是校验没有通过！
				fi
			else
				echo_date 检测到gfwlist本地版本号和在线版本号相同，那还更新个毛啊!
			fi
		else
			echo_date gfwlist文件下载失败！
		fi
	fi
	
	
	# update chnroute
	if [ "$xray_basic_chnroute_update" == "1" ] || [ -n "$1" ];then
		echo_date " ---------------------------------------------------------------------------------------"
		if [ ! -z "$version_chnroute2" ];then
			if [ "$version_chnroute1" != "$version_chnroute2" ];then
				echo_date 检测到新版本chnroute，开始更新...
				echo_date 下载chnroute到临时文件...
				wget --no-check-certificate --timeout=8 -qO - $url_main/chnroute.txt > /tmp/chnroute.txt
				md5sum_chnroute1=$(md5sum /tmp/chnroute.txt | sed 's/ /\n/g'| sed -n 1p)
				if [ "$md5sum_chnroute1"x = "$md5sum_chnroute2"x ];then
					echo_date 下载完成，校验通过，将临时文件覆盖到原始chnroute文件
					mv /tmp/chnroute.txt $KSROOT/xray/chnroute.txt
					sed -i "2s/.*/$git_line2/" $KSROOT/xray/version
					reboot="1"
					echo_date 【更新成功】你的chnroute刚才已经更新到最新了哦~
				else
					echo_date md5sum 下载完成，但是校验没有通过！
				fi
			else
				echo_date 检测到chnroute本地版本号和在线版本号相同，那还更新个毛啊!
			fi
		else
			echo_date chnroute文件下载失败！
		fi
	fi
	
	# update cdn file
	if [ "$xray_basic_cdn_update" == "1" ] || [ -n "$1" ];then
		echo_date " ---------------------------------------------------------------------------------------"
		if [ ! -z "$version_cdn2" ];then
			if [ "$version_cdn1" != "$version_cdn2" ];then
				echo_date 检测到新版本cdn名单，开始更新...
				echo_date 下载cdn名单到临时文件...
				wget --no-check-certificate --timeout=8 -qO - $url_main/cdn.txt > /tmp/cdn.txt
				md5sum_cdn1=$(md5sum /tmp/cdn.txt | sed 's/ /\n/g'| sed -n 1p)
				if [ "$md5sum_cdn1"x = "$md5sum_cdn2"x ];then
					echo_date 下载完成，校验通过，将临时文件覆盖到原始cdn名单文件
					mv /tmp/cdn.txt $KSROOT/xray/cdn.txt
					sed -i "4s/.*/$git_line4/" $KSROOT/xray/version
					reboot="1"
					echo_date 【更新成功】你的cdn名单刚才已经更新到最新了哦~
				else
					echo_date 下载完成，但是校验没有通过！
				fi
			else
				echo_date 检测到cdn名单本地版本号和在线版本号相同，那还更新个毛啊!
			fi
		else
			echo_date cdn名单文件下载失败！
		fi
	fi
	rm -rf /tmp/gfwlist.conf1
	rm -rf /tmp/chnroute.txt1
	rm -rf /tmp/cdn.txt1
	rm -rf /tmp/version1
	
	echo_date 规则更新进程运行完毕！
	# write number
	ipset_numbers=`cat $KSROOT/xray/gfwlist.conf | grep -c ipset`
	chnroute_numbers=`cat $KSROOT/xray/chnroute.txt | grep -c .`
	cdn_numbers=`cat $KSROOT/xray/cdn.txt | grep -c .`
	
	update_ipset=`cat $KSROOT/xray/version | sed -n 1p | sed 's/#/\n/g'| sed -n 1p`
	update_chnroute=`cat $KSROOT/xray/version | sed -n 2p | sed 's/#/\n/g'| sed -n 1p`
	update_cdn=`cat $KSROOT/xray/version | sed -n 4p | sed 's/#/\n/g'| sed -n 1p`
	dbus set xray_basic_gfw_status="$ipset_numbers 条，最后更新版本： $update_ipset "
	dbus set xray_basic_chn_status="$chnroute_numbers 条，最后更新版本： $update_chnroute "
	dbus set xray_basic_cdn_status="$cdn_numbers 条，最后更新版本： $update_cdn "
	
	# reboot ss
	if [ "$reboot" == "1" ];then
		echo_date 自动重启koolss，以应用新的规则文件！请稍后！
		$KSROOT/scripts/xray_config.sh start
	fi
	echo =======================================================================================================
}
rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(date +%s%N)
    echo $(($num%$max+$min))
}
xray_watchdog_status(){
	local rnd newname
	/usr/bin/wget -4 --spider --quiet --tries=2 --timeout=3 www.google.com.tw
	[ "$?" == "0" ] || {
		/usr/bin/wget -4 --spider --quiet --tries=2 --timeout=3 www.baidu.com
		[ "$?" == "0" ] && {
			if [ "$xray_basic_watchdog_mod" == "1" ]; then
				restart_by_nat >/dev/null 2>&1
				echo_date 【xray守护】检测到xray连接出错，重启插件！ >> $LOG_FILE
			else
				if [ "$xray_basic_type" == "1" ]; then
					rnd=$(rand 1 $xray_server_node_max)
					dbus set xray_basic_server="$rnd"
					newname=$(dbus get "xray_server_tag_$rnd")
				else
					rnd=$(rand 1 $xray_sub_node_max)
					dbus set xray_basic_server="$rnd"
					newname=$(dbus get "xray_sub_tag_$rnd")
				fi
				restart_by_nat >/dev/null 2>&1
				echo_date 【xray守护】检测到xray连接出错，随机切换到服务器：$newname！ >> $LOG_FILE			
			fi
		}
	}
}
set_xray_watchdog(){
	if [ "$xray_basic_watchdog" == "1" ]; then
		sed -i '/xraywatchdog/d' /etc/crontabs/root >/dev/null 2>&1
		echo "*/$xray_basic_watchdog_time * * * * /koolshare/scripts/xray_config.sh watchdog #xraywatchdog#" >> /etc/crontabs/root
		echo_date "开启xray守护，检测间隔$xray_basic_watchdog_time分钟"
		check_cron
	else
		sed -i '/xraywatchdog/d' /etc/crontabs/root >/dev/null 2>&1
		echo_date xray守护未开启
	fi
}
set_xray_cron(){
	if [ "$xray_basic_cron" == "1" -a "$xray_basic_enable" == "1" ]; then
		sed -i '/xraytimeswitch/d' /etc/crontabs/root >/dev/null 2>&1
		echo "$xray_basic_cron_enableminute $xray_basic_cron_enablehour * * * /koolshare/scripts/xray_config.sh #xraytimeswitch#" >> /etc/crontabs/root
		echo "$xray_basic_cron_disableminute $xray_basic_cron_disablehour * * * /koolshare/scripts/xray_config.sh stop #xraytimeswitch#" >> /etc/crontabs/root
		echo_date "设置在$xray_basic_cron_enablehour:$xray_basic_cron_enableminute自动开启xray，$xray_basic_cron_disablehour:$xray_basic_cron_disableminute自动关闭xray"
	else
		sed -i '/xraytimeswitch/d' /etc/crontabs/root >/dev/null 2>&1
		echo_date xray自动开关未启用
	fi
}
stop_xray_watchdog(){
	sed -i '/xraywatchdog/d' /etc/crontabs/root >/dev/null 2>&1
	echo_date 关闭xray守护
}
check_cron(){
	local crontab
	crontab=`pidof crond`
	[ -z "$crontab" ] && /etc/init.d/cron start >/dev/null 2>&1
}
clean_server_list(){
	local locallist configlist
	locallist=$(($(dbus list xray_server_|cut -d "=" -f1|cut -d "_" -f4|sort -rn|head -n1)+1))
	[ $locallist -ge $xray_server_node_max ] && {
		configlist=`expr $xray_server_node_max + 1`
		for i in $(seq $configlist $locallist)
		do 
			dbus remove xray_server_tag_$i
			dbus remove xray_server_config_$i
		done
	}
}
#=====================
restart_xray(){
	ONSTART=`ps -l|grep $PPID|grep -v grep|grep S99xray`
	echo_date ---------------------- LEDE 固件 xray -----------------------
	detect_ss
	# stop first
	restore_dnsmasq_conf
	[ -z "$ONSTART" ] && restart_dnsmasq
	flush_nat
	restore_start_file
	kill_process
	# start
	create_dnsmasq_conf
	auto_start
	start_xray
	load_nat
	restart_dnsmasq
	write_numbers
	set_xray_watchdog
	set_xray_cron
	echo_date ------------------------- xray 启动完毕 -------------------------
}
stop_xray(){
	echo_date ---------------------- LEDE 固件 xray -----------------------
	stop_xray_watchdog
	set_xray_cron
	restore_dnsmasq_conf
	restart_dnsmasq
	flush_nat
	restore_start_file
	kill_process
	echo_date ------------------------- xray 成功关闭 -------------------------
}
restart_by_nat(){
	detect_ss
	restore_dnsmasq_conf
	kill_process
	flush_nat
	load_nat
	start_xray
	create_dnsmasq_conf
	restart_dnsmasq
}
# used by rc.d
case $1 in
start)
	set_lock
	if [ "$xray_basic_enable" == "1" ];then
		restart_xray
	else
		stop_xray
    fi
	unset_lock
	;;
stop)
	set_lock
	stop_xray
	unset_lock
	;;
config)
	gen_xray_config
	;;
watchdog)
	xray_watchdog_status
	;;
*)
	set_lock
	[ -z "$2" ] && restart_by_nat
	unset_lock
	;;
esac
# used by httpdb
case $2 in
1)
	if [ "$xray_basic_enable" == "1" ];then
		restart_xray > $LOG_FILE
	else
		stop_xray > $LOG_FILE
	fi
	echo XU6J03M6 >> $LOG_FILE
	http_response $1
	;;
2)
	# remove all xray config in skipd
	echo_date 尝试关闭 xray... > $LOG_FILE
	sh $KSROOT/scripts/xray_config.sh stop
	echo_date 开始清理 xray 配置... >> $LOG_FILE
	confs=`dbus list xray | cut -d "=" -f 1 | grep -v "version"`
	for conf in $confs
	do
		echo_date 移除$conf >> $LOG_FILE
		dbus remove $conf
	done
	echo_date 设置一些默认参数... >> $LOG_FILE
	dbus set xray_basic_enable="0"
	echo_date 完成！ >> $LOG_FILE
	http_response $1
	;;
3)
	#备份配置
	echo "" > $LOG_FILE
	mkdir -p $KSROOT/webs/files
	dbus list xray | grep -v "status" | grep -v "enable" | grep -v "version" | sed 's/=/=\"/' | sed 's/$/\"/g'|sed 's/^/dbus set /' | sed '1 i\\n' | sed '1 isource /koolshare/scripts/base.sh' |sed '1 i#!/bin/sh' > $KSROOT/webs/files/xray_conf_backup.sh
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	;;
4)
	#用备份的xray_conf_backup.sh 去恢复配置
	echo_date "开始恢复xray配置..." > $LOG_FILE
	file_nu=`ls /tmp/upload/xray_conf_backup | wc -l`
	i=20
	until [ -n "$file_nu" ]
	do
		i=$(($i-1))
		if [ "$i" -lt 1 ];then
			echo_date "错误：没有找到恢复文件!"
			echo XU6J03M6
			exit
		fi
		sleep 1
		file_nu=`ls /tmp/upload/xray_conf_backup | wc -l`
	done
	format=`cat /tmp/upload/xray_conf_backup.sh |grep dbus`
	if [ -n "format" ];then
		echo_date "检测到正确格式的配置文件！" >> $LOG_FILE
		cd /tmp/upload
		chmod +x xray_conf_backup.sh
		echo_date "恢复中..." >> $LOG_FILE
		sh xray_conf_backup.sh
		sleep 1
		rm -rf /tmp/upload/xray_conf_backup.sh
		echo_date "恢复完毕！" >> $LOG_FILE
	else
		echo_date "配置文件格式错误！" >> $LOG_FILE
	fi
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	;;
5)
	# 更新xray二进制
  echo ======================================================================================================= > $LOG_FILE
	check_update_xray >> $LOG_FILE
	http_response "$1"
	;;
6)
	# 更新规则
	if [ "$1" == "cron" ];then
		echo ======================================================================================================= > $LOG_FILE
		echo_date "规则更新定时更新计划" >> $LOG_FILE
		update_rule >> $LOG_FILE
		echo XU6J03M6 >> $LOG_FILE
	else
		echo ======================================================================================================= > $LOG_FILE
		update_rule "$1" >> $LOG_FILE
		echo XU6J03M6 >> $LOG_FILE
		http_response "$1"
	fi
	;;
7)
	echo "" > $LOG_FILE
	sed -i '/xraynodeupdate/d' /etc/crontabs/root >/dev/null 2>&1
	if [ "$xray_basic_rule_update" = "1" ];then
		[ "$xray_basic_gfwlist_update" == "1" ] && echo_date "开启gfwlist规则自动更新！" >> $LOG_FILE ||  echo_date "gfwlist规则自动更新未开启！" >> $LOG_FILE
		[ "$xray_basic_chnroute_update" == "1" ] && echo_date "开启chnrotue规则自动更新！" >> $LOG_FILE ||  echo_date "chnrotue规则自动更新未开启！" >> $LOG_FILE
		[ "$xray_basic_cdn_update" == "1" ] && echo_date "开启cdn规则自动更新！" >> $LOG_FILE ||  echo_date "cdn规则自动更新未开启！" >> $LOG_FILE
		if [ "$xray_basic_rule_update_day" = "7" ];then
			echo "0 $xray_basic_rule_update_hr * * * /koolshare/scripts/xray_config.sh cron 6 #xraynodeupdate#" >> /etc/crontabs/root
			echo_date "设置订阅服务器自动更新订阅服务器在每天 $xray_basic_rule_update_hr 点。" >> $LOG_FILE
		else
			echo "0 $xray_basic_rule_update_hr * * $xray_basic_rule_update_day /koolshare/scripts/ss_online_update.sh cron 6 #xraynodeupdate#" >> /etc/crontabs/root
			echo_date "设置订阅服务器自动更新订阅服务器在星期 $xray_basic_rule_update_day 的 $xray_basic_rule_update_hr 点。" >> $LOG_FILE
		fi
	else
		echo_date "关闭规则定时更新计划任务！" >> $LOG_FILE
	fi
	sleep 1
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	;;
8)
	# 更新插件
	check_update_now > $LOG_FILE
	http_response "$1"
	;;
9)
	# 保存服务器列表
	clean_server_list
	http_response "$1"
	;;
10)
	# 更新订阅列表
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	;;
esac