#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "alpine"; then
    release="alpine"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

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

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi

install_base() {
if [[ "${release}" == "centos" ]]; then
    yum install epel-release -y
    yum install wget unzip -y
elif [[ "${release}" == "alpine" ]]; then
    apk update
    apk add wget unzip
else
    apt update
    apt install wget unzip -y
fi
}

Disable_automatic_updates() {
echo -e "${green}开始 尝试关闭自动更新"
if [[ "${release}" == "alpine" ]]; then
    if [ -f /etc/init.d/nezha-agent ]; then
        echo -e "${green}/etc/init.d/nezha-agent 存在 开始修改 ${plain}"
        sed -i '/command_args=/ s/"$/ --disable-auto-update --disable-force-update"/' /etc/init.d/nezha-agent
        echo -e "${green}=========================================== ${plain}"
        cat /etc/init.d/nezha-agent  
    else
       echo -e "${yellow}/etc/init.d/nezha-agent 不存在 请尝试手动修改 ${plain}"
    fi
else
    if [ -f /etc/systemd/system/nezha-agent.service ]; then
        echo -e "${green}/etc/systemd/system/nezha-agent.service 存在 开始修改 ${plain}"
        sudo sed -i '/^ExecStart=/ s/$/ --disable-auto-update --disable-force-update/' /etc/systemd/system/nezha-agent.service
        echo -e "${green}=========================================== ${plain}"   
        cat /etc/systemd/system/nezha-agent.service
    else
       echo -e "${yellow}/etc/systemd/system/nezha-agent.service 不存在 请尝试手动修改 ${plain}"
    fi
fi
}




Downgrade_agent(){
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


}

restart_agent(){
echo -e "${green}开始尝试重启Agent"
if [[ "${release}" == "centos" ]]; then
sudo systemctl daemon-reload
systemctl restart nezha-agent

elif [[ "${release}" == "alpine" ]]; then
    chmod +x /etc/init.d/nezha-agent
    rc-update add nezha-agent default
    rc-service nezha-agent restart
else
    sudo systemctl daemon-reload
    systemctl restart nezha-agent
fi
}




echo -e "${green}开始运行 检测到系统为: ${release} 架构: ${arch} ${plain}"

install_base
Disable_automatic_updates
sleep 1
        echo -e "${green}=========================================== ${plain}" 
        echo -e "${green}请自行判断配置是否正确 ${plain}" 
Downgrade_agent
restart_agent