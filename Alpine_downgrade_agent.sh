#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1



arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="64"
    echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
fi



if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
    exit 2
fi




    apk update
    apk add wget unzip



echo -e "${green}开始 尝试关闭自动更新"

    if [ -f /etc/init.d/nezha-agent ]; then
        echo -e "${green}/etc/init.d/nezha-agent 存在 开始修改 ${plain}"
        sed -i '/command_args=/ s/"$/ --disable-auto-update --disable-force-update"/' /etc/init.d/nezha-agent
        echo -e "${green}=========================================== ${plain}"
        cat /etc/init.d/nezha-agent  
    else
       echo -e "${yellow}/etc/init.d/nezha-agent 不存在 请尝试手动修改 ${plain}"
    fi






echo -e "${green}开始尝试降级Agent"
    if [ -f /opt/nezha/agent/nezha-agent ]; then
        echo -e "${green}=========================================== ${plain}"        
        echo -e "${green}/opt/nezha/agent/nezha-agent 存在 开始尝试降级 ${plain}"
        echo -e "${green}检测到系统为: ${release} 架构: ${arch} ${plain}"

        if [[ "${arch}" == "64" ]]; then
        wget https://github.com/nezhahq/agent/releases/download/v0.15.15/nezha-agent_linux_amd64.zip && unzip nezha-agent_linux_amd64.zip && rm nezha-agent_linux_amd64.zip && mv nezha-agent /opt/nezha/agent/nezha-agent
        elif [[ "${arch}" == "arm64-v8a" ]]; then
        wget https://github.com/nezhahq/agent/releases/download/v0.15.15/nezha-agent_linux_arm64.zip && unzip nezha-agent_linux_arm64.zip && rm nezha-agent_linux_arm64.zip && mv nezha-agent /opt/nezha/agent/nezha-agent
        fi

    else
       echo -e "${yellow}/opt/nezha/agent/nezha-agent 不存在 请尝试手动降级 ${plain}"
    fi





    chmod +x /etc/init.d/nezha-agent
    rc-update add nezha-agent default
    rc-service nezha-agent restart




