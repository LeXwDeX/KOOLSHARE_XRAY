#!/bin/bash
# cratdir

dirname=backupfile
echo "the dir name is $dirname"
if [ ! -d $dirname ]; then
	mkdir $dirname
	mkdir $dirname/xray-linux-64
else
	echo dir exist
fi

backupRule() {
	wget -4 -O- https://raw.githubusercontent.com/xinhugo/Free-List/master/WhiteList.txt >./${dirname}/WhiteList.txt
	wget -4 -O- https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset >./${dirname}/ipip_country_cn.netset
	wget -4 -O- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf >./${dirname}/accelerated-domains.china.conf
	wget -4 -O- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf >./${dirname}/apple.china.conf
	wget -4 -O- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf >./${dirname}/google.china.conf
	wget -4 -O- http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest >./${dirname}/delegated-apnic-latest
	wget -4 -O- https://raw.githubusercontent.com/xinhugo/Free-List/master/WhiteList.txt >./${dirname}/WhiteList.txt
}

getgeoData() {
	getgeoData=$(wget -qO- -t1 -T2 "https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
	wget -4 -O- "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/${getgeoData}/geoip.dat" >./${dirname}/geoip.dat
	wget -4 -O- "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/${getgeoData}/geosite.dat" >./${dirname}/geosite.dat
}

getnewXray() {
	getNewXray=$(wget -qO- -t1 -T2 "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
	wget -4 -O- "https://github.com/XTLS/Xray-core/releases/download/${getNewXray}/Xray-linux-64.zip" >./${dirname}/xray-linux-64.zip
	unzip -o ./${dirname}/xray-linux-64.zip -d ./${dirname}/xray-linux-64/
}

updateXray() {
	cp -f ./${dirname}/geoip.dat ./v2ray/bin/
	cp -f ./${dirname}/geosite.dat ./v2ray/bin/
	cp -f ./${dirname}/xray-linux-64/xray ./v2ray/bin/v2ray
	cp -f ./rules/auto_update/cdn.txt ./v2ray/v2ray/
	cp -f ./rules/auto_update/chnroute.txt ./v2ray/v2ray/
	cp -f ./rules/gfwlist.conf ./v2ray/v2ray/
	cp -f ./rules/version1 ./v2ray/v2ray/version
}

zipXray() {
	tar -zcf latest_Linux64_xray.tar.gz v2ray
}

backupRule
getgeoData
getnewXray
updateXray
zipXray