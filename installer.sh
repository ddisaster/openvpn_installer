#!/bin/bash

ls /root &> /dev/null

if [ "$?" != "0" ]; then
	echo "Run this script with root privileges"
	exit 1
fi

function error {
	exit 1
}

# Get informations
while [ true ]; do
	read -p "Custmer Name: " customer
	read -p "Server addresse (e.g.: cust.dyndns.org): " server_addr
	read -p "Customer network (e.g.: 192.168.2.0): " cust_network
	read -p "Customer netmask (e.g.: 255.255.255.0): " cust_netmask
	read -p "Customer vpn network (e.g.: 10.8.0.0): " vpn_network
	read -p "Port (e.g.: 1194): " port
	read -p "Country (e.g.: DE): " country
	read -p "Province (e.g.: BY): " province
	read -p "City (e.g.: Illertissen): " city
	read -p "Organisation (e.g.: Computer Service Schmid): " org
	read -p "Email (e.g.: service@computerserviceschmid.de): " email
	read -p "Organisation Unit (e.g.: Verkauf): " ounit

	read -p "Server IP (e.g.: 192.168.2.201/24): " server_ip
	read -p "Gateway IP (e.g.: 192.168.2.100): " gateway

	read -p "All Informations correct? [y|n] " -n 1 finished
	echo
	if [ "${finished}" == "y" ]; then
		break
	fi
done

# update and install packages
apt-get update || error
apt-get upgrade -y || error 
apt-get dist-upgrade -y || error
apt-get install -y git openvpn easy-rsa iptables || error

# enable ip_forwarding
cp /etc/sysctl.conf /etc/sysctl.conf.bak || error
cat /etc/sysctl.conf | sed -e "s/#net.ipv4.ip_forward=0/net.ipv4.ip_forward=1/g" > /etc/sysctl.conf || error
rm /etc/sysctl.conf.bak || error
sysctl -w net.ipv4.ip_forward=1 || error

# generate keys
cp -r /usr/share/easy-rsa/ /etc/openvpn || error
mkdir /etc/openvpn/easy-rsa/keys

route=$(ip route | grep default)
found=false
for i in $route; do
	if [ ${i} == "dev" ]; then
		found=true
	fi
	if [ found ]; then
		interface=${i}
	fi
done
cp /etc/network/interfaces /etc/network/interfaces.backup
grep 

# generate config file
git clone https://github.com/ddisaster/openvpn_installer.git /tmp/openvpn_installer || error

cp /tmp/openvpn_installer/server.conf /etc/openvpn/server.conf

echo "port ${port}" >> /etc/openvpn/server.conf
echo "server ${vpn_network} 255.255.255.0" >> /etc/openvpn/server.conf
echo "push \"route ${cust_network} ${cust_netmask}\"" >> /etc/openvpn/server.conf
echo "route ${cust_network} ${cust_netmask}" >> /etc/openvpn/server.conf

cp /tmp/openvpn_installer/vars /etc/openvpn/easy-rsa/vars

echo "export KEY_COUNTRY=\"${country}\"" >> /etc/openvpn/easy-rsa/vars
echo "export KEY_PROVINCE=\"${province}\"" >> /etc/openvpn/easy-rsa/vars
echo "export KEY_CITY=\"${city}\"" >> /etc/openvpn/easy-rsa/vars
echo "export KEY_ORG=\"${org}\"" >> /etc/openvpn/easy-rsa/vars
echo "export KEY_EMAIL=\"${mail}\"" >> /etc/openvpn/easy-rsa/vars
echo "export KEY_OU=\"${ounit}\"" >> /etc/openvpn/easy-rsa/vars


penssl dhparam -out /etc/openvpn/dh2048.pem 2048 || error

cd /etc/openvpn/easy-rsa
source vars || error
./clean-all || error
./build-ca || error
./build-key-server server || error

cp /etc/openvpn/easy-rsa/keys/{server.crt,server.key,ca.crt} /etc/openvpn || error
