# LEDE_KoolShare_XRay

## Koolshare版本不在维护，转战原生OpenWRT。原生更好使！

## 简介
* 原始版本基于LEDE的V2Ray软件包修改而来。目前系统环境变量，运行目录，配置文件等都修改成了适合XRAY的版本，经测试可用，可支持各类复杂的配置。
* 服务器每天晚上会进行各类规则文件的更新，并发布和打包最新的XRay客户端。
* 新老版本系统变量和安装目录完全不一样，不冲突，可两个都安装。
* 软件使用测试平台：`Openwrt Koolshare Router V2.37 r17471-8ed31dafdf`，其他系统暂时没有设备可测试。

## 目录
* ./rules/auto_update/update_rules.sh 更新配置
* ./run_me.sh 打包用

## 分支说明
* main = xray版本
* old_vray = 老版本

## 使用方式
* 使用`离线安装`即可，如果遇到关键字检测不可用，可在BASH中输入解决此问题：
```bash
# 去掉软件中心屏蔽字
sed -i 's/\tdetect_package/\t# detect_package/g' /koolshare/scripts/ks_tar_install.sh
```

## TODO
* 可解析`vless://`协议的订阅
