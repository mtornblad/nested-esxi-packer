cat << 'EOF' > files/local.sh
#!/bin/sh ++group=host/vim/vmvisor/boot
# local configuration options
# Note: modify at your own risk!  If you do/use anything in this
# script that is not part of a stable API (relying on files to be in
# specific places, specific tools, specific output, etc) there is a
# possibility you will end up with a broken system after patching or
# upgrading.  Changes are not supported unless under direction of
# VMware support.
# Note: This script will not be run when UEFI secure boot is enabled.
# rc.local
# /sbin/auto-backup.sh 
#!/bin/bash -x
# William Lam
# www.virtuallyghetto.com
# Sample Network Customization script for VMware PhotonOS
# https://github.com/lamw/custom-virtual-appliances/blob/master/rc.local
if [ -e /root_ran_customization ]; then
    touch /root_exist
    exit
else
    touch /root_running
    HOSTNAME_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.hostname")
    PASSWORD_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.password")
    IP_ADDRESS_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.ipaddress")
    NETMASK_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.netmask")
    GATEWAY_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.gateway")
    DNS_SERVER_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.dns")
    DNS_DOMAIN_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.domain")
    NTP_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.ntp")
    VLAN_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.vlan")
    SSH_PROPERTY=$(vmtoolsd --cmd "info-get guestinfo.ovfEnv" | grep "guestinfo.ssh")

    ##################################
    ### No User Input, assume DHCP ###
    ##################################
    if [ -z "${HOSTNAME_PROPERTY}" ]; then
    touch /root_noproperty
    #########################
    ### Static IP Address ###
    #########################
    else
        HOSTNAME=$(echo "${HOSTNAME_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
        PASSWORD=$(echo "${PASSWORD_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
        IP_ADDRESS=$(echo "${IP_ADDRESS_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
        NETMASK=$(echo "${NETMASK_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
        GATEWAY=$(echo "${GATEWAY_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
        DNS_SERVER=$(echo "${DNS_SERVER_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
        DNS_DOMAIN=$(echo "${DNS_DOMAIN_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
        NTP=$(echo "${NTP_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
        VLAN=$(echo "${VLAN_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')
        SSH=$(echo "${SSH_PROPERTY}" | awk -F 'oe:value="' '{print $2}' | awk -F '"' '{print $1}')

        HOSTNAME=$(echo $HOSTNAME|awk -F ' ' '{print $1}')
        PASSWORD=$(echo $PASSWORD|awk -F ' ' '{print $1}')
        IP_ADDRESS=$(echo $IP_ADDRESS|awk -F ' ' '{print $1}')
        NETMASK=$(echo $NETMASK|awk -F ' ' '{print $1}')
        GATEWAY=$(echo $GATEWAY|awk -F ' ' '{print $1}')
        DNS_SERVER=$(echo $DNS_SERVER|awk -F ' ' '{print $1}')
        DNS_DOMAIN=$(echo $DNS_DOMAIN|awk -F ' ' '{print $1}')
        NTP=$(echo $NTP|awk -F ' ' '{print $1}')
        VLAN=$(echo $VLAN|awk -F ' ' '{print $1}')
        SSH=$(echo $SSH|awk -F ' ' '{print $1}')

#        v300=$(esxcli --formatter=csv --format-param=fields='Size,Devfs Path' --format-param=show-header=false storage core device list|sort | tail -2 |head -1 | awk -F ',' '{print $2}'|cut -d/ -f5)
#        v24=$(esxcli --formatter=csv --format-param=fields='Size,Devfs Path' --format-param=show-header=false storage core device list|sort | tail -3 |head -1 | awk -F ',' '{print $2}'|cut -d/ -f5)
#        /bin/partedUtil setptbl /vmfs/devices/disks/${v300} gpt
#        /bin/partedUtil setptbl /vmfs/devices/disks/${v24} gpt
#        esxcli vsan storage tag add -d ${v300} -t capacityFlash
#        esxcli vsan network ipv4 add -i vmk0

        #esxcli network ip dns server list
        esxcli network ip dns server add -s ${DNS_SERVER}
        esxcli system hostname set --domain=${DNS_DOMAIN}
        echo -e "${PASSWORD}\n${PASSWORD}" | passwd
        esxcli system hostname set --fqdn=${HOSTNAME}
        esxcli network firewall set --enabled=0
        esxcli system ntp set --server=${NTP}
        esxcli system ntp set --enabled=yes
        esxcli network vswitch standard set --vswitch-name=vSwitch0 --mtu 9000
        esxcli network vswitch standard policy security set --vswitch-name vSwitch0 --allow-forged-transmits=true --allow-mac-change=true --allow-promiscuous=true
        esxcli network vswitch standard portgroup set --portgroup-name='Management Network' --vlan-id ${VLAN}
        esxcli network vswitch standard portgroup set --portgroup-name='VM Network' 
        chkconfig SSH on > /dev/null 2>&1
        touch /root_ran_customization
        cp /etc/rc.local.d/.#local.sh /etc/rc.local.d/local.sh
        esxcli network ip interface ipv4 set -i vmk0 -g ${GATEWAY} -I ${IP_ADDRESS} -N ${NETMASK} -t static -P false
        esxcli network ip route ipv4 remove -n 0.0.0.0/0.0.0.0 -g 192.168.1.1
        esxcli network ip route ipv4 add --gateway ${GATEWAY} --network 0.0.0.0/0.0.0.0
        /sbin/generate-certificates
        openssl x509 -in /etc/vmware/ssl/rui.crt -out /etc/vmware/ssl/castore.pem
        #/etc/init.d/hostd restart
        #/etc/init.d/vpxa restart
        #To restart all management agents on the host, run the command
        /bin/services.sh restart
        #openssl s_client  -connect localhost:443 |grep notBefore
        /sbin/auto-backup.sh
    fi
fi
exit 0
EOF