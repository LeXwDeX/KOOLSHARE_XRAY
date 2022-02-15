#!/bin/bash
# cratdir

# 创建文件夹如果不存在的话
dirname=backupfile
echo "the dir name is $dirname"
if [ ! -d $dirname ]; then
	mkdir $dirname
	mkdir $dirname/xray-linux-64
else
	echo dir exist
fi

# 备份白名单,CDN名单等内容
backupRule() {
	wget -4 -O- https://raw.githubusercontent.com/xinhugo/Free-List/master/WhiteList.txt >./${dirname}/WhiteList.txt
	wget -4 -O- https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/ipip_country/ipip_country_cn.netset >./${dirname}/ipip_country_cn.netset
	wget -4 -O- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf >./${dirname}/accelerated-domains.china.conf
	wget -4 -O- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf >./${dirname}/apple.china.conf
	wget -4 -O- https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/google.china.conf >./${dirname}/google.china.conf
	wget -4 -O- http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest >./${dirname}/delegated-apnic-latest
	wget -4 -O- https://raw.githubusercontent.com/xinhugo/Free-List/master/WhiteList.txt >./${dirname}/WhiteList.txt
}

# 获取最新的GeoData
getgeoData() {
	getgeoData=$(wget -qO- -t1 -T2 "https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
	wget -4 -O- "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/${getgeoData}/geoip.dat" >./${dirname}/geoip.dat
	wget -4 -O- "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/${getgeoData}/geosite.dat" >./${dirname}/geosite.dat
}

# 获取最新的xray bin文件
getnewBin() {
	getnewxray=$(wget -qO- -t1 -T2 "https://api.github.com/repos/xtls/Xray-core/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
	wget -4 -O- "https://github.com/xtls/Xray-core/releases/download/${getnewxray}/xray-linux-64.zip" >./${dirname}/xray-linux-64.zip
	unzip -o ./${dirname}/xray-linux-64.zip -d ./${dirname}/xray-linux-64/
}

# 拷贝文件到对应的软件包目录
updateData() {
	cp -f ./${dirname}/geoip.dat ./xray/bin/
	cp -f ./${dirname}/geosite.dat ./xray/bin/
	cp -f ./${dirname}/xray-linux-64/xray ./xray/bin/
	cp -f ./rules/auto_update/cdn.txt ./xray/xray/
	cp -f ./rules/auto_update/chnroute.txt ./xray/xray/
	cp -f ./rules/gfwlist.conf ./xray/xray/
	cp -f ./rules/version1 ./xray/xray/version
}

# 制作压缩包
packageData() {
	tar -zcf latest_xray.tar.gz xray
}

backupRule
getgeoData
getnewBin
updateData
packageData
