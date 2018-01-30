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
	read -p "Server addresse [comse.dyndns.org]: " server_addr
	if [ "${server_addr}" = "" ]; then server_addr="comse.dyndns.org"; fi
	read -p "Port [1194]: " port
	if [ "${port}" = "" ]; then port="1194"; fi
	read -p "Server IP [192.168.99.205/24]: " server_ip
	if [ "${server_ip}" = "" ]; then server_ip="192.168.99.205/24"; fi
	read -p "Gateway IP [192.168.99.100]: " gateway
	if [ "${gateway}" = "" ]; then gateway="192.168.99.100"; fi
	read -p "Customer network [192.168.99.0]: " cust_network
	if [ "${cust_network}" = "" ]; then cust_network="192.168.99.0"; fi
	read -p "Customer netmask [255.255.255.0]: " cust_netmask
	if [ "${cust_netmask}" = "" ]; then cust_netmask="255.255.255.0"; fi
	read -p "Customer vpn network [10.99.0.0]: " vpn_network
	if [ "${vpn_network}" = "" ]; then vpn_network="10.99.0.0"; fi
	read -p "Country [DE]: " country
	if [ "${country}" = "" ]; then country="DE"; fi
	read -p "Province [BY]: " province
	if [ "${province}" = "" ]; then province="BY"; fi
	read -p "City [Illertissen]: " city
	if [ "${city}" = "" ]; then city="Illertissen"; fi
	read -p "Organisation [Computer Service Schmid]: " org
	if [ "${org}" = "" ]; then org="Computer Service Schmid"; fi
	read -p "Email [info@computerserviceschmid.de]: " email
	if [ "${email}" = "" ]; then email="info@computerserviceschmid.de"; fi
	read -p "Organisation Unit [EDV]: " ounit
	if [ "${ounit}" = "" ]; then ounit="EDV"; fi

	read -p "First VPN User: " user
	read -p "Passowrd: " password
	if [ "${user}" = "" ]; then user="#user"; password="password"; fi

	read -p "All Informations correct? [y|n] " -n 1 finished
	echo
	if [ "${finished}" == "y" ]; then
		break
	fi
done

found=false
for i in $(ip route | grep default); do
	if $found; then
		interface=$i
		break
	fi
	if [ "$i" = "dev" ]; then
		found=true
	fi
done

# update and install packages
apt-get update || error
apt-get upgrade -y || error 
apt-get dist-upgrade -y || error
apt-get install -y git openvpn easy-rsa iptables vim gcc || error

# generate keys
rm -r /etc/openvpn
mkdir /etc/openvpn || error
cp -r /usr/share/easy-rsa /etc/openvpn/easy-rsa || error
mkdir /etc/openvpn/easy-rsa/keys || error

mv /etc/network/interfaces /etc/network/interfaces.backup || error
grep -v ${interface} /etc/network/interfaces.backup > /etc/network/interfaces || error
echo "allow-hotplug ${interface}" >> /etc/network/interfaces || error
echo "iface ${interface} inet static" >> /etc/network/interfaces || error
echo "   address ${server_ip}" >> /etc/network/interfaces || error
echo "   gateway ${gateway}" >> /etc/network/interfaces || error

# generate config file
tempfolder=$(mktemp -d) || error
git clone https://github.com/ddisaster/openvpn_installer.git ${tempfolder} || error

cp ${tempfolder}/server.conf /etc/openvpn/server.conf || error

# enable ip_forwarding
cp ${tempfolder}/autostart.sh /etc/openvpn/autostart.sh
echo "/sbin/iptables -t nat -A POSTROUTING -o ${interface} -j MASQUERADE" >> /etc/openvpn/autostart.sh || error

cp ${tempfolder}/openvpn-extra.service /etc/systemd/system/openvpn-extra.service || error
systemctl enable openvpn-extra.service || error

echo "port ${port}" >> /etc/openvpn/server.conf || error
echo "server ${vpn_network} 255.255.255.0" >> /etc/openvpn/server.conf || error
echo "push \"route ${cust_network} ${cust_netmask}\"" >> /etc/openvpn/server.conf || error
#echo "route ${cust_network} ${cust_netmask}" >> /etc/openvpn/server.conf || error

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

mkdir /etc/openvpn/ccd || error

user=$(ls /home | head -n 1) || error
cp /etc/openvpn/client.ovpn /home/${user}/client.ovpn || error
chown ${user}/${user} /home/${user}/client.ovpn || error

echo
read -p "Do you want to edit the user file? [y|n] " -n 1 edit_user
echo
if [ "${edit_user}" = "y" ]; then
	nano /etc/openvpn/user.txt
fi

echo 
echo -p "The config file should be available at \"/home/${user}/client.ovpn\" [Press any key to continue] " -n 1 asdf
echo

echo
read -p "The system must be restarted. Restart now? [y|n] " -n 1 restart
echo
if [ "${restart}" = "y" ]; then
	reboot
fi
