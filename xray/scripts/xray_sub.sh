#!/bin/sh

# shadowsocks script for HND router with kernel 4.1.27 merlin firmware

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
eval $(dbus export xray)
LOCK_FILE=/var/lock/xray_sub.lock
LOG_FILE=/tmp/upload/xray_log.txt

set_lock() {
	exec 233>"$LOCK_FILE"
	flock -n 233 || {
		echo_date "订阅脚本已经在运行，请稍候再试！"
		exit 1
	}
}

unset_lock() {
	flock -u 233
	rm -rf "$LOCK_FILE"
}

decode_url_link() {
	local link=$1
	local len=$(echo $link | wc -L)
	local mod4=$(($len % 4))
	if [ "$mod4" -gt "0" ]; then
		local var="===="
		local newlink=${link}${var:$mod4}
		echo -n "$newlink" | sed 's/-/+/g; s/_/\//g' | base64 -d 2>/dev/null
	else
		echo -n "$link" | sed 's/-/+/g; s/_/\//g' | base64 -d 2>/dev/null
	fi
}

get_xray_remote_config() {
	decode_link="$1"
	xray_v=$(echo "$decode_link" | jq -r .v)
	xray_ps=$(echo "$decode_link" | jq -r .ps | sed 's/[ \t]*//g')
	xray_add=$(echo "$decode_link" | jq -r .add | sed 's/[ \t]*//g')
	xray_port=$(echo "$decode_link" | jq -r .port | sed 's/[ \t]*//g')
	xray_id=$(echo "$decode_link" | jq -r .id | sed 's/[ \t]*//g')
	xray_aid=$(echo "$decode_link" | jq -r .aid | sed 's/[ \t]*//g')
	xray_net=$(echo "$decode_link" | jq -r .net)
	xray_type=$(echo "$decode_link" | jq -r .type)
	xray_tls_tmp=$(echo "$decode_link" | jq -r .tls)
	[ "$xray_tls_tmp"x == "tls"x ] && xray_tls="tls" || xray_tls="none"

	if [ "$xray_v" == "2" ]; then
		#echo_date "new format"
		xray_path=$(echo "$decode_link" | jq -r .path)
		xray_host=$(echo "$decode_link" | jq -r .host)
	else
		#echo_date "old format"
		case $xray_net in
		tcp)
			xray_host=$(echo "$decode_link" | jq -r .host)
			xray_path=""
			;;
		kcp)
			xray_host=""
			xray_path=""
			;;
		ws)
			xray_host_tmp=$(echo "$decode_link" | jq -r .host)
			if [ -n "$xray_host_tmp" ]; then
				format_ws=$(echo $xray_host_tmp | grep -E ";")
				if [ -n "$format_ws" ]; then
					xray_host=$(echo $xray_host_tmp | cut -d ";" -f1)
					xray_path=$(echo $xray_host_tmp | cut -d ";" -f1)
				else
					xray_host=""
					xray_path=$xray_host
				fi
			fi
			;;
		h2)
			xray_host=""
			xray_path=$(echo "$decode_link" | jq -r .path)
			;;
		esac
	fi

	[ -z "$xray_ps" -o -z "$xray_add" -o -z "$xray_port" -o -z "$xray_id" -o -z "$xray_aid" -o -z "$xray_net" -o -z "$xray_type" ] && return 1 || return 0
}

add_xray_servers() {
	local kcp="null"
	local tcp="null"
	local ws="null"
	local h2="null"
	local tls="null"
	local xrayindex
	usleep 250000
	if [ -z "$1" ]; then
		#[ -z "$xray_sub_node_max" ] && xray_sub_node_max=0
		xrayindex=$(($(dbus list xray_sub_ | cut -d "=" -f1 | cut -d "_" -f4 | sort -rn | head -n1) + 1))
	else
		#[ -z "$xray_server_node_max" ] && xray_server_node_max=0
		xrayindex=$(($(dbus list xray_server_ | cut -d "=" -f1 | cut -d "_" -f4 | sort -rn | head -n1) + 1))
		#xrayindex=`expr $xray_server_node_max + 1`
	fi

	[ "$xray_tls" == "none" ] && local xray_network_security=""
	#if [ "$xray_sub_xray_network" == "ws" -o "$xray_sub_xray_network" == "h2" ];then
	case "$xray_tls" in
	tls)
		local tls="{
			\"allowInsecure\": true,
			\"serverName\": \"$xray_host\"
			}"
		;;
	*)
		local tls="null"
		;;
	esac
	#fi
	# incase multi-domain input
	if [ "$(echo $xray_host | grep ",")" ]; then
		xray_host=$(echo $xray_host | sed 's/,/", "/g')
	fi

	case "$xray_net" in
	tcp)
		if [ "$xray_type" == "http" ]; then
			local tcp="{
				\"connectionReuse\": true,
				\"header\": {
				\"type\": \"http\",
				\"request\": {
				\"version\": \"1.1\",
				\"method\": \"GET\",
				\"path\": [\"/\"],
				\"headers\": {
				\"Host\": [\"$xray_host\"],
				\"User-Agent\": [\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36\",\"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46\"],
				\"Accept-Encoding\": [\"gzip, deflate\"],
				\"Connection\": [\"keep-alive\"],
				\"Pragma\": \"no-cache\"
				}
				},
				\"response\": {
				\"version\": \"1.1\",
				\"status\": \"200\",
				\"reason\": \"OK\",
				\"headers\": {
				\"Content-Type\": [\"application/octet-stream\",\"video/mpeg\"],
				\"Transfer-Encoding\": [\"chunked\"],
				\"Connection\": [\"keep-alive\"],
				\"Pragma\": \"no-cache\"
				}
				}
				}
				}"
		else
			local tcp="null"
		fi
		;;
	kcp)
		local kcp="{
			\"mtu\": 1350,
			\"tti\": 50,
			\"uplinkCapacity\": 12,
			\"downlinkCapacity\": 100,
			\"congestion\": false,
			\"readBufferSize\": 2,
			\"writeBufferSize\": 2,
			\"header\": {
			\"type\": \"$xray_type\",
			\"request\": null,
			\"response\": null
			}
			}"
		;;
	ws)
		local ws="{
			\"connectionReuse\": true,
			\"path\": \"$xray_path\",
			\"headers\": { 
				\"Host\": \"$xray_host\"
			}
			}"
		;;
	h2)
		local h2="{
			\"path\": \"$xray_path\",
			\"headers\": { 
				\"Host\": \"$xray_host\"
			}
			}"
		;;
	esac
	local xray_config="
		{
			\"outbound\": {
				\"protocol\": \"vmess\",
				\"settings\": {
					\"vnext\": [
						{
							\"address\": \"$xray_add\",
							\"port\": $xray_port,
							\"users\": [
								{
									\"id\": \"$xray_id\",
									\"alterId\": $xray_aid,
									\"security\": \"auto\"
								}
							]
						}
					]
				},
				\"streamSettings\": {
					\"network\": \"$xray_net\",
					\"security\": \"$xray_tls\",
					\"tlsSettings\": $tls,
					\"tcpSettings\": $tcp,
					\"kcpSettings\": $kcp,
					\"wsSettings\": $ws,
					\"httpSettings\": $h2
				},
				\"mux\": {
					\"enabled\": true
				}
			}
		}"
	if [ -z "$1" ]; then
		dbus set "xray_sub_tag_$xrayindex"="$xray_ps"
		dbus set "xray_sub_config_$xrayindex"=$(echo $xray_config | base64_encode)
		dbus set xray_sub_node_max=$xrayindex
		echo_date xray 通过订阅：新增加 【$xray_ps】 到节点列表第 $xrayindex 位。
	else
		dbus set "xray_server_tag_$xrayindex"="$xray_ps"
		dbus set "xray_server_config_$xrayindex"=$(echo $xray_config | base64_encode)
		dbus set xray_server_node_max=$xrayindex
		echo_date xray 通过链接：新增加 【$xray_ps】 到节点列表第 $xrayindex 位。
	fi
}

get_oneline_rule_now() {
	# ss订阅
	xray_subscribe_link="$1"
	LINK_FORMAT=$(echo "$xray_subscribe_link" | grep -E "^http://|^https://")
	[ -z "$LINK_FORMAT" ] && return 4

	echo_date "开始更新在线订阅列表..."
	echo_date "开始下载订阅链接到本地临时文件，请稍等..."
	rm -rf /tmp/xray_subscribe_file* >/dev/null 2>&1

	if [ "$xray_basic_suburl_socks" == "1" ]; then
		socksopen=$(netstat -nlp | grep -w 1280 | grep -E "local|xray")
		if [ -n "$socksopen" ]; then
			echo_date "使用 xray 提供的socks代理网络下载..."
			curl --connect-timeout 8 -s -L --socks5-hostname 127.0.0.1:1280 $xray_subscribe_link >/tmp/xray_subscribe_file.txt
		else
			echo_date "没有可用的socks5代理端口，改用常规网络下载..."
			curl --connect-timeout 8 -s -L $xray_subscribe_link >/tmp/xray_subscribe_file.txt
		fi
	else
		echo_date "使用常规网络下载..."
		curl --connect-timeout 8 -s -L $xray_subscribe_link >/tmp/xray_subscribe_file.txt
	fi

	#虽然为0但是还是要检测下是否下载到正确的内容
	if [ "$?" == "0" ]; then
		#订阅地址有跳转
		blank=$(cat /tmp/xray_subscribe_file.txt | grep -E " |Redirecting|301")
		if [ -n "$blank" ]; then
			echo_date 订阅链接可能有跳转，尝试更换wget进行下载...
			rm /tmp/xray_subscribe_file.txt
			if [ "$(echo $xray_subscribe_link | grep ^https)" ]; then
				wget --no-check-certificate -qO /tmp/xray_subscribe_file.txt $xray_subscribe_link
			else
				wget -qO /tmp/xray_subscribe_file.txt $xray_subscribe_link
			fi
		fi
		#下载为空...
		if [ -z "$(cat /tmp/xray_subscribe_file.txt)" ]; then
			echo_date 下载为空...
			return 3
		fi
		#产品信息错误
		wrong1=$(cat /tmp/xray_subscribe_file.txt | grep "{")
		wrong2=$(cat /tmp/xray_subscribe_file.txt | grep "<")
		if [ -n "$wrong1" -o -n "$wrong2" ]; then
			return 2
		fi
	else
		return 1
	fi

	if [ "$?" == "0" ]; then
		echo_date 下载订阅成功...
		echo_date 开始解析节点信息...

		decode_url_link $(cat /tmp/xray_subscribe_file.txt) >/tmp/xray_subscribe_file_temp1.txt
		xray_group=$(echo $xray_subscribe_link | awk -F'[/:]' '{print $4}')

		# 检测vmess
		NODE_FORMAT1=$(cat /tmp/xray_subscribe_file_temp1.txt | grep -E "^ss://")
		NODE_FORMAT2=$(cat /tmp/xray_subscribe_file_temp1.txt | grep -E "^vmess://")
		NODE_FORMAT3=$(cat /tmp/xray_subscribe_file_temp1.txt | grep -E "^vless://")

		if [ -n "$NODE_FORMAT2" ]; then
			# xray 订阅
			# detect format again
			if [ -n "$NODE_FORMAT1" ]; then
				# vmess://里夹杂着ss://
				NODE_NU=$(cat /tmp/xray_subscribe_file_temp1.txt | grep -Ec "vmess://|ss://|ssr://")
				echo_date 检测到vmess和ss节点格式，共计$NODE_NU个节点...
				urllinks=$(decode_url_link $(cat /tmp/xray_subscribe_file.txt) | sed 's/vmess:\/\///g')

			elif [ -n "$NODE_FORMAT2" ]; then
				# 纯vmess://
				NODE_NU=$(cat /tmp/xray_subscribe_file_temp1.txt | grep -Ec "vmess://")
				echo_date 检测到vmess节点格式，共计$NODE_NU个节点...
				urllinks=$(decode_url_link $(cat /tmp/xray_subscribe_file.txt) | sed 's/vmess:\/\///g')

			elif [ -n "$NODE_FORMAT3" ]; then
				# 纯vless://
				NODE_NU=$(cat /tmp/xray_subscribe_file_temp1.txt | grep -Ec "vless://")
				echo_date 检测到vmess节点格式，共计$NODE_NU个节点...
				urllinks=$(decode_url_link $(cat /tmp/xray_subscribe_file.txt) | sed 's/vless:\/\///g')
			fi

			remove_sub

			for link in $urllinks; do
				decode_link=$(decode_url_link $link)
				decode_link=$(echo $decode_link | jq -c .)
				if [ -n "$decode_link" ]; then
					get_xray_remote_config "$decode_link"
					[ "$?" == "0" ] && add_xray_servers || echo_date "检测到一个错误节点，已经跳过！"
				else
					echo_date "解析失败！！！"
				fi
			done

			ONLINE_GET=$(dbus list xray_sub_tag_ | wc -l) || 0
			echo_date "本次更新订阅来源 【$xray_group】"
			echo_date "现共有订阅xray节点：$ONLINE_GET 个。"
			echo_date "在线订阅列表更新完成!"
			echo_date "在线订阅列表不会在自建服务列表中显示，请在【账号设置】-【服务器类型】选择【订阅】使用！"
			set_cru
		else
			return 3
		fi
	else
		return 1
	fi
}

start_update() {
	online_url_nu=$(dbus get xray_basic_suburl | base64_decode | sed 's/$/\n/' | sed '/^$/d' | wc -l)
	url=$(dbus get xray_basic_suburl | base64_decode | awk '{print $1}' | sed -n "$z p" | sed '/^#/d')
	[ -z "$url" ] && continue
	echo_date "==================================================================="
	echo_date "                             xray 服务器订阅程序"
	echo_date "==================================================================="
	echo_date "从 $url 获取订阅..."
	addnum=0
	updatenum=0
	delnum=0
	get_oneline_rule_now "$url"

	case $? in
	0)
		continue
		;;
	2)
		echo_date "无法获取产品信息！请检查你的服务商是否更换了订阅链接！"
		rm -rf /tmp/xray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "退出订阅程序..."
		exit
		;;
	3)
		echo_date "该订阅链接不包含任何节点信息！请检查你的服务商是否更换了订阅链接！"
		rm -rf /tmp/xray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "退出订阅程序..."
		exit
		;;
	4)
		echo_date "订阅地址错误！检测到你输入的订阅地址并不是标准网址格式！"
		rm -rf /tmp/xray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "退出订阅程序..."
		exit
		;;
	1 | *)
		echo_date "下载订阅失败...请检查你的网络..."
		rm -rf /tmp/xray_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date "退出订阅程序..."
		exit
		;;
	esac

	# 结束
	echo_date "-------------------------------------------------------------------"
	echo_date "一点点清理工作..."
	rm -rf /tmp/xray_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/xray_subscribe_file_temp1.txt >/dev/null 2>&1
	echo_date "==================================================================="
	echo_date "所有订阅任务完成，请等待6秒，或者手动关闭本窗口！"
	echo_date "==================================================================="
}

add() {
	echo_date "==================================================================="
	echo_date 通过xray链接添加节点...
	rm -rf /tmp/xray_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/xray_subscribe_file_temp1.txt >/dev/null 2>&1
	#echo_date 添加链接为：`dbus get xray_base64_links`
	xraylinks=$(dbus get xray_base64_links | sed 's/$/\n/' | sed '/^$/d')
	for xraylink in $xraylinks; do
		if [ -n "$xraylink" ]; then
			if [ -n "$(echo -n "$xraylinks" | grep "vmess://")" ]; then
				echo_date 检测到vmess链接...开始尝试解析...
				new_xraylink=$(echo -n "$xraylink" | sed 's/vmess:\/\///g')
				decode_xraylink=$(decode_url_link $new_xraylink)
				decode_xraylink=$(echo $decode_xraylink | jq -c .)
				get_xray_remote_config $decode_xraylink
				add_xray_servers 1
			elif [ -n "$(echo -n "$xraylinks" | grep "vless://")" ]; then
				echo_date 检测到vless链接...开始尝试解析...
				new_xraylink=$(echo -n "$xraylink" | sed 's/vless:\/\///g')
				decode_xraylink=$(decode_url_link $new_xraylink)
				decode_xraylink=$(echo $decode_xraylink | jq -c .)
				get_xray_remote_config $decode_xraylink
				add_xray_servers 1
			else
				echo_date 没有检测到vmess、vless信息，添加失败，请检查输入...
			fi
		fi
		dbus remove xray_base64_links
	done
	echo_date "==================================================================="
}

set_cru() {
	if [ "$xray_basic_node_update" = "1" ]; then
		sed -i '/xraynodeupdate/d' /etc/crontabs/root >/dev/null 2>&1
		if [ "$xray_basic_node_update_day" = "7" ]; then
			echo "0 $xray_basic_node_update_hr * * * /koolshare/scripts/xray_sub.sh 3 3 #xraynodeupdate#" >>/etc/crontabs/root
			echo_date "设置自动更新订阅服务在每天 $xray_basic_node_update_hr 点。" >>$LOG_FILE
		else
			echo "0 $xray_basic_node_update_hr * * xray_basic_node_update_day /koolshare/scripts/xray_sub.sh 3 3 #xraynodeupdate#" >>/etc/crontabs/root
			echo_date "设置自动更新订阅服务在星期 $xray_basic_node_update_day 的 $xray_basic_node_update_hr 点。" >>$LOG_FILE
		fi
	else
		echo_date "自动更新订阅服务已关闭！" >>$LOG_FILE
		sed -i '/xraynodeupdate/d' /etc/crontabs/root >/dev/null 2>&1
	fi
}

remove_server() {
	# 2 清除已有的ss节点配置
	echo_date 删除所有普通节点信息！
	confs=$(dbus list xray_server_ | cut -d "=" -f 1)
	for conf in $confs; do
		#echo_date 移除$conf
		dbus remove $conf
	done
	dbus set xray_server_node_max=0
}

remove_sub() {
	# 2 清除已有的ss节点配置
	echo_date 删除所有订阅节点信息！
	confs=$(dbus list xray_sub_ | cut -d "=" -f 1)
	for conf in $confs; do
		#echo_date 移除$conf
		dbus remove $conf
	done
	dbus set xray_sub_node_max=0
}

case $2 in
1)
	# 删除所有节点
	set_lock
	echo " " >$LOG_FILE
	remove_server >>$LOG_FILE
	remove_sub >>$LOG_FILE
	unset_lock
	echo XU6J03M6 >>$LOG_FILE
	http_response "$1"
	;;
2)
	# 删除所有订阅节点
	set_lock
	echo " " >$LOG_FILE
	remove_sub >>$LOG_FILE
	unset_lock
	echo XU6J03M6 >>$LOG_FILE
	http_response "$1"
	;;
3)
	# 订阅节点
	set_lock
	echo " " >$LOG_FILE
	start_update >>$LOG_FILE
	unset_lock
	echo XU6J03M6 >>$LOG_FILE
	http_response "$1"
	;;
4)
	# 链接添加xray
	set_lock
	echo " " >$LOG_FILE
	add >>$LOG_FILE
	unset_lock
	echo XU6J03M6 >>$LOG_FILE
	http_response "$1"
	;;
esac
