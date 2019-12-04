#!/bin/sh

#if [ -f "/etc/os-release" ]; then
#    which  busybox;
#    if [[ $? == 0 ]] && cat /etc/os-release | grep -qwi 'alpine'; then
#        apk add --no-cache tzdata ;
#        cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;
#        echo "Asia/Shanghai" > /etc/timezone ;
#        apk del tzdata ;
#    else
#        if cat /etc/os-release | grep -qwiE 'ubuntu|debian'; then
#            export DEBIAN_FRONTEND=noninteractive;
#            apt-get update ;
#            apt-get install --no-install-recommends net-tools tzdata vim iputils-ping curl telnet -y;
#            cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;
#            echo "Asia/Shanghai" > /etc/timezone;
#        else
#            if cat /etc/os-release | grep -qwi 'centos'; then
#                yum install iputils net-tools vim curl telnet -y;
#                rm -rf /etc/localtime ;
#                cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;
#                echo "Asia/Shanghai" > /etc/timezone;
#            fi
#        fi
#    fi
#else
#    which  busybox;
#    if [ $? == 0 ]; then
#    echo 'busybox images';
#    fi
#
#fi


if grep -q "Photon" /etc/lsb-release; then
    tdnf update -y 
    tdnf install -y tzdata curl iputils telnet vim 
    cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime ;
    tdnf clean all
else
    echo "Current OS is not Photon"
fi