#!/bin/bash

ls /root &> /dev/null

if [ "$?" != "0" ]; then
	echo "Run this script with root privileges"
	exit 1
fi

function error {
	echo "error"
	exit 1
}

# Get informations
while [ true ]; do
	clear
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

	read -p "First VPN User: " user
	read -p "Passowrd: " password

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
apt-get install -y git openvpn easy-rsa iptables vim gcc || error

# enable ip_forwarding
cp /etc/sysctl.conf /etc/sysctl.conf.bak || error
cat /etc/sysctl.conf | sed -e "s/#net.ipv4.ip_forward=0/net.ipv4.ip_forward=1/g" > /etc/sysctl.conf || error
rm /etc/sysctl.conf.bak || error
sysctl -w net.ipv4.ip_forward=1 || error

# generate keys
rm -r /etc/openvpn
mkdir /etc/openvpn || error
cp -r /usr/share/easy-rsa /etc/openvpn/easy-rsa || error
mkdir /etc/openvpn/easy-rsa/keys || error

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
mv /etc/network/interfaces /etc/network/interfaces.backup || error
grep -v ${interface} /etc/network/interfaces.backup > /etc/network/interfaces || error
echo "iface ${interface} inet static" >> /etc/network/interfaces || error
echo "   address ${server_ip}" >> /etc/network/interfaces || error
echo "   gateway ${gateway}" >> /etc/network/interfaces || error

# generate config file
tempfolder=$(mktemp -d) || error
git clone https://github.com/ddisaster/openvpn_installer.git ${tempfolder} || error

cp ${tempfolder}/server.conf /etc/openvpn/server.conf || error

echo "port ${port}" >> /etc/openvpn/server.conf || error
echo "server ${vpn_network} 255.255.255.0" >> /etc/openvpn/server.conf || error
echo "push \"route ${cust_network} ${cust_netmask}\"" >> /etc/openvpn/server.conf || error
echo "route ${cust_network} ${cust_netmask}" >> /etc/openvpn/server.conf || error

rm /etc/openvpn/easy-rsa/vars || error
cp ${tempfolder}/vars /etc/openvpn/easy-rsa/vars || error

echo "export KEY_COUNTRY=\"${country}\"" >> /etc/openvpn/easy-rsa/vars || error
echo "export KEY_PROVINCE=\"${province}\"" >> /etc/openvpn/easy-rsa/vars || error
echo "export KEY_CITY=\"${city}\"" >> /etc/openvpn/easy-rsa/vars || error
echo "export KEY_ORG=\"${org}\"" >> /etc/openvpn/easy-rsa/vars || error
echo "export KEY_EMAIL=\"${mail}\"" >> /etc/openvpn/easy-rsa/vars || error
echo "export KEY_OU=\"${ounit}\"" >> /etc/openvpn/easy-rsa/vars || error


openssl dhparam -out /etc/openvpn/dh2048.pem 2048 || error

cp /etc/openvpn/easy-rsa/openssl-1.0.0.cnf /etc/openvpn/easy-rsa/openssl.cnf || error

cd /etc/openvpn/easy-rsa || error
source vars || error
export EASY_RSA="${EASY_RSA:-.}" || error
./clean-all || error
"$EASY_RSA/pkitool" --initca || error
"$EASY_RSA/pkitool" --server server || error

cp /etc/openvpn/easy-rsa/keys/{server.crt,server.key,ca.crt} /etc/openvpn || error

cp ${tempfolder}/client.ovpn /etc/openvpn/client.ovpn || error

echo "remote ${server_addr} ${port}" >> /etc/openvpn/client.ovpn || error

"$EASY_RSA/pkitool" client || error

echo "<ca>" >> /etc/openvpn/client.ovpn || error
cat /etc/openvpn/easy-rsa/keys/ca.crt >> /etc/openvpn/client.ovpn || error
echo "</ca>" >> /etc/openvpn/client.ovpn || error

echo "<cert>" >> /etc/openvpn/client.ovpn || error
cat /etc/openvpn/easy-rsa/keys/client.crt >> /etc/openvpn/client.ovpn || error
echo "</cert>" >> /etc/openvpn/client.ovpn || error

echo "<key>" >> /etc/openvpn/client.ovpn || error
cat /etc/openvpn/easy-rsa/keys/client.key >> /etc/openvpn/client.ovpn || error
echo "</key>" >> /etc/openvpn/client.ovpn || error

gcc -o /etc/openvpn/userauth ${tempfolder}/userauth.c || error

echo "${user}:${password}" > /etc/openvpn/user.txt || error
